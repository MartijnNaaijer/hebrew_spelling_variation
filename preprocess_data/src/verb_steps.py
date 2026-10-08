"""
Processing steps for specific verbal forms and the particles. Like in steps.py, every step takes a DataFrame and
returns a new DataFrame.
"""
import numpy as np
import pandas as pd


def _move_final_letters_to_nme(data, mask, n_letters):
    """Moves the last n_letters of the stem (and pattern) to the start of nme, for the rows in mask."""
    data = data.copy()
    letters = data.stem.str[-n_letters:]
    data['stem'] = np.where(mask, data.stem.str[:-n_letters], data.stem)
    data['pattern'] = np.where(mask, data.pattern.str[:-n_letters], data.pattern)
    data['nme'] = np.where(mask, letters + data.nme, data.nme)
    return data


def _add_vowel_letter_columns(data, syllable_type, vowel_letter, has_vowel_letter):
    data = data.copy()
    data['type'] = syllable_type
    data['vowel_letter'] = vowel_letter
    data['has_vowel_letter'] = has_vowel_letter
    return data


def remove_hollow_roots(data):
    return data[~data.lex.str[1].isin(['W', 'J'])]


# Participles

def make_ptc_patterns(data):
    """Pattern for DSS and SP participles: every W and J is a vowel letter, except the first letter."""
    def ptc_pattern(text):
        return 'C' + ''.join(['C' if char not in {'J', 'W'} else 'M' for char in text])[1:]

    data = data.copy()
    data['pattern'] = [ptc_pattern(stem) for stem in data.stem]
    data['pattern_g_cons'] = [ptc_pattern(g_cons) for g_cons in data.g_cons]
    return data


def select_sp_qal_participles(data):
    """The SP has no verbal stem yet. Qal participles are the participles that start with the stem."""
    return data[[stem == g_cons[:len(stem)] for stem, g_cons in zip(data.stem, data.g_cons)]]


def remove_useless_participles(data):
    """Removes participles without pattern (only MT cases have to have a pattern), with a pattern of one letter,
    of hollow roots, and of ayin-ayin roots where the last consonant has dropped."""
    data = data[[pat.count('C') > 0 for pat in data.pattern]]
    data = data[data.pattern.str.len() > 1]
    data = remove_hollow_roots(data)

    is_ayin_ayin = data.lex.str[1] == data.lex.str[2]
    ayin_ayin = data[is_ayin_ayin]
    keep = [(ay_ay_string in g_cons) or (vt == 'ptcp')
            for ay_ay_string, g_cons, vt in zip(ayin_ayin.lex.str[1:3], ayin_ayin.g_cons, ayin_ayin.vt)]
    return pd.concat([ayin_ayin[keep], data[~is_ayin_ayin]]).sort_values(by='tf_id')


def correct_active_participles(data):
    data = data.copy()
    # The model sometimes thinks that W has consonantal value, which is corrected here.
    data['pattern'] = np.where((data.pattern == 'CCCC') & (data.g_cons.str[1] == 'W'),
                               'CM' + data.pattern.str[2:],
                               data.pattern)
    data['pattern_g_cons'] = np.where((data.pattern == 'CCCC') & (data.g_cons.str[1] == 'W'),
                                      'CW' + data.pattern_g_cons.str[2:],
                                      data.pattern_g_cons)

    # Remove feminine T.
    has_extra_t = (data.stem.str[-1] == 'T') & (data.lex.str[:3].str[-1] != 'T') & \
                  (data.gn == 'f') & (data.nu == 'sg')
    data = _move_final_letters_to_nme(data, has_extra_t, 1)
    data['has_nme'] = np.where(has_extra_t, 1, data.has_nme)

    data['pattern'] = 'C' + data.pattern.str[1:]
    return data[data.pattern.str.count('C') > 1]  # We keep cases like PNH[


def move_nme_t_of_passive_participles(data):
    has_nme_t = (data.stem.str[-1] == 'T') & (data.lex.str.strip('[').str.strip('=').str[-1] != 'T')
    data = _move_final_letters_to_nme(data, has_nme_t, 1)
    data['has_nme'] = np.where(has_nme_t, 1, data.has_nme)
    return data


def add_vowel_letter_active_participles(data):
    has_vowel_letter = data.pattern.str[1] == 'M'
    return _add_vowel_letter_columns(data, 'first', np.where(has_vowel_letter, data.stem.str[1], ''),
                                     np.where(has_vowel_letter, 1, 0))


def add_vowel_letter_passive_participles(data):
    has_vowel_letter = data.g_cons.str[2] == 'W'
    return _add_vowel_letter_columns(data, 'last', np.where(has_vowel_letter, 'W', ''),
                                     np.where(has_vowel_letter, 1, 0))


# Infinitive construct

