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

DATASETS = ['nouns', 'ptc', 'infc', 'hiphil', 'niph_hiph_pe_yod', 'particles', 'infa']


def parse_args():
    parser = argparse.ArgumentParser(description='Build the spelling variation datasets.')
    parser.add_argument('datasets', nargs='*', default=['nouns'], choices=DATASETS + ['all'],
                        help='datasets to build (default: nouns)')
    parser.add_argument('--out', help='folder for the output files (default: the data folder)')
    return parser.parse_args()


def main():
    args = parse_args()
    # Text-Fabric and the data print non-ASCII characters, which fails in a Windows console with another encoding.
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')
    datasets = DATASETS if 'all' in args.datasets else args.datasets
    if args.out:
        os.makedirs(args.out, exist_ok=True)
        os.environ['SPELLING_OUTPUT_DIR'] = os.path.abspath(args.out)

    # Imported here, so that config sees the output folder. Importing data_classes loads the Text-Fabric corpora.
    from config import output_path
    from data_classes import Corpus
    from parse_matres_mt import MTMatresProcessor
    import pipeline_functions as pf

    def save(df, file_name):
        df.to_csv(os.path.join(output_path, file_name), sep='\t', index=False)

    corpus = Corpus('biblical')
    matres_processor_mt = MTMatresProcessor(corpus)
    mt = matres_processor_mt.mt_matres_df

    if 'nouns' in datasets:
        mt_dss_sp_nouns_adjvs, mt_dss_sp_nouns_adjvs_all = pf.get_nouns_adjective_data(corpus, mt)
        save(mt_dss_sp_nouns_adjvs, 'nouns_adjectives.csv')
        save(mt_dss_sp_nouns_adjvs_all, 'nouns_adjectives_incl_no_variation.csv')

    if 'ptc' in datasets:
        # TODO: patterns "CCMC" are strange, "CMCC" is expected.
        ptca, ptcp = pf.get_participle_qal_data(corpus, mt)
        save(ptca.sort_values(by=['tf_id']), 'ptca_qal.csv')
        save(ptcp.sort_values(by=['tf_id']), 'ptcp_qal.csv')

    if 'infc' in datasets:
        lamed_he_infc, other_infc = pf.get_qal_infinitive_construct_data(corpus, mt)
        save(lamed_he_infc, 'infc_qal_lamed_he.csv')
        save(other_infc, 'infc_qal_triliteral.csv')

    if 'hiphil' in datasets:
        save(pf.get_triliteral_hiphil(corpus, mt), 'hiphil_triliteral.csv')

    if 'niph_hiph_pe_yod' in datasets:
        save(pf.get_niphal_hiphil_pe_yod_data(corpus, mt), 'niph_hiph_pe_yod.csv')

    if 'particles' in datasets:
        save(pf.get_particles(corpus, mt), 'particles.csv')

    if 'infa' in datasets:
        save(pf.get_qal_infinitive_absolute(corpus, mt), 'infa_qal.csv')


if __name__ == '__main__':
    main()
