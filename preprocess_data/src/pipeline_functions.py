"""
Each functions runs the data preparation pipeline for a specific feature.
The function get_nouns_adjectives_data depends on a json file (../data/pattern_data.json), which contains partly
manually corrected matres patterns.

"""
import json
import os

import numpy as np
import pandas as pd

from config import data_path, matres_patterns_mt_dss_file, matres_patterns_sp_file, entropy
from first_data_selection_mt import BasicMTDataSelector
from process_data_sp_dss import SpDssDataProcessor

from various_manipulations import FinalAlephConverter, FeminineTStripper, OtherVowelEndingsColumnAdder, \
    FinalYodRemover, MTDSSHelpColumnsAdder, MatresColumnAdder, RecCorColumnsAdder
from process_invalid_data import InvalidDataRemover, InvalidDataRemoverInfcLamedHe
from remove_useless_lexemes_and_plurals import UselessRowsRemover, SyllablesWithoutVariationRemover
from remove_useless_inf_abs import UselessRootsInfAbsRemover
from add_column_neighboring_vowel_letter import VowelLetterInSubsequentSyllableAdder

from special_data import USELESS_PLURALS, REMOVE_LEXEMES, AD_HOC_REMOVALS

# For participles
from remove_useless_participle_roots import UselessParticiplesRemover, PassiveParticipleNMECleaner
from matres_column_participles import ParticiplesCorrector, MatresColumnAdderParticiples
from make_dss_ptc_patterns import PtcPatternMaker

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


def get_nouns_adjective_data(corpus, mt):
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='subs_adjv')
    mt_nouns_adjectives_data = basic_mt_data_selector.select_data()

    # TODO: ADD SP TO mt_dss
    matres_parser_dss = SpDssDataProcessor(corpus, 'dss', 'subs_adjv')
    matres_parser_sp = SpDssDataProcessor(corpus, 'sp', 'subs_adjv')

    with open(os.path.join(data_path, matres_patterns_sp_file)) as j:
        pattern_dict_sp = json.loads(j.read())

    pattern_integer_dict_sp = {int(k): v for k, v in pattern_dict_sp.items()}
    pattern_l = []
    pattern_g_cons_l = []

    sp = matres_parser_sp.matres_df

    for _, row in sp.iterrows():
        tf_id = row.tf_id
        stem = row.stem
        g_cons = row.g_cons
        stem_idx = g_cons.find(stem)
        pat_g_cons = pattern_integer_dict_sp.get(tf_id, [''])
        pattern_stem = pat_g_cons[stem_idx:stem_idx + len(stem)]
        pattern_g_cons_l.append(pat_g_cons)
        pattern_l.append(pattern_stem)
    sp['pattern'] = pattern_l
    sp['pattern_g_cons'] = pattern_g_cons_l

    final_aleph_converter = FinalAlephConverter(sp)
    sp = final_aleph_converter.data

    fem_t_stripper = FeminineTStripper(sp)
    sp = fem_t_stripper.data

    other_vowel_endings_column_adder = OtherVowelEndingsColumnAdder(sp)
    sp = other_vowel_endings_column_adder.data

    final_yod_remover = FinalYodRemover(sp)
    sp = final_yod_remover.data
    mt_dss_help_columns_adder = MTDSSHelpColumnsAdder(sp)
    sp = mt_dss_help_columns_adder.mt_dss_data

    rec_cor_columns_adder = RecCorColumnsAdder(sp)
    sp = rec_cor_columns_adder.data

    matres_column_adder = MatresColumnAdder(sp)
    sp = matres_column_adder.df_with_vowel_letters

    invalid_data_remover = InvalidDataRemover(sp)
    sp = invalid_data_remover.data_complete_syllables

    useless_lexemes_remover = UselessRowsRemover(data=sp,
                                                 useless_plurals=USELESS_PLURALS,
                                                 useless_lexemes=REMOVE_LEXEMES,
                                                 useless_nodes=AD_HOC_REMOVALS)
    sp = useless_lexemes_remover.data

    mt_dss = pd.concat([mt_nouns_adjectives_data, matres_parser_dss.matres_df])
    mt_dss = mt_dss.sort_values(by=['tf_id'])

    with open(os.path.join(data_path, matres_patterns_mt_dss_file)) as j:
        pattern_dict = json.loads(j.read())
    pattern_integer_dict = {int(k): v for k, v in pattern_dict.items()}

    pattern_l = []
    pattern_g_cons_l = []

    for tf_id, g_cons, stem in zip(mt_dss.tf_id, mt_dss.g_cons, mt_dss.stem):
        stem_idx = g_cons.find(stem)
        pat_g_cons = pattern_integer_dict.get(int(tf_id), ['', ''])
        if not isinstance(pat_g_cons, str):
            pattern_stem = ''
        else:
            pattern_stem = pat_g_cons[stem_idx:stem_idx + len(stem)]
        pattern_l.append(pattern_stem)
        pattern_g_cons_l.append(pat_g_cons)

    mt_dss['pattern'] = pattern_l
    mt_dss['pattern_g_cons'] = pattern_g_cons_l

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

    matres_column_adder = MatresColumnAdder(mt_dss)
    mt_dss = matres_column_adder.df_with_vowel_letters

    invalid_data_remover = InvalidDataRemover(mt_dss)
    mt_dss = invalid_data_remover.data_complete_syllables

    useless_lexemes_remover = UselessRowsRemover(data=mt_dss,
                                                 useless_plurals=USELESS_PLURALS,
                                                 useless_lexemes=REMOVE_LEXEMES,
                                                 useless_nodes=AD_HOC_REMOVALS)
    mt_dss = useless_lexemes_remover.data

    sp['tf_id'] = sp['tf_id'] + 100000
    mt_dss_sp = pd.concat([mt_dss, sp])

    syllables_without_variation_remover = SyllablesWithoutVariationRemover(mt_dss_sp, entropy_threshold=entropy)
    mt_dss_sp = syllables_without_variation_remover.data_variable_syllables

    vowel_letter_in_subsequent_syll_adder = VowelLetterInSubsequentSyllableAdder(mt_dss_sp)
    mt_dss_sp = vowel_letter_in_subsequent_syll_adder.data

    # TODO: adapt dtypes in mt_dss(object -> categorical)
    return mt_dss_sp


