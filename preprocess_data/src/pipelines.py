"""
Each function makes the dataset(s) of one feature from the word tables of the MT, DSS and SP (see words.py).
It returns a dictionary with the file names as keys and the DataFrames as values. Besides the datasets, it returns
the selected DSS and SP words (files all_dss_*.csv and all_sp_*.csv) for inspection.

The nouns and adjectives depend on json files with partly manually corrected matres patterns (see config.py).
"""
import json
import os
from functools import partial

import pandas as pd

from config import data_path, matres_patterns_mt_dss_file, matres_patterns_sp_file, entropy
from selection import select_words
from special_data import USELESS_PLURALS, REMOVE_LEXEMES, AD_HOC_REMOVALS
from steps import run_steps, set_column, add_matres_patterns, convert_final_aleph, strip_feminine_t, \
    split_off_other_vowel_endings, remove_final_yod, add_help_columns, add_rec_cor_stem_columns, add_syllable_rows, \
    remove_invalid_data, remove_short_stems, remove_nodes, remove_useless_rows, \
    remove_syllables_without_variation, add_neighboring_vowel_letter
import verb_steps as vs

# The SP tf_ids overlap with those of the MT, so they are shifted in the combined datasets.
SP_TF_ID_OFFSET = 100000


def load_matres_patterns(file_name):
    with open(os.path.join(data_path, file_name)) as f:
        return {int(k): v for k, v in json.load(f).items()}


def select(tables, feature, corpus):
    return select_words(tables[corpus], feature, corpus)


def combine(*datasets):
    return pd.concat(datasets).sort_values(by=['tf_id'])


def shift_sp_tf_ids(data):
    return data.assign(tf_id=data.tf_id + SP_TF_ID_OFFSET)


def first_steps(feature):
    """Steps that are applied first to the verbal forms and particles (without vowel endings)."""
    return [set_column('other_vowel_ending', ''),
            set_column('feature', feature)]


NOUN_STEPS = [
    convert_final_aleph,
    strip_feminine_t,
    split_off_other_vowel_endings,
    remove_final_yod,
    add_help_columns,
    add_rec_cor_stem_columns,
    add_syllable_rows,
    remove_invalid_data,
    partial(remove_useless_rows, useless_plurals=USELESS_PLURALS, useless_lexemes=REMOVE_LEXEMES,
            useless_nodes=AD_HOC_REMOVALS),
]


def nouns_adjectives(tables):
    """A dataset with nouns and adjectives that show orthographic variation in their stem,
    and one with all nouns and adjectives."""
    mt = select(tables, 'subs_adjv', 'mt')
    dss = select(tables, 'subs_adjv', 'dss')
    sp = select(tables, 'subs_adjv', 'sp')

    sp_patterns = load_matres_patterns(matres_patterns_sp_file)
    sp_data = run_steps(sp, [partial(add_matres_patterns, pattern_dict=sp_patterns),
                             set_column('feature', 'subs_adjv')] + NOUN_STEPS)

    mt_dss_patterns = load_matres_patterns(matres_patterns_mt_dss_file)
    mt_dss_data = run_steps(combine(mt, dss), [partial(add_matres_patterns, pattern_dict=mt_dss_patterns),
                                               set_column('feature', 'subs_adjv')] + NOUN_STEPS)

    # We want a dataset with all syllables, including the ones with very little variation.
    all_syllables = pd.concat([mt_dss_data, shift_sp_tf_ids(sp_data)])
    variable_syllables = remove_syllables_without_variation(all_syllables, entropy_threshold=entropy)

    return {'all_dss_subs_adjv.csv': dss,
            'all_sp_subs_adjv.csv': sp,
            'nouns_adjectives.csv': add_neighboring_vowel_letter(variable_syllables),
            'nouns_adjectives_incl_no_variation.csv': add_neighboring_vowel_letter(all_syllables)}


def participles_qal(tables):
    """Active and passive qal participles."""
    mt = select(tables, 'ptc_qal', 'mt')
    dss = select(tables, 'ptc_qal', 'dss')
    sp = select(tables, 'ptc_qal', 'sp')

    sp_data = vs.select_sp_qal_participles(shift_sp_tf_ids(vs.make_ptc_patterns(sp)))
    data = run_steps(combine(mt, vs.make_ptc_patterns(dss), sp_data), [
        set_column('feature', 'ptc_qal'),
        vs.remove_useless_participles,
        convert_final_aleph,
        strip_feminine_t,
        split_off_other_vowel_endings,
        remove_final_yod,
        add_help_columns,
        add_rec_cor_stem_columns,
    ])
    # TODO: patterns "CCMC" are strange, "CMCC" is expected.
    ptca = run_steps(data[data.vt == 'ptca'], [
        vs.correct_active_participles,
        vs.add_vowel_letter_active_participles,
        remove_invalid_data,
    ])
    ptcp = run_steps(data[data.vt == 'ptcp'], [
        vs.move_nme_t_of_passive_participles,
        vs.add_vowel_letter_passive_participles,
        remove_invalid_data,
    ])
    return {'all_dss_ptc_qal.csv': dss,
            'all_sp_ptc_qal.csv': sp,
            'ptca_qal.csv': ptca.sort_values(by=['tf_id']),
            'ptcp_qal.csv': ptcp.sort_values(by=['tf_id'])}


