"""
Regression check: compares newly generated datasets with reference datasets.

Row order is ignored, because the pipeline does not produce a fixed order. Every value is compared as text.
Rows are compared as a whole, so a row in which one value changed shows up once as removed and once as added.

Usage:
    python compare_datasets.py NEW_DIR [REF_DIR] [--files a.csv b.csv] [--examples N]

REF_DIR defaults to the data folder of the repository. Only the csv files that exist in NEW_DIR are compared,
unless --files is given. The exit code is 1 if any dataset differs, so that the script can be used in scripts.

Typical use:
    cd src
    python main.py all --out ../regression_output
    cd ..
    python compare_datasets.py regression_output
"""
import argparse
import os
import sys

import pandas as pd

DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'data')


def read_dataset(path):
    """Reads a csv file as text. Older files in the repository are separated by ';' instead of tabs."""
    with open(path, encoding='utf-8') as f:
        header = f.readline()
    sep = '\t' if '\t' in header else ';'
    return pd.read_csv(path, sep=sep, dtype=str, keep_default_na=False)


def with_occurrence_number(df):
    """Numbers identical rows, so that duplicated rows are compared as a multiset."""
    df = df.copy()
    df['_occurrence'] = df.groupby(list(df.columns), sort=False).cumcount()
    return df


def compare(ref, new, n_examples):
    """Returns a list of lines describing the differences, empty if the datasets are identical."""
    report = []
    if list(ref.columns) != list(new.columns):
        removed = [c for c in ref.columns if c not in new.columns]
        added = [c for c in new.columns if c not in ref.columns]
        if removed or added:
            report.append(f'  columns removed: {removed}, columns added: {added}')
        else:
            report.append('  same columns, but in a different order')

    common = [c for c in ref.columns if c in new.columns]
    merged = with_occurrence_number(ref[common]).merge(with_occurrence_number(new[common]), how='outer',
                                                       indicator=True)
    only_ref = merged[merged['_merge'] == 'left_only'].drop(columns=['_occurrence', '_merge'])
    only_new = merged[merged['_merge'] == 'right_only'].drop(columns=['_occurrence', '_merge'])
    if len(only_ref) or len(only_new):
        report.append(f'  rows: {len(ref)} -> {len(new)}; {len(only_ref)} rows only in reference, '
                      f'{len(only_new)} rows only in new output')
        for label, rows in [('only in reference', only_ref), ('only in new output', only_new)]:
            if len(rows) == 0:
                continue
            if 'scroll' in rows.columns:
                counts = rows.scroll.value_counts()
                report.append(f'  {label}, per scroll: {counts.head(10).to_dict()}' +
                              (' ...' if len(counts) > 10 else ''))
            if n_examples:
                report.append(f'  examples {label}:')
                report.append(rows.head(n_examples).to_string(index=False, max_colwidth=20))
    return report


def main():
    sys.stdout.reconfigure(encoding='utf-8')  # the data contain Hebrew script
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('new_dir')
    parser.add_argument('ref_dir', nargs='?', default=DATA_DIR)
    parser.add_argument('--files', nargs='+', help='file names to compare (default: all csv files in NEW_DIR)')
    parser.add_argument('--examples', type=int, default=5, help='number of example rows to show per difference')
    args = parser.parse_args()

    files = args.files or sorted(f for f in os.listdir(args.new_dir) if f.endswith('.csv'))
    n_differing = 0
    for file_name in files:
        ref_path, new_path = os.path.join(args.ref_dir, file_name), os.path.join(args.new_dir, file_name)
        if not os.path.exists(ref_path) or not os.path.exists(new_path):
            print(f'{file_name}: MISSING in {"reference" if not os.path.exists(ref_path) else "new output"}')
            n_differing += 1
            continue
        report = compare(read_dataset(ref_path), read_dataset(new_path), args.examples)
        print(f'{file_name}: {"DIFFERENT" if report else "identical"}')
        for line in report:
            print(line)
        n_differing += bool(report)

    print(f'\n{len(files) - n_differing} of {len(files)} datasets identical.')
    sys.exit(1 if n_differing else 0)


if __name__ == '__main__':
    main()