def get_qal_infinitive_construct_data(corpus, mt):
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='infc_qal')
    mt_infc_qal_df = basic_mt_data_selector.select_data()

    matres_parser_dss = SpDssDataProcessor(corpus, 'dss',
                                           relevant_data='infc_qal')

    mt_dss_infc_qal_df = pd.concat([mt_infc_qal_df, matres_parser_dss.matres_df])
    mt_dss_infc_qal_df = mt_dss_infc_qal_df.sort_values(by=['tf_id'])
    mt_dss_infc_qal_df['other_vowel_ending'] = ''

    final_aleph_converter = FinalAlephConverter(mt_dss_infc_qal_df)
    mt_dss_infc_qal_df = final_aleph_converter.data

    lamed_he_infc = mt_dss_infc_qal_df[mt_dss_infc_qal_df.lex.str[2] == 'H']
    other_infc = mt_dss_infc_qal_df[mt_dss_infc_qal_df.lex.str[2] != 'H']

    infc_lamed_he_corrector = InfcLamedHeCorrector(lamed_he_infc)
    lamed_he_infc = infc_lamed_he_corrector.data

    mt_dss_help_columns_adder = MTDSSHelpColumnsAdder(lamed_he_infc)
    lamed_he_infc = mt_dss_help_columns_adder.mt_dss_data

    rec_cor_col_adder = RecCorColumnsAdder(lamed_he_infc)
    lamed_he_infc = rec_cor_col_adder.data

    matres_column_adder_lamed_he_infc = MatresColumnAdderInfinitiveConstructLamedHe(lamed_he_infc)
    lamed_he_infc = matres_column_adder_lamed_he_infc.data

    invalid_data_remover_lam_he = InvalidDataRemoverInfcLamedHe(lamed_he_infc)
    lamed_he_infc = invalid_data_remover_lam_he.data_complete_syllables

    infc_other_corrector = InfcOtherCorrector(other_infc)
    other_infc = infc_other_corrector.data

    mt_dss_help_columns_adder = MTDSSHelpColumnsAdder(other_infc)
    other_infc = mt_dss_help_columns_adder.mt_dss_data

    rec_cor_col_adder = RecCorColumnsAdder(other_infc)
    other_infc = rec_cor_col_adder.data

    matres_col_adder_infc_triliteral = MatresColumnAdderInfinitiveTriliteral(other_infc)
    other_infc = matres_col_adder_infc_triliteral.data

    invalid_data_remover = InvalidDataRemover(other_infc)
    other_infc = invalid_data_remover.data_complete_syllables

    return lamed_he_infc, other_infc


