import pandas as pd

from data_classes import Corpus
from parse_matres_mt import MTMatresProcessor
from parse_matres_dss import DSSMatresProcessor, MatresPatternDataSet
from various_manipulations import FinalAlephConverter, FeminineTStripper, OtherVowelEndingsColumnAdder, \
    FinalYodRemover, MTDSSHelpColumnsAdder, MatresColumnAdder
from process_invalid_data import InvalidDataRemover

relevant_sps = {'adjv', 'subs'}


def main():

    corpus = Corpus('biblical')

    matres_processor_mt = MTMatresProcessor(corpus, relevant_sps)

    matres_pattern_dataset = MatresPatternDataSet('dss_predictions_per_word.txt')

    matres_parser_dss = DSSMatresProcessor(corpus, relevant_sps, matres_pattern_dataset.matres_predictions_dict)
    mt_dss = pd.concat([matres_processor_mt.mt_matres_df_relevant_sps, matres_parser_dss.dss_matres_df])

    final_aleph_converter = FinalAlephConverter(mt_dss)
    mt_dss = final_aleph_converter.data

    fem_t_stripper = FeminineTStripper(mt_dss)
    mt_dss = fem_t_stripper.data

    other_vowel_endings_column_adder = OtherVowelEndingsColumnAdder(mt_dss)
    mt_dss = other_vowel_endings_column_adder.data

    final_yod_remover = FinalYodRemover(mt_dss)
    mt_dss = final_yod_remover.data

    mt_dss_help_columns_adder = MTDSSHelpColumnsAdder(mt_dss, relevant_sps)
    mt_dss = mt_dss_help_columns_adder.mt_dss_data

    invalid_data_remover = InvalidDataRemover(mt_dss)
    mt_dss = invalid_data_remover.data_complete_syllables

    print(mt_dss.head(25))
    print(mt_dss.tail(25))
    print(mt_dss.shape)

    mt_dss.to_csv('../data/mt_dss_new_matres_pattern.csv', sep='\t', index=False)

    # TODO: adapt dtypes in mt_dss(object -> categorical)


if __name__ == '__main__':
    main()
