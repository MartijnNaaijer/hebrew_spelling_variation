"""
A dataset is created containing nouns and adjectives that show orthographic variation in their stem. With "stem", we
the consonantal representation of a word without suffixes (nominal endings and pronominal suffixes) and without prefixed
words (article or preposition).

"""

import pandas as pd

from data_classes import Corpus
from add_hebrew_text_column import HebrewTextAdder
from first_data_selection_mt import BasicMTDataSelector
from parse_matres_mt import MTMatresProcessor
from parse_matres_dss import DSSMatresProcessor, MatresPatternDataSet
from various_manipulations import FinalAlephConverter, FeminineTStripper, OtherVowelEndingsColumnAdder, \
    FinalYodRemover, MTDSSHelpColumnsAdder, MatresColumnAdder, RecCorColumnsAdder
from process_invalid_data import InvalidDataRemover
from remove_useless_lexemes_and_plurals import UselessRowsRemover, SyllablesWithoutVariationRemover

from special_data import USELESS_PLURALS, REMOVE_LEXEMES, AD_HOC_REMOVALS

# For participles
from remove_useless_participle_roots import UselessParticiplesRemover
from matres_column_participles import ParticiplesCorrector, MatresColumnAdderActiveParticiples

# For infc
from matres_column_infc import InfcLamedHeCorrector, MatresColumnAdderInfinitiveConstructLamedHe, InfcOtherCorrector, \
     MatresColumnAdderInfinitiveConstructTriliteral


def main():

    corpus = Corpus('biblical')

    matres_processor_mt = MTMatresProcessor(corpus)
    mt = matres_processor_mt.mt_matres_df

    matres_pattern_dataset = MatresPatternDataSet('dss_predictions_per_word.txt')

    ####################################################
    # Nouns adjectives
    #mt_dss_nouns_adjvs = get_nouns_adjective_data(corpus, mt, matres_pattern_dataset)
    #mt_dss_nouns_adjvs.to_csv('../data/mt_dss_new_matres_pattern.csv', sep='\t', index=False)

    ####################################################

    # ptca en ptcp qal
    # ptca, ptcp = get_participle_qal_data(corpus, mt, matres_pattern_dataset)
    # ptca = ptca.sort_values(by=['tf_id'])
    # ptcp = ptcp.sort_values(by=['tf_id'])
    # ptca.to_csv('../data/ptca.csv', sep='\t', index=False)
    # ptcp.to_csv('../data/ptcp.csv', sep='\t', index=False)
    # TODO: patterns "CCMC" are strange, "CMCC" is expected.

    # lamed_he_infc, other_infc = get_qal_infinitive_construct_data(corpus, mt, matres_pattern_dataset)
    # print(other_infc.shape)
    # print(lamed_he_infc.shape)
    # lamed_he_infc.to_csv('../data/lamed_he_infc.csv', sep='\t', index=False)
    # other_infc.to_csv('../data/other_infc.csv', sep='\t', index=False)
    # # TODO: add some columns, see nouns_adjvs


def get_nouns_adjective_data(corpus, mt, matres_pattern_dataset):
    matres_parser_dss = DSSMatresProcessor(corpus, 'subs_adjv', matres_pattern_dataset.matres_predictions_dict)

    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='ptc_qal')
    mt_nouns_adjectives_data = basic_mt_data_selector.select_data()

    mt_dss = pd.concat([mt_nouns_adjectives_data, matres_parser_dss.dss_matres_df])
    mt_dss = mt_dss.sort_values(by=['tf_id'])

    mt_dss.to_csv('../data/mt_dss_before_manual_correction.csv', sep='\t', index=False)

    # Import manually corrected dataset
    mt_dss = pd.read_csv('../data/mt_dss_after_manual_correction.csv', sep=';')

    hebrew_text_adder = HebrewTextAdder(mt_dss)
    mt_dss = hebrew_text_adder.data

    final_aleph_converter = FinalAlephConverter(mt_dss)
    mt_dss = final_aleph_converter.data

    fem_t_stripper = FeminineTStripper(mt_dss)
    mt_dss = fem_t_stripper.data

    other_vowel_endings_column_adder = OtherVowelEndingsColumnAdder(mt_dss)
    mt_dss = other_vowel_endings_column_adder.data

    final_yod_remover = FinalYodRemover(mt_dss)
    mt_dss = final_yod_remover.data

    mt_dss_help_columns_adder = MTDSSHelpColumnsAdder(mt_dss)
    mt_dss = mt_dss_help_columns_adder.mt_dss_data

    rec_cor_columns_adder = RecCorColumnsAdder(mt_dss)
    mt_dss = rec_cor_columns_adder.data

    mt_dss.to_csv('../data/mt_dss_before_matres_col_adder.csv', sep='\t', index=False)

    matres_column_adder = MatresColumnAdder(mt_dss)
    mt_dss = matres_column_adder.df_with_vowel_letters

    invalid_data_remover = InvalidDataRemover(mt_dss)
    mt_dss = invalid_data_remover.data_complete_syllables

    useless_lexemes_remover = UselessRowsRemover(data=mt_dss,
                                                 useless_plurals=USELESS_PLURALS,
                                                 useless_lexemes=REMOVE_LEXEMES,
                                                 useless_nodes=AD_HOC_REMOVALS)
    mt_dss = useless_lexemes_remover.data

    syllables_without_variation_remover = SyllablesWithoutVariationRemover(mt_dss, entropy_threshold=0.12)
    mt_dss = syllables_without_variation_remover.data_variable_syllables

    # TODO: adapt dtypes in mt_dss(object -> categorical)
    return mt_dss


