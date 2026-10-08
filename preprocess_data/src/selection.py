"""
Selects the words of a feature (e.g. qal participles) from a word table made in words.py.
"""
from words import WORD_COLUMNS


def feature_mask(words, feature, corpus):
    """Boolean mask of the words that belong to the feature. corpus is 'mt', 'dss' or 'sp'."""
    sp, vs, vt, lex = words.sp, words.vs, words.vt, words.lex
    is_verb = sp == 'verb'

    if feature == 'subs_adjv':
        return sp.isin(['subs', 'adjv'])
    if feature == 'ptc_qal':
        mask = is_verb & vt.isin(['ptca', 'ptcp'])
        if corpus == 'sp':  # The SP does not have the verbal stem yet.
            return mask
        return mask & (vs == 'qal')
    if feature == 'infc_qal':
        return is_verb & (vt == 'infc') & (vs == 'qal')
    if feature == 'inf_abs_qal':
        return is_verb & (vt == 'infa') & (vs == 'qal')
    if feature == 'niph_hiph_pe_yod':
        return is_verb & ((lex.str[0] == 'J') | (lex == 'HLK[')) & vs.isin(['nif', 'hif', 'hof'])
    if feature == 'hiph_triliteral':
        return is_verb & (vs == 'hif') & \
            ~lex.str[1].isin(['W', 'J']) & \
            (lex.str[0] != 'J') & \
            (lex.str[2] != 'H') & \
            (lex.str[1] != lex.str[2])
    if feature == 'particles':
        return lex.isin(['KJ', 'L>', 'MJ'])
    raise ValueError(f'Unknown feature: {feature}')


def select_words(words, feature, corpus):
    """Returns the Hebrew words of the feature, with the columns in WORD_COLUMNS and tf_id as index.
    In the DSS and SP, words without lexeme, text or stem are left out."""
    words = words[words.lang == 'Hebrew']
    if corpus != 'mt':
        words = words[words.lex.astype(bool) & words.g_cons.astype(bool) & words.stem.astype(bool)]
    selected = words[feature_mask(words, feature, corpus)][WORD_COLUMNS].copy()
    selected.index = selected.tf_id.to_numpy()
    return selected