def get_participle_qal_data(corpus, mt):
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='ptc_qal')
    mt_ptc_qal_df = basic_mt_data_selector.select_data()
    print(0, 'PNH[' in list(mt_ptc_qal_df.lex))

    ###################################################################################################
    matres_parser_dss = SpDssDataProcessor(corpus, 'dss',
                                           relevant_data='ptc_qal')

    dss_ptc_df = matres_parser_dss.matres_df
    ptc_pattern_maker = PtcPatternMaker(dss_ptc_df)
    dss_ptc_qal_df = ptc_pattern_maker.data

    ########################################################################################

    matres_parser_sp = SpDssDataProcessor(corpus, 'sp',
                                           relevant_data='ptc_qal')

    sp_ptc_df = matres_parser_sp.matres_df
    ptc_pattern_maker = PtcPatternMaker(sp_ptc_df)
    sp_ptc_qal_df = ptc_pattern_maker.data
    sp_ptc_qal_df['tf_id'] = sp_ptc_qal_df['tf_id'] + 100000

    # Select qal cases
    qal_cases = [stem == g_cons[:len(stem)] for stem, g_cons in zip(sp_ptc_qal_df.stem, sp_ptc_qal_df.g_cons)]
    sp_ptc_qal_df = sp_ptc_qal_df[qal_cases]

    ########################################################################################
    mt_dss_ptc_qal_df = pd.concat([mt_ptc_qal_df, dss_ptc_qal_df, sp_ptc_qal_df])
    mt_dss_ptc_qal_df = mt_dss_ptc_qal_df.sort_values(by=['tf_id'])

    mt = mt_dss_ptc_qal_df[(mt_dss_ptc_qal_df.scroll == 'MT') & (mt_dss_ptc_qal_df.vt == 'ptca')]
    print(4, 'PNH[' in list(mt.lex))

    useless_participles_remover = UselessParticiplesRemover(mt_dss_ptc_qal_df)
    mt_dss_ptc_qal_df = useless_participles_remover.clean_ptc_data

    mt = mt_dss_ptc_qal_df[(mt_dss_ptc_qal_df.scroll == 'MT') & (mt_dss_ptc_qal_df.vt == 'ptca')]
    print(5, 'PNH[' in list(mt.lex))

    final_aleph_converter = FinalAlephConverter(mt_dss_ptc_qal_df)
    mt_dss_ptc_qal_df = final_aleph_converter.data

    fem_t_stripper = FeminineTStripper(mt_dss_ptc_qal_df)
    mt_dss_ptc_qal_df = fem_t_stripper.data

    other_vowel_endings_column_adder = OtherVowelEndingsColumnAdder(mt_dss_ptc_qal_df)
    mt_dss_ptc_qal_df = other_vowel_endings_column_adder.data

    mt = mt_dss_ptc_qal_df[(mt_dss_ptc_qal_df.scroll == 'MT') & (mt_dss_ptc_qal_df.vt == 'ptca')]
    print(6, 'PNH[' in list(mt.lex))

    final_yod_remover = FinalYodRemover(mt_dss_ptc_qal_df)
    mt_dss_ptc_qal_df = final_yod_remover.data

    mt_dss_help_columns_adder = MTDSSHelpColumnsAdder(mt_dss_ptc_qal_df)
    mt_dss_ptc_qal_df = mt_dss_help_columns_adder.mt_dss_data

    mt = mt_dss_ptc_qal_df[(mt_dss_ptc_qal_df.scroll == 'MT') & (mt_dss_ptc_qal_df.vt == 'ptca')]
    print(7, 'PNH[' in list(mt.lex))

    rec_cor_columns_adder = RecCorColumnsAdder(mt_dss_ptc_qal_df)
    mt_dss_ptc_qal_df = rec_cor_columns_adder.data

    mt = mt_dss_ptc_qal_df[(mt_dss_ptc_qal_df.scroll == 'MT') & (mt_dss_ptc_qal_df.vt == 'ptca')]
    print(7.5, 'PNH[' in list(mt.lex))

    ptca = mt_dss_ptc_qal_df[mt_dss_ptc_qal_df.vt == 'ptca']
    ptcp = mt_dss_ptc_qal_df[mt_dss_ptc_qal_df.vt == 'ptcp']

    participles_corrector = ParticiplesCorrector(ptca)
    ptca = participles_corrector.data

    mt = ptca[(ptca.scroll == 'MT') & (ptca.vt == 'ptca')]
    print(8, 'PNH[' in list(mt.lex))

    matres_column_adder_ptca = MatresColumnAdderParticiples(ptca, 'ptca')
    ptca = matres_column_adder_ptca.data

    mt = ptca[(ptca.scroll == 'MT') & (ptca.vt == 'ptca')]
    print(9, 'PNH[' in list(mt.lex))

    invalid_data_remover = InvalidDataRemover(ptca)
    ptca = invalid_data_remover.data_complete_syllables

    mt = ptca[(ptca.scroll == 'MT') & (ptca.vt == 'ptca')]
    print(10, 'PNH[' in list(mt.lex))

    pp_nme_cleaner = PassiveParticipleNMECleaner(ptcp)
    ptcp = pp_nme_cleaner.data

    matres_column_adder_ptcp = MatresColumnAdderParticiples(ptcp, 'ptcp')
    ptcp = matres_column_adder_ptcp.data

    invalid_data_remover = InvalidDataRemover(ptcp)
    ptcp = invalid_data_remover.data_complete_syllables

    return ptca, ptcp


