"""
A dataset is created containing nouns and adjectives that show orthographic variation in their stem. With "stem", we
the consonantal representation of a word without suffixes (nominal endings and pronominal suffixes) and without prefixed
words (article or preposition).
The output is a csv file that

"""

import pandas as pd

from data_classes import Corpus
from add_hebrew_text_column import HebrewTextAdder
from parse_matres_mt import MTMatresProcessor
from parse_matres_dss import DSSMatresProcessor, MatresPatternDataSet
from various_manipulations import FinalAlephConverter, FeminineTStripper, OtherVowelEndingsColumnAdder, \
    FinalYodRemover, MTDSSHelpColumnsAdder, MatresColumnAdder
from process_invalid_data import InvalidDataRemover
from remove_useless_lexemes_and_plurals import UselessRowsRemover, SyllablesWithoutVariationRemover

from special_data import USELESS_PLURALS, REMOVE_LEXEMES, AD_HOC_REMOVALS

relevant_sps = {'adjv', 'subs'}


def main():

    corpus = Corpus('biblical')

    matres_processor_mt = MTMatresProcessor(corpus, relevant_sps)

    matres_pattern_dataset = MatresPatternDataSet('dss_predictions_per_word.txt')

    matres_parser_dss = DSSMatresProcessor(corpus, relevant_sps, matres_pattern_dataset.matres_predictions_dict)
    mt_dss = pd.concat([matres_processor_mt.mt_matres_df_relevant_sps, matres_parser_dss.dss_matres_df])
    mt_dss = mt_dss.sort_values(by=['tf_id'])
    #print('MT dtypes', matres_processor_mt.mt_matres_df_relevant_sps.dtypes)
    #print()
    #print('dss dtypes', matres_parser_dss.dss_matres_df.dtypes)
    #print()
    #print(mt_dss.dtypes)
    #print()
    mt_dss.to_csv('../data/mt_dss_before_manual_correction.csv', sep='\t', index=False)

    # Import manually corrected dataset
    # mt_dss = pd.read_csv('../data/mt_dss_after_manual_correction.csv', sep='\t')
    #
    # hebrew_text_adder = HebrewTextAdder(mt_dss)
    # mt_dss = hebrew_text_adder.data
    #
    # final_aleph_converter = FinalAlephConverter(mt_dss)
    # mt_dss = final_aleph_converter.data
    #
    # fem_t_stripper = FeminineTStripper(mt_dss)
    # mt_dss = fem_t_stripper.data
    #
    # other_vowel_endings_column_adder = OtherVowelEndingsColumnAdder(mt_dss)
    # mt_dss = other_vowel_endings_column_adder.data
    #
    # final_yod_remover = FinalYodRemover(mt_dss)
    # mt_dss = final_yod_remover.data
    #
    # mt_dss_help_columns_adder = MTDSSHelpColumnsAdder(mt_dss, relevant_sps)
    # mt_dss = mt_dss_help_columns_adder.mt_dss_data
    #
    # mt_dss.to_csv('../data/mt_dss_before_matres_col_adder.csv', sep='\t', index=False)
    #
    # matres_column_adder = MatresColumnAdder(mt_dss)
    # mt_dss = matres_column_adder.df_with_vowel_letters
    #
    # invalid_data_remover = InvalidDataRemover(mt_dss)
    # mt_dss = invalid_data_remover.data_complete_syllables
    #
    # useless_lexemes_remover = UselessRowsRemover(data=mt_dss,
    #                                              useless_plurals=USELESS_PLURALS,
    #                                              useless_lexemes=REMOVE_LEXEMES,
    #                                              useless_nodes=AD_HOC_REMOVALS)
    # mt_dss = useless_lexemes_remover.data
    #
    # syllables_without_variation_remover = SyllablesWithoutVariationRemover(mt_dss, entropy_threshold=0.12)
    # mt_dss = syllables_without_variation_remover.data_variable_syllables
    #
    # #print(mt_dss.head(25))
    # #print(mt_dss.tail(25))
    # #print(mt_dss.shape)
    #
    # mt_dss.to_csv('../data/mt_dss_new_matres_pattern.csv', sep='\t', index=False)

    # TODO: adapt dtypes in mt_dss(object -> categorical)


if __name__ == '__main__':
    main()