def get_participle_qal_data(corpus, mt, matres_pattern_dataset):
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='ptc_qal')
    mt_ptc_qal_df = basic_mt_data_selector.select_data()

    matres_parser_dss = DSSMatresProcessor(corpus,
                                           relevant_data='ptc_qal',
                                           matres_pattern_dict=matres_pattern_dataset.matres_predictions_dict)

    mt_dss_ptc_qal_df = pd.concat([mt_ptc_qal_df, matres_parser_dss.dss_matres_df])
    mt_dss_ptc_qal_df = mt_dss_ptc_qal_df.sort_values(by=['tf_id'])

    useless_participles_remover = UselessParticiplesRemover(mt_dss_ptc_qal_df)
    mt_dss_ptc_qal_df = useless_participles_remover.no_lamed_he_data

    hebrew_text_adder = HebrewTextAdder(mt_dss_ptc_qal_df)
    mt_dss_ptc_qal_df = hebrew_text_adder.data

    final_aleph_converter = FinalAlephConverter(mt_dss_ptc_qal_df)
    mt_dss_ptc_qal_df = final_aleph_converter.data

    fem_t_stripper = FeminineTStripper(mt_dss_ptc_qal_df)
    mt_dss_ptc_qal_df = fem_t_stripper.data

    other_vowel_endings_column_adder = OtherVowelEndingsColumnAdder(mt_dss_ptc_qal_df)
    mt_dss_ptc_qal_df = other_vowel_endings_column_adder.data

    final_yod_remover = FinalYodRemover(mt_dss_ptc_qal_df)
    mt_dss_ptc_qal_df = final_yod_remover.data

    mt_dss_help_columns_adder = MTDSSHelpColumnsAdder(mt_dss_ptc_qal_df)
    mt_dss_ptc_qal_df = mt_dss_help_columns_adder.mt_dss_data

    rec_cor_columns_adder = RecCorColumnsAdder(mt_dss_ptc_qal_df)
    mt_dss_ptc_qal_df = rec_cor_columns_adder.data

    ptca = mt_dss_ptc_qal_df[mt_dss_ptc_qal_df.vt == 'ptca']
    ptcp = mt_dss_ptc_qal_df[mt_dss_ptc_qal_df.vt == 'ptcp']
    # TODO: continue with ptcp (cleaning, add vowel cols)

    participles_corrector = ParticiplesCorrector(ptca)
    ptca = participles_corrector.data

    matres_column_adder_ptca = MatresColumnAdderActiveParticiples(ptca)
    ptca = matres_column_adder_ptca.data

    #matres_column_adder = MatresColumnAdder(ptca)
    #ptca = matres_column_adder.df_with_vowel_letters.sort_values(by=['tf_id'])

    #matres_column_adder = MatresColumnAdder(ptcp)
    #ptcp = matres_column_adder.df_with_vowel_letters.sort_values(by=['tf_id'])

    return ptca, ptcp


def get_qal_infinitive_construct_data(corpus, mt, matres_pattern_dataset):
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='infc_qal')
    mt_infc_qal_df = basic_mt_data_selector.select_data()

    matres_parser_dss = DSSMatresProcessor(corpus,
                                           relevant_data='infc_qal',
                                           matres_pattern_dict=matres_pattern_dataset.matres_predictions_dict)

    mt_dss_infc_qal_df = pd.concat([mt_infc_qal_df, matres_parser_dss.dss_matres_df])
    mt_dss_infc_qal_df = mt_dss_infc_qal_df.sort_values(by=['tf_id'])

    hebrew_text_adder = HebrewTextAdder(mt_dss_infc_qal_df)
    mt_dss_infc_qal_df = hebrew_text_adder.data

    final_aleph_converter = FinalAlephConverter(mt_dss_infc_qal_df)
    mt_dss_infc_qal_df = final_aleph_converter.data

    lamed_he_infc = mt_dss_infc_qal_df[mt_dss_infc_qal_df.lex.str[2] == 'H']
    other_infc = mt_dss_infc_qal_df[mt_dss_infc_qal_df.lex.str[2] != 'H']

    infc_lamed_he_corrector = InfcLamedHeCorrector(lamed_he_infc)
    lamed_he_infc = infc_lamed_he_corrector.data

    matres_column_adder_lamed_he_infc = MatresColumnAdderInfinitiveConstructLamedHe(lamed_he_infc)
    lamed_he_infc = matres_column_adder_lamed_he_infc.data

    infc_other_corrector = InfcOtherCorrector(other_infc)
    other_infc = infc_other_corrector.data
    matres_col_adder_infc_triliteral = MatresColumnAdderInfinitiveConstructTriliteral(other_infc)
    other_infc = matres_col_adder_infc_triliteral.data

    return lamed_he_infc, other_infc


def get_triliteral_hiphil_data():
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='trilit_hiphil')
    mt_ptc_qal_df = basic_mt_data_selector.select_data()


def get_qal_infinitive_absolute():
    pass


if __name__ == '__main__':
    main()
