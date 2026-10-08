"""
Builds the datasets of spelling variation in MT, DSS and SP and saves them as tab-separated files.

The main dataset contains nouns and adjectives that show orthographic variation in their stem. With "stem", we mean
the consonantal representation of a word without suffixes (nominal endings and pronominal suffixes) and without
prefixed words (article or preposition). The other datasets contain specific verbal forms and particles.

Usage (from preprocess_data/src):
    python main.py                       # nouns and adjectives only
    python main.py hiphil infa           # the given datasets
    python main.py all                   # all datasets
    python main.py all --out some/dir    # write the files to some/dir instead of the data folder

"""
import argparse
import os
import sys

from config import data_path
from corpora import load_corpora
from pipelines import PIPELINES
from words import WORD_COLUMNS, build_mt_table, build_dss_table, build_sp_table, mt_sections

DATASETS = list(PIPELINES)


def parse_args():
    parser = argparse.ArgumentParser(description='Build the spelling variation datasets.')
    parser.add_argument('datasets', nargs='*', default=['nouns'], choices=DATASETS + ['all'],
                        help='datasets to build (default: nouns)')
    parser.add_argument('--out', help='folder for the output files (default: the data folder)')
    return parser.parse_args()


def sort_rows(df):
    """Sorts the rows by tf_id and syllable type, so that a dataset is written in the same order in every run.
    If these do not identify the rows, the other columns are used too."""
    key = [c for c in ['tf_id', 'type'] if c in df.columns]
    if df.duplicated(key).any():
        return df.sort_values(by=list(df.columns), key=lambda col: col if col.name == 'tf_id' else col.astype(str),
                              kind='stable')
    return df.sort_values(by=key, kind='stable')


def main():
    args = parse_args()
    # Text-Fabric and the data print non-ASCII characters, which fails in a Windows console with another encoding.
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')
    datasets = DATASETS if 'all' in args.datasets else args.datasets
    out = args.out or data_path
    os.makedirs(out, exist_ok=True)

    def save(df, file_name):
        sort_rows(df).to_csv(os.path.join(out, file_name), sep='\t', index=False)

    corpora = load_corpora()
    mt_words = build_mt_table(corpora.mt)
    sections = mt_sections(mt_words)
    tables = {'mt': mt_words, 'dss': build_dss_table(corpora.dss, sections), 'sp': build_sp_table(corpora.sp, sections)}
    save(mt_words[mt_words.lang == 'Hebrew'][WORD_COLUMNS], 'matres_mt.csv')

    for dataset in datasets:
        for file_name, df in PIPELINES[dataset](tables).items():
            save(df, file_name)


if __name__ == '__main__':
    main()
