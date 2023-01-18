from data_classes import Corpus
from parse_matres_mt import MTMatresProcessor
from parse_matres_dss import DSSMatresProcessor

relevant_sps = {'adjv', 'subs'}

def main():

    corpus = Corpus('biblical')

    matres_processor = MTMatresProcessor(corpus)
    matres_parser_dss = DSSMatresProcessor(relevant_sps, corpus)


if __name__ == '__main__':
    main()