def get_niphal_hiphil_pe_yod_data(corpus, mt):
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='niph_hiph_pe_yod')
    mt_niph_hiph_pe_yod_df = basic_mt_data_selector.select_data()

    matres_parser_dss = SpDssDataProcessor(corpus, 'dss',
                                           relevant_data='niph_hiph_pe_yod')

    niph_hiph_pe_yod_df = pd.concat([mt_niph_hiph_pe_yod_df, matres_parser_dss.matres_df])
    niph_hiph_pe_yod_df = niph_hiph_pe_yod_df.sort_values(by=['tf_id'])

    niph_hiph_pe_yod_df['other_vowel_ending'] = ''

    mt_dss_help_columns_adder = MTDSSHelpColumnsAdder(niph_hiph_pe_yod_df)
    niph_hiph_pe_yod_df = mt_dss_help_columns_adder.mt_dss_data

    rec_cor_columns_adder = RecCorColumnsAdder(niph_hiph_pe_yod_df)
    niph_hiph_pe_yod_df = rec_cor_columns_adder.data

    useless_hif_nif_pe_yod = UselessHiphNiphPeYod(niph_hiph_pe_yod_df)
    niph_hiph_pe_yod_df = useless_hif_nif_pe_yod.no_cons_waw_yod

    matres_column_adder_hif_nif_pe_yod = MatresColumnAdderHifNifPeYod(niph_hiph_pe_yod_df)
    niph_hiph_pe_yod_df = matres_column_adder_hif_nif_pe_yod.data

    invalid_data_remover = InvalidDataRemover(niph_hiph_pe_yod_df)
    niph_hiph_pe_yod_df = invalid_data_remover.data_complete_syllables

    return niph_hiph_pe_yod_df