def infinitive_construct_qal(tables):
    """Qal infinitive construct of lamed-he verbs (vowel letter in the ending) and of other verbs."""
    dss = select(tables, 'infc_qal', 'dss')
    data = run_steps(combine(select(tables, 'infc_qal', 'mt'), dss),
                     first_steps('infc_qal') + [convert_final_aleph])

    lamed_he = run_steps(data[data.lex.str[2] == 'H'], [
        vs.correct_infc_lamed_he,
        add_help_columns,
        add_rec_cor_stem_columns,
        vs.add_vowel_letter_infc_lamed_he,
        remove_short_stems,
        vs.remove_reconstructed_nme,
    ])
    other = run_steps(data[data.lex.str[2] != 'H'], [
        vs.correct_infc_triliteral,
        add_help_columns,
        add_rec_cor_stem_columns,
        vs.add_vowel_letter_last_syllable_w,
        remove_invalid_data,
    ])
    return {'all_dss_infc_qal.csv': dss,
            'infc_qal_lamed_he.csv': lamed_he,
            'infc_qal_triliteral.csv': other}


def niphal_hiphil_pe_yod(tables):
    dss = select(tables, 'niph_hiph_pe_yod', 'dss')
    data = run_steps(combine(select(tables, 'niph_hiph_pe_yod', 'mt'), dss), first_steps('niph_hiph_pe_yod') + [
        add_help_columns,
        add_rec_cor_stem_columns,
        vs.remove_useless_hif_nif_pe_yod,
        vs.add_vowel_letter_hif_nif_pe_yod,
        partial(remove_invalid_data, remove_one_letter_stems=False),
    ])
    return {'all_dss_niph_hiph_pe_yod.csv': dss,
            'niph_hiph_pe_yod.csv': data}


def hiphil_triliteral(tables):
    """Problem of impf is that there are two forms: jaqtil en jaqtel, the latter (juss.)
    is difficult to distinguish without vocalization. Both are included in the dataset."""
    dss = select(tables, 'hiph_triliteral', 'dss')
    data = run_steps(combine(select(tables, 'hiph_triliteral', 'mt'), dss), first_steps('hiph_triliteral') + [
        add_help_columns,
        add_rec_cor_stem_columns,
        vs.select_relevant_hiphil_forms,
        vs.add_vowel_letter_hiphil,
        remove_invalid_data,
        partial(remove_nodes, nodes=AD_HOC_REMOVALS),
    ])
    return {'all_dss_hiph_triliteral.csv': dss,
            'hiphil_triliteral.csv': data}


def infinitive_absolute_qal(tables):
    # Strange case in dataset:
    # in 4Q56 2x inf abs in 37:30, waar komen die vandaan, niet in andere manuscr.
    dss = select(tables, 'inf_abs_qal', 'dss')
    data = run_steps(combine(select(tables, 'inf_abs_qal', 'mt'), dss), first_steps('inf_abs_qal') + [
        add_help_columns,
        add_rec_cor_stem_columns,
        vs.remove_useless_inf_abs,
        vs.add_vowel_letter_last_syllable_w,
        remove_invalid_data,
        partial(remove_nodes, nodes=AD_HOC_REMOVALS),
    ])
    return {'all_dss_inf_abs_qal.csv': dss,
            'infa_qal.csv': data}


def particles(tables):
    """The particles KJ, L> and MJ."""
    dss = select(tables, 'particles', 'dss')
    sp = select(tables, 'particles', 'sp')
    data = run_steps(combine(select(tables, 'particles', 'mt'), sp, dss), first_steps('particles') + [
        add_help_columns,
        add_rec_cor_stem_columns,
        vs.remove_mt_particles_without_pattern,
        vs.add_vowel_letter_particles,
        remove_invalid_data,
    ])
    return {'all_dss_particles.csv': dss,
            'all_sp_particles.csv': sp,
            'particles.csv': data}


PIPELINES = {
    'nouns': nouns_adjectives,
    'ptc': participles_qal,
    'infc': infinitive_construct_qal,
    'hiphil': hiphil_triliteral,
    'niph_hiph_pe_yod': niphal_hiphil_pe_yod,
    'particles': particles,
    'infa': infinitive_absolute_qal,
}
