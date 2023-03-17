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
from remove_useless_inf_abs import UselessRootsInfAbsRemover

from special_data import USELESS_PLURALS, REMOVE_LEXEMES, AD_HOC_REMOVALS

# For participles
from remove_useless_participle_roots import UselessParticiplesRemover, PassiveParticipleNMECleaner
from matres_column_participles import ParticiplesCorrector, MatresColumnAdderParticiples

# For infc
from matres_column_infc import InfcLamedHeCorrector, MatresColumnAdderInfinitiveConstructLamedHe, InfcOtherCorrector, \
     MatresColumnAdderInfinitiveTriliteral

# for particles
from remove_useless_particles import UselessParticleRemover

# for hif-nif pe yod
from matres_column_hif_nif_pe_yod import MatresColumnAdderHifNifPeYod
from remove_useless_hif_nif_pe_yod import UselessHiphNiphPeYod

# for triliteral hiphil
from remove_useless_hiphil_triliteral import UselessHiphilTriliteral
from matres_column_hiphil_triliteral import MatresColumnAdderHifTriliteral


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
    ptca, ptcp = get_participle_qal_data(corpus, mt, matres_pattern_dataset)
    ptca = ptca.sort_values(by=['tf_id'])
    ptcp = ptcp.sort_values(by=['tf_id'])
    ptca.to_csv('../data/ptca.csv', sep='\t', index=False)
    ptcp.to_csv('../data/ptcp.csv', sep='\t', index=False)
    # TODO: patterns "CCMC" are strange, "CMCC" is expected.

    # lamed_he_infc, other_infc = get_qal_infinitive_construct_data(corpus, mt, matres_pattern_dataset)
    # print(other_infc.shape)
    # print(lamed_he_infc.shape)
    # lamed_he_infc.to_csv('../data/lamed_he_infc.csv', sep='\t', index=False)
    # other_infc.to_csv('../data/other_infc.csv', sep='\t', index=False)
    # # TODO: add some columns, see nouns_adjvs

    #niph_hiph_pe_yod = get_niphal_hiphil_pe_yod_data(corpus, mt, matres_pattern_dataset)
    #print(niph_hiph_pe_yod.shape)
    #niph_hiph_pe_yod.to_csv('../data/niph_hiph_pe_yod.csv', sep='\t', index=False)

    #hiph_triliteral = get_triliteral_hiphil(corpus, mt, matres_pattern_dataset)
    #print(hiph_triliteral.shape)
    #hiph_triliteral.to_csv('../data/hiph_triliteral.csv', sep='\t', index=False)

    #particles = get_particles(corpus, mt, matres_pattern_dataset)
    #print(particles.shape)
    #particles.to_csv('../data/particles.csv', sep='\t', index=False)


    #qal_inf_abs = get_qal_infinitive_absolute(corpus, mt, matres_pattern_dataset)
    #print(qal_inf_abs.shape)
    #qal_inf_abs.to_csv('../data/qal_inf_abs.csv', sep='\t', index=False)

def get_participle_qal_data(corpus, mt, matres_pattern_dataset):
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='ptc_qal')
    mt_ptc_qal_df = basic_mt_data_selector.select_data()

    matres_parser_dss = DSSMatresProcessor(corpus,
                                           relevant_data='ptc_qal',
                                           matres_pattern_dict=matres_pattern_dataset.matres_predictions_dict)

    mt_dss_ptc_qal_df = pd.concat([mt_ptc_qal_df, matres_parser_dss.dss_matres_df])
    mt_dss_ptc_qal_df = mt_dss_ptc_qal_df.sort_values(by=['tf_id'])

    useless_participles_remover = UselessParticiplesRemover(mt_dss_ptc_qal_df)
    mt_dss_ptc_qal_df = useless_participles_remover.clean_ptc_data

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

    participles_corrector = ParticiplesCorrector(ptca)
    ptca = participles_corrector.data

    matres_column_adder_ptca = MatresColumnAdderParticiples(ptca, 'ptca')
    ptca = matres_column_adder_ptca.data

    pp_nme_cleaner = PassiveParticipleNMECleaner(ptcp)
    ptcp = pp_nme_cleaner.data

    matres_column_adder_ptcp = MatresColumnAdderParticiples(ptcp, 'ptcp')
    ptcp = matres_column_adder_ptcp.data

    return ptca, ptcp


def get_niphal_hiphil_pe_yod_data(corpus, mt, matres_pattern_dataset):
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='niph_hiph_pe_yod')
    mt_niph_hiph_pe_yod_df = basic_mt_data_selector.select_data()

    matres_parser_dss = DSSMatresProcessor(corpus,
                                           relevant_data='niph_hiph_pe_yod',
                                           matres_pattern_dict=matres_pattern_dataset.matres_predictions_dict)

    niph_hiph_pe_yod_df = pd.concat([mt_niph_hiph_pe_yod_df, matres_parser_dss.dss_matres_df])
    niph_hiph_pe_yod_df = niph_hiph_pe_yod_df.sort_values(by=['tf_id'])

    hebrew_text_adder = HebrewTextAdder(niph_hiph_pe_yod_df)
    niph_hiph_pe_yod_df = hebrew_text_adder.data

    niph_hiph_pe_yod_df['other_vowel_ending'] = ''

    mt_dss_help_columns_adder = MTDSSHelpColumnsAdder(niph_hiph_pe_yod_df)
    niph_hiph_pe_yod_df = mt_dss_help_columns_adder.mt_dss_data

    rec_cor_columns_adder = RecCorColumnsAdder(niph_hiph_pe_yod_df)
    niph_hiph_pe_yod_df = rec_cor_columns_adder.data

    useless_hif_nif_pe_yod = UselessHiphNiphPeYod(niph_hiph_pe_yod_df)
    niph_hiph_pe_yod_df = useless_hif_nif_pe_yod.data_no_second_h

    matres_column_adder_hif_nif_pe_yod = MatresColumnAdderHifNifPeYod(niph_hiph_pe_yod_df)
    niph_hiph_pe_yod_df = matres_column_adder_hif_nif_pe_yod.data

    return niph_hiph_pe_yod_df


def get_triliteral_hiphil(corpus, mt, matres_pattern_dataset):
    """Problem of impf is that there are two forms: jaqtil en jaqtel, the latter (juss.)
    is difficult to distinguish without vocalization. Both are included in the dataset."""
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='hiph_triliteral')
    mt_hiph_triliteral_df = basic_mt_data_selector.select_data()

    matres_parser_dss = DSSMatresProcessor(corpus,
                                           relevant_data='hiph_triliteral',
                                           matres_pattern_dict=matres_pattern_dataset.matres_predictions_dict)

    hiph_triliteral_df = pd.concat([mt_hiph_triliteral_df, matres_parser_dss.dss_matres_df])
    hiph_triliteral_df = hiph_triliteral_df.sort_values(by=['tf_id'])

    hebrew_text_adder = HebrewTextAdder(hiph_triliteral_df)
    hiph_triliteral_df = hebrew_text_adder.data

    hiph_triliteral_df['other_vowel_ending'] = ''

    mt_dss_help_columns_adder = MTDSSHelpColumnsAdder(hiph_triliteral_df)
    hiph_triliteral_df = mt_dss_help_columns_adder.mt_dss_data

    rec_cor_columns_adder = RecCorColumnsAdder(hiph_triliteral_df)
    hiph_triliteral_df = rec_cor_columns_adder.data

    useless_hiphil_triliteral = UselessHiphilTriliteral(hiph_triliteral_df)
    hiph_triliteral_df = useless_hiphil_triliteral.relevant_combinations

    matres_column_adder_hif_triliteral = MatresColumnAdderHifTriliteral(hiph_triliteral_df)
    hiph_triliteral_df = matres_column_adder_hif_triliteral.data
    return hiph_triliteral_df


def get_qal_infinitive_absolute(corpus, mt, matres_pattern_dataset):
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='inf_abs_qal')
    mt_qal_inf_abs = basic_mt_data_selector.select_data()

    matres_parser_dss = DSSMatresProcessor(corpus,
                                           relevant_data='inf_abs_qal',
                                           matres_pattern_dict=matres_pattern_dataset.matres_predictions_dict)

    qal_inf_abs_df = pd.concat([mt_qal_inf_abs, matres_parser_dss.dss_matres_df])
    qal_inf_abs_df = qal_inf_abs_df.sort_values(by=['tf_id'])

    hebrew_text_adder = HebrewTextAdder(qal_inf_abs_df)
    qal_inf_abs_df = hebrew_text_adder.data

    qal_inf_abs_df['other_vowel_ending'] = ''

    mt_dss_help_columns_adder = MTDSSHelpColumnsAdder(qal_inf_abs_df)
    qal_inf_abs_df = mt_dss_help_columns_adder.mt_dss_data

    rec_cor_columns_adder = RecCorColumnsAdder(qal_inf_abs_df)
    qal_inf_abs_df = rec_cor_columns_adder.data

    useless_roots_inf_abs = UselessRootsInfAbsRemover(qal_inf_abs_df)
    qal_inf_abs_df = useless_roots_inf_abs.no_lamed_he

    # add has_vowel_letter has_syllable_recs
    matres_column_adder_infin_trilit = MatresColumnAdderInfinitiveTriliteral(qal_inf_abs_df)
    qal_inf_abs_df = matres_column_adder_infin_trilit.data

    # Strange case in dataset:
    # in 4Q56 2x inf abs in 37:30, waar komen die vandaan, niet in andere manuscr.

    return qal_inf_abs_df


def get_particles(corpus, mt, matres_pattern_dataset):
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='particles')
    mt_particles = basic_mt_data_selector.select_data()

    matres_parser_dss = DSSMatresProcessor(corpus,
                                           relevant_data='particles',
                                           matres_pattern_dict=matres_pattern_dataset.matres_predictions_dict)

    particles_df = pd.concat([mt_particles, matres_parser_dss.dss_matres_df])
    particles_df = particles_df.sort_values(by=['tf_id'])

    hebrew_text_adder = HebrewTextAdder(particles_df)
    particles_df = hebrew_text_adder.data

    particles_df['other_vowel_ending'] = ''

    mt_dss_help_columns_adder = MTDSSHelpColumnsAdder(particles_df)
    particles_df = mt_dss_help_columns_adder.mt_dss_data

    rec_cor_columns_adder = RecCorColumnsAdder(particles_df)
    particles_df = rec_cor_columns_adder.data

    # add type, vowel_letter, has_vowel_letter
    particles_df['type'] = 'single'
    useless_particle_remover = UselessParticleRemover(particles_df)
    particles_df = useless_particle_remover.data

    particles_df['vowel_letter'] = particles_df.g_cons.str[1:]
    particles_df['has_vowel_letter'] = 1

    # Correct in data: 1957484 is lex L, rest is good, remove deviating cases (L, LH, LW, etc in analysis)

    return particles_df


if __name__ == '__main__':
    main()