def correct_infc_lamed_he(data):
    """Infc of lamed-he verbs end on WT or T. This is moved from the stem to nme."""
    data = _move_final_letters_to_nme(data, data.stem.str[-2:] == 'WT', 2)
    data = _move_final_letters_to_nme(data, (data.stem.str[-1] == 'T') & (data.stem.str.len() > 2), 1)
    data = data[data.stem.str.len() > 1]
    return data[data.nme.str.contains('T')]


def add_vowel_letter_infc_lamed_he(data):
    has_w = data.nme.str.contains('W')
    return _add_vowel_letter_columns(data, 'nme', np.where(has_w, 'W', ''), np.where(has_w, 1, 0))


def remove_reconstructed_nme(data):
    """Removes cases where the nme or the letter before it is reconstructed."""
    is_reconstructed = []
    for rec_signs, nme in zip(data.rec_signs, data.nme):
        if isinstance(nme, float):
            nme = ''
        is_reconstructed.append('r' in rec_signs[-(len(nme) + 1):])
    return data[~np.array(is_reconstructed, dtype=bool)]


def correct_infc_triliteral(data):
    """Moves a final T to nme and removes the forms that are not useful for the analysis."""
    has_extra_t = (data.stem.str[-1] == 'T') & (data.stem.str.len() > 1) & (data.lex.str[2] != 'T')
    data = _move_final_letters_to_nme(data, has_extra_t, 1)
    data = data[~data.lex.isin(['NTN[', 'LQX[', 'JD<['])]
    data = remove_hollow_roots(data)
    # Remove ayin-ayin verbs (SBB) with pattern SB. The second and third radical need to be there.
    data = data[[word.count(lex[1]) == 2 if (lex[1] == lex[2]) else True
                 for word, lex in zip(data.g_cons, data.lex)]]
    # Pe-yod verbs have a qal infc ending in T.
    data = data[data.lex.str[0] != 'J']
    data = data[~((data.lex.str[0].isin(['H', 'N'])) & (data.nme.str.contains('T')))]
    # Verbs with dropped first consonant
    data = data[(data.lex.str[0]) == (data.g_cons.str[0])]
    data = data[~data.nme.str[0].isin(['T', 'H'])]
    # With a prs, the sound shifts from o to a.
    data = data[data.prs.str.len() == 0]
    # Cases with a consonant dropped, etc. Only a few cases.
    return data[~data.pattern.isin(['CC', 'CCCM', 'CCM'])]


def add_vowel_letter_last_syllable_w(data):
    has_w = data.stem.str[-2] == 'W'
    return _add_vowel_letter_columns(data, 'last', np.where(has_w, 'W', ''), np.where(has_w, 1, 0))


# Infinitive absolute

def remove_useless_inf_abs(data):
    data = remove_hollow_roots(data)
    # Remove ayin ayin verbs where last consonant has dropped.
    data = data[~((data.lex.str[1] == data.lex.str[2]) & (data.stem.str.len() == 2))]
    # Remove lamed-he verbs
    return data[data.lex.str[2] != 'H']


# Niphal, hiphil and hophal of pe-yod verbs

def remove_useless_hif_nif_pe_yod(data):
    # In Niphal, waw is a mater only in perfect and participle. Other tenses are removed for the Niphal.
    data = data[((data.vs == 'nif') & (data.vt.isin(['perf', 'ptca', 'ptcp']))) | (data.vs.isin(['hif', 'hof']))]
    # Removes cases like: 230380 MT Isaiah 52 5 JLL[ JHJLJLW
    data = data[data.g_cons.str[1] != 'H']
    # Remove consonantal waw and yod in the MT
    return data[~((data.g_cons.str[1].isin(['J', 'W'])) & (data.pattern.str[0] == 'C') & (data.scroll == 'MT'))]


def add_vowel_letter_hif_nif_pe_yod(data):
    vowel_letter = np.where(data.g_cons.str[1].isin(['W', 'J']), data.g_cons.str[1], '')
    return _add_vowel_letter_columns(data, 'first', vowel_letter, np.where(np.isin(vowel_letter, ['W', 'J']), 1, 0))


# Triliteral hiphil

def select_relevant_hiphil_forms(data):
    return data[((data.vt == 'perf') & (data.ps == 'p3')) |
                ((data.vt == 'impf') & ~((data.ps.isin(['p2', 'p3'])) & (data.nu == 'pl') & (data.gn == 'f'))) |
                (data.vt == 'impv') |
                (data.vt.isin(['infc', 'ptca'])) |
                (data.vt == 'wayq')]


def add_vowel_letter_hiphil(data):
    has_j = data.stem.str[-2] == 'J'
    return _add_vowel_letter_columns(data, 'last', np.where(has_j, 'J', ''), np.where(has_j, 1, 0))


# Particles

def remove_mt_particles_without_pattern(data):
    return data[((data.scroll == 'MT') & (data.pattern.str.count('C') > 0)) | (data.scroll != 'MT')]


def add_vowel_letter_particles(data):
    vowel_letter = data.g_cons.str[1:]
    return _add_vowel_letter_columns(data, 'single', vowel_letter, np.where(vowel_letter.str.len() > 1, 1, 0))
