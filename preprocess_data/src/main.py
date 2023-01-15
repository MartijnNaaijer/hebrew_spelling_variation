from data_classes import Corpus
from parse_matres_mt import MTMatresProcessor


def main():

    corpus = Corpus('biblical')

    matres_processor = MTMatresProcessor(corpus)


if __name__ == '__main__':
    main()