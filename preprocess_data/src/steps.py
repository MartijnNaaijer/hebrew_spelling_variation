"""
Processing steps that are shared by several datasets. Every step takes a DataFrame and returns a new DataFrame,
so that a dataset can be made by applying a list of steps with run_steps().
"""
from functools import cache

import numpy as np
import pandas as pd
from scipy.stats import entropy

from corpora import load_corpora
from special_data import POTENTIALLY_FEMININE_WORDS, CONSONANTAL_J_LEXEMES


def run_steps(data, steps):
    for step in steps:
        data = step(data)
    return data


def set_column(name, value):
    """Step that gives a column the same value in every row."""
    def step(data):
        data = data.copy()
        data[name] = value
        return data
    return step


def add_matres_patterns(data, pattern_dict):
    """Adds the vowel letter pattern of the word (pattern_g_cons) and of the stem (pattern).
    pattern_dict has a pattern for every tf_id. Words without a pattern get empty patterns."""
    data = data.copy()
    patterns_g_cons = [pattern_dict.get(int(tf_id), '') for tf_id in data.tf_id]
    patterns_g_cons = [pattern if isinstance(pattern, str) else '' for pattern in patterns_g_cons]
    stem_idcs = [g_cons.find(stem) for g_cons, stem in zip(data.g_cons, data.stem)]
    data['pattern'] = [pattern[idx:idx + len(stem)] for pattern, idx, stem in
                       zip(patterns_g_cons, stem_idcs, data.stem)]
    data['pattern_g_cons'] = patterns_g_cons
    return data


def convert_final_aleph(data):
    """
    If the stem ends on aleph (III-aleph roots), this letter is converted to a consonant, to harmonize these cases.
    """
    data = data.copy()
    data['pattern'] = np.where(data.stem.str[-1] == '>', data.pattern.str[:-1] + 'C', data.pattern)
    return data


@cache
def find_feminine_t_words():
    """Find all lexemes in BHSA that are feminine and have nominal ending T in lexeme.
    We can use this to remove nominal ending T in DSS words.
    Output:
        lex_set: set. Set containing lexemes.
    """
    F = load_corpora().mt.F
    lex_set = set()
    for w in F.otype.s('word'):
        lexendswitht = F.lex.v(w).strip('/').strip('=')[-1] == 'T'
        isfeminine = F.gn.v(w) == 'f'
        issubstantive = F.sp.v(w) == 'subs'
        issingular = F.nu.v(w) == 'sg'
        contains_t_nme = 'T' in F.g_nme.v(w)
        if all([lexendswitht, isfeminine, issubstantive, issingular, contains_t_nme]):
            lex_set.add(F.lex.v(w))
    return {lex for lex in lex_set if not lex.rstrip('/').rstrip('=').endswith('WT')}


def strip_feminine_t(data):
    """Move final T in feminine words to nme on basis of set of lexemes from BHSA."""
    data = data.copy()
    fem_t_words = find_feminine_t_words() | POTENTIALLY_FEMININE_WORDS
    is_t_word = [lex in fem_t_words and stem[-1] == 'T' for lex, stem in zip(data.lex, data.stem)]
    data['pattern'] = np.where(is_t_word, data.pattern.str[:-1], data.pattern)
    data['stem'] = np.where(is_t_word, data.stem.str[:-1], data.stem)
    nme = [nme if isinstance(nme, str) else '' for nme in data.nme]
    data['nme'] = ['T' + nme_val if t_word else nme_val for t_word, nme_val in zip(is_t_word, nme)]
    return data


def _other_vowel_ending(stem, vowel_count):
    try:
        return stem[-int(vowel_count):] if vowel_count else ''
    except (TypeError, ValueError):
        return ''


def split_off_other_vowel_endings(data):
    """Vowel letters at the end of the stem are moved to the column other_vowel_ending."""
    data = data.copy()
    vowel_counts = data.pattern.str.split('C').str[-1].str.count('M')
    data['other_vowel_ending'] = [_other_vowel_ending(stem, count) for stem, count in zip(data.stem, vowel_counts)]
    data['stem'] = [str(stem).removesuffix(ending) for stem, ending in zip(data.stem, data.other_vowel_ending)]
    data['pattern'] = [pattern[:len(stem)] if isinstance(pattern, str) else '' for pattern, stem
                       in zip(data.pattern, data.stem)]
    return data


def remove_final_yod(data):
    """
    Removes final yod from stems and adds it to column other_vowel_ending, even if this yod has consonantal value.
    The same is done with a final yod + aleph.
    """
    data = data.copy()
    lexemes = data.lex.str.strip('/').str.strip('=')

    # Both are determined on the stem before anything is removed.
    has_final_j = [((lex[-1] == 'J' or lex in {'CLJCJT', 'XMJCJT'}) and stem[-1] == 'J' and
                    lex_whole not in CONSONANTAL_J_LEXEMES)
                   for lex, stem, lex_whole in zip(lexemes, data.stem, data.lex)]
    has_final_j_aleph = [(lex[-1] == 'J' and stem[-2:] == 'J>') for lex, stem in zip(lexemes, data.stem)]

    data['other_vowel_ending'] = np.where(has_final_j, 'J' + data.other_vowel_ending.astype(str),
                                          data.other_vowel_ending)
    data['stem'] = np.where(has_final_j, data.stem.str[:-1], data.stem)
    data['pattern'] = np.where(has_final_j, data.pattern.str[:-1], data.pattern)

    data['other_vowel_ending'] = np.where(has_final_j_aleph, 'J>' + data.other_vowel_ending.astype(str),
                                          data.other_vowel_ending)
    data['stem'] = np.where(has_final_j_aleph, data.stem.str[:-2], data.stem)
    data['pattern'] = np.where(has_final_j_aleph, data.pattern.str[:-2], data.pattern)
    return data


def add_help_columns(data):
    """
    Adds the columns line and column (location in the manuscript, '-' for MT and SP), and the binary columns
    has_prs, has_prefix, has_hloc and has_nme (values 0 (absent) and 1 (present)).
    Note, line and column are not necessarily integers. It can also be an identifier of a fragment.
    """
    F, L = load_corpora().dss.F, load_corpora().dss.L
    data = data.copy()
    line_ids = [L.u(w, 'line')[0] if scroll not in {'MT', 'SP'} else -1 for w, scroll in zip(data.tf_id, data.scroll)]
    data['line'] = [F.line.v(line_id) if line_id != -1 else '-' for line_id in line_ids]
    data['column'] = [F.fragment.v(line_id) if line_id != -1 else '-' for line_id in line_ids]
    for column in ['prs', 'prefix', 'hloc', 'nme']:
        data[f'has_{column}'] = (data[column].str.len() > 0).astype(int)
    return data


def add_rec_cor_stem_columns(data):
    """Adds the reconstructed and corrected signs of the stem (rec_signs_stem and cor_signs_stem)."""
    data = data.copy()
    stems = [stem if isinstance(stem, str) else '' for stem in data.stem]
    for column in ['rec_signs', 'cor_signs']:
        signs = [sign if isinstance(sign, str) else '' for sign in data[column]]
        data[f'{column}_stem'] = [sign[:len(stem)] for sign, stem in zip(signs, stems)]
    return data


def get_vowel_indices_first_and_last_syllables(pattern, c_count):
    """Returns the indices of the vowel letters of a stem with one syllable (list),
    or of the first and the last syllable of a stem with more syllables (tuple of two lists)."""
    pat = pattern.strip('M')
    vowel_chunks = pat.split('C')
    idx_vowels_first_syll = [idx + 1 for idx in range(len(vowel_chunks[1]))]
    if c_count > 2:
        idx_vowels_last_syll = [idx + 1 for idx in range(len(pat) - 2 - len(vowel_chunks[-2]), len(pat) - 2)]
        return idx_vowels_first_syll, idx_vowels_last_syll
    return idx_vowels_first_syll


def add_syllable_rows(data):
    """
    Makes one row per syllable that is analyzed, with the columns
    type: str syllable type (values: first, last, single)
    vowel_letter: str (what is the vowel letter (W, J, > or a combination))
    has_vowel_letter: 1 if the syllable has a vowel letter, else 0.
    Stems with one syllable get a row of type single, if no letter of the syllable is reconstructed.
    Stems with more syllables get a row for the first and a row for the last syllable.
    """
    new_rows = {}
    for _, row in data.iterrows():
        pattern = row['pattern']
        if isinstance(pattern, float):
            pattern = ''
        if pattern.startswith('M'):
            pattern = 'C' + pattern[1:]
        c_count = pattern.count('C')
        if c_count < 2:
            continue

        idcs = get_vowel_indices_first_and_last_syllables(pattern, c_count)
        if isinstance(idcs, list):
            if sum([row.rec_signs[idx].count('r') for idx in idcs]):
                continue
            syllables = [('single', idcs)]
        else:
            syllables = [('last', idcs[1]), ('first', idcs[0])]

        for syllable_type, syllable_idcs in syllables:
            new_row = row.copy()
            new_row['type'] = syllable_type
            new_row['vowel_letter'] = ''.join([row['stem'][idx] for idx in syllable_idcs])
            new_rows[(syllable_type, new_row['tf_id'])] = new_row

    new_data = pd.DataFrame(list(new_rows.values()), dtype=object).sort_values(by=['tf_id'])
    new_data['has_vowel_letter'] = (new_data['vowel_letter'].str.len() > 0).astype(int)
    return new_data


def remove_short_stems(data, min_length=2):
    return data[data['stem'].str.len() >= min_length]


def _syllable_indices(stem, vowels, syll_type):
    syllable_length = 2 + len(vowels)
    return {'single': (0, len(stem)),
            'first': (0, syllable_length),
            'last': (-syllable_length, len(stem))}[syll_type]


def remove_reconstructed_syllables(data):
    """
    Removes syllables with reconstructed letters in it.
    This involves the vowel letter and the consonant before and after it.
    If one of these letters is reconstructed, the syllable is not taken into consideration.
    """
    is_reconstructed = []
    for rec_signs, vowels, syll_type, stem in zip(data.rec_signs_stem, data.vowel_letter, data.type, data.stem):
        if isinstance(vowels, float):
            vowels = ''
        start_idx, end_idx = _syllable_indices(stem, vowels, syll_type)
        is_reconstructed.append('r' in rec_signs[start_idx:end_idx])
    return data[~np.array(is_reconstructed, dtype=bool)]


def remove_invalid_data(data, remove_one_letter_stems=True):
    """
    From the dataset, two types of data are removed:
    1. Words with a stem consisting of one letter (if remove_one_letter_stems),
       e.g. lexemes like PH/, "mouth", and FH/, "sheep".
    2. Syllables with reconstructed letters in it (see remove_reconstructed_syllables).
    """
    if remove_one_letter_stems:
        data = remove_short_stems(data)
    return remove_reconstructed_syllables(data)


def remove_nodes(data, nodes):
    return data[~data.tf_id.isin(list(nodes))]


def remove_useless_rows(data, useless_plurals, useless_lexemes, useless_nodes):
    """
    Cleans the dataset in four steps:
    1. Remove words without matres pattern (generally ketiv/qere cases, that are excluded).
    2. Remove a number of ad-hoc cases, called useless_nodes here. You can find these nodes in special_data.py
       in the dict AD_HOC_REMOVALS.
    3. A number of plurals (and duals) do not display spelling variation. The relevant lexemes can be found in
       special_data.py in the list USELESS_PLURALS.
    4. A number of lexemes is removed, because the letter J in its stem can be both a vowel letter or consonant, e.g.
       BJT/ and >JN/. See the list REMOVE_LEXEMES in special_data.py. These words can have variation in the
       matres pattern with identical spelling.
    """
    data = data[[pat.count('C') > 0 for pat in data.pattern]]
    data = remove_nodes(data, useless_nodes)
    useless_plural = np.array([lex in useless_plurals and nu in {'du', 'pl'} for lex, nu in zip(data.lex, data.nu)],
                              dtype=bool)
    data = data[~useless_plural]
    return data[~data.lex.isin(useless_lexemes)]


def get_syllable_pattern(pattern, vowel_letters, syllable_type):
    if not isinstance(pattern, str):
        return None
    vowel_length = len(vowel_letters) if isinstance(vowel_letters, str) else 0
    if syllable_type == 'single':
        return 'C' + pattern[1:]
    elif syllable_type == 'first':
        return 'C' + pattern[:2 + vowel_length][1:]
    elif syllable_type == 'last':
        return pattern[-(2 + vowel_length):]
    raise ValueError('No valid value for syllable type:', syllable_type)


def remove_syllables_without_variation(data, entropy_threshold):
    """
    Remove Syllables in lexemes which have very low variation, based on an entropy threshold.
    E.g., in MLK/, "king", there is nowhere any variation in the spelling of the first syllable.
    In the second syllable, there is a case of a vowel letter > (ML>KJM in MT, 2Sam 11:1). This is such a rare
    phenomenon, and also a difficult reading, that the second syllable of MLK/ is also excluded from the analysis.
    """
    variable_syllables = []
    for _, dat_lex_type in data.groupby(['lex', 'type'], sort=False):
        patterns = [get_syllable_pattern(pattern, vowel_letters, syllable_type) for pattern, vowel_letters,
                    syllable_type in zip(dat_lex_type.pattern, dat_lex_type.vowel_letter, dat_lex_type.type)]
        pattern_counts = pd.Series(patterns).value_counts()
        max_count, total_count = max(pattern_counts), sum(pattern_counts)
        syll_entropy = entropy([max_count / total_count, (total_count - max_count) / total_count], base=2)

        # second requirement guarantees that variation is not only in pattern, but also in written text.
        if syll_entropy > entropy_threshold and len(set(dat_lex_type.stem)) > 1:
            variable_syllables.append(dat_lex_type)
    return pd.concat(variable_syllables).sort_values(by='tf_id')


def add_neighboring_vowel_letter(data):
    """
    Adds the column neigh_vowel_letter: 1 if the same vowel letter occurs in the neighboring syllable, else 0.
    For a single syllable, the neighboring syllable is the start of the suffix. For the first syllable, it is the
    last syllable or the start of the suffix, for the last syllable the first syllable or the start of the suffix.
    If the syllable has no vowel letter, the most frequent vowel letter of the lexeme and syllable type is used.
    """
    data = data.copy()
    most_frequent_vowel_letter = {key: group.vowel_letter.value_counts().index[0]
                                  for key, group in data.groupby(['lex', 'type'], sort=False)}
    neighboring = []
    for stem_pattern, word_pattern, syll_type, vowel_letter, stem, g_cons, lex in zip(
            data.pattern, data.pattern_g_cons, data.type, data.vowel_letter, data.stem, data.g_cons, data.lex):
        if not vowel_letter:
            vowel_letter = most_frequent_vowel_letter[(lex, syll_type)]

        suffix_pattern = word_pattern[len(stem_pattern):]
        suffix = g_cons[len(stem):]
        in_suffix = bool(suffix_pattern) and suffix_pattern[0] == 'M' and suffix[0] == vowel_letter
        if syll_type == 'single':
            neighboring.append(int(in_suffix))
        elif syll_type == 'last':
            in_first_syllable = stem_pattern[1] == 'M' and stem[1] == vowel_letter
            neighboring.append(int(in_suffix or in_first_syllable))
        elif syll_type == 'first':
            in_last_syllable = stem_pattern[-2] == 'M' and stem[-2] == vowel_letter
            neighboring.append(int(in_suffix or in_last_syllable))
    data['neigh_vowel_letter'] = neighboring
    return data