def get_triliteral_hiphil(corpus, mt):
    """Problem of impf is that there are two forms: jaqtil en jaqtel, the latter (juss.)
    is difficult to distinguish without vocalization. Both are included in the dataset."""
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='hiph_triliteral')
    mt_hiph_triliteral_df = basic_mt_data_selector.select_data()

    matres_parser_dss = SpDssDataProcessor(corpus, 'dss',
                                           relevant_data='hiph_triliteral')

    hiph_triliteral_df = pd.concat([mt_hiph_triliteral_df, matres_parser_dss.matres_df])
    hiph_triliteral_df = hiph_triliteral_df.sort_values(by=['tf_id'])

    hiph_triliteral_df['other_vowel_ending'] = ''

    mt_dss_help_columns_adder = MTDSSHelpColumnsAdder(hiph_triliteral_df)
    hiph_triliteral_df = mt_dss_help_columns_adder.mt_dss_data

    rec_cor_columns_adder = RecCorColumnsAdder(hiph_triliteral_df)
    hiph_triliteral_df = rec_cor_columns_adder.data

    useless_hiphil_triliteral = UselessHiphilTriliteral(hiph_triliteral_df)
    hiph_triliteral_df = useless_hiphil_triliteral.relevant_combinations

    matres_column_adder_hif_triliteral = MatresColumnAdderHifTriliteral(hiph_triliteral_df)
    hiph_triliteral_df = matres_column_adder_hif_triliteral.data

    invalid_data_remover = InvalidDataRemover(hiph_triliteral_df)
    hiph_triliteral_df = invalid_data_remover.data_complete_syllables

    return hiph_triliteral_df


def get_qal_infinitive_absolute(corpus, mt):
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='inf_abs_qal')
    mt_qal_inf_abs = basic_mt_data_selector.select_data()

    matres_parser_dss = SpDssDataProcessor(corpus, 'dss',
                                           relevant_data='inf_abs_qal')

    qal_inf_abs_df = pd.concat([mt_qal_inf_abs, matres_parser_dss.matres_df])
    qal_inf_abs_df = qal_inf_abs_df.sort_values(by=['tf_id'])

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

    invalid_data_remover = InvalidDataRemover(qal_inf_abs_df)
    qal_inf_abs_df = invalid_data_remover.data_complete_syllables

    # Strange case in dataset:
    # in 4Q56 2x inf abs in 37:30, waar komen die vandaan, niet in andere manuscr.

    return qal_inf_abs_df


def get_particles(corpus, mt):
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='particles')
    mt_particles = basic_mt_data_selector.select_data()

    matres_parser_dss = SpDssDataProcessor(corpus, 'dss',
                                           relevant_data='particles')

    matres_parser_sp = SpDssDataProcessor(corpus, 'sp',
                                          relevant_data='particles')

    particles_df = pd.concat([mt_particles,
                              matres_parser_sp.matres_df,
                              matres_parser_dss.matres_df])
    particles_df = particles_df.sort_values(by=['tf_id'])

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
    particles_df['has_vowel_letter'] = np.where(particles_df.vowel_letter.str.len() > 1, 1, 0)

    invalid_data_remover = InvalidDataRemover(particles_df)
    particles_df = invalid_data_remover.data_complete_syllables

    return particles_df


def get_yiqtol_wayyiqtol_hollow_roots(corpus, mt):
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='yiq_wayq_hollow')
    mt_particles = basic_mt_data_selector.select_data()

    matres_parser_dss = SpDssDataProcessor(corpus, 'dss',
                                           relevant_data='yiq_wayq_hollow')

    pass

    # particles_df = pd.concat([mt_particles, matres_parser_dss.matres_df])
    # particles_df = particles_df.sort_values(by=['tf_id'])
    #
    # particles_df['other_vowel_ending'] = ''
    #
    # mt_dss_help_columns_adder = MTDSSHelpColumnsAdder(particles_df)
    # particles_df = mt_dss_help_columns_adder.mt_dss_data
    #
    # rec_cor_columns_adder = RecCorColumnsAdder(particles_df)
    # particles_df = rec_cor_columns_adder.data
    #
    # # add type, vowel_letter, has_vowel_letter
    # particles_df['type'] = 'single'
    # useless_particle_remover = UselessParticleRemover(particles_df)
    # particles_df = useless_particle_remover.data
    #
    # particles_df['vowel_letter'] = particles_df.g_cons.str[1:]
    # particles_df['has_vowel_letter'] = 1
    #
    # invalid_data_remover = InvalidDataRemover(particles_df)
    # particles_df = invalid_data_remover.data_complete_syllables

    #return yiqtol_wayyiqtol_hollow_roots