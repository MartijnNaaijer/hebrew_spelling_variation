import pandas as pd

from data_classes import Corpus
from parse_matres_mt import MTMatresProcessor
from parse_matres_dss import DSSMatresProcessor

relevant_sps = {'adjv', 'subs'}


def main():

    corpus = Corpus('biblical')

    matres_processor = MTMatresProcessor(corpus, relevant_sps)
    matres_parser_dss = DSSMatresProcessor(corpus, relevant_sps)
    mt_dss = pd.concat([matres_processor.mt_matres_df_relevant_sps, matres_parser_dss.dss_matres_df])


if __name__ == '__main__':
    main()
