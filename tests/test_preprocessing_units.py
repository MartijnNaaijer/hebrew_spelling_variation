"""
Unit tests of the preprocessing code on small, hand-made examples. They do not need the Text-Fabric corpora.
"""
import pandas as pd
import pytest

from parse_matres_mt import MatresParserBHSA, add_dashes
from selection import feature_mask
from steps import get_vowel_indices_first_and_last_syllables, get_syllable_pattern, add_syllable_rows, \
    remove_reconstructed_syllables, split_off_other_vowel_endings, remove_final_yod, add_neighboring_vowel_letter, \
    remove_syllables_without_variation, add_matres_patterns
from verb_steps import make_ptc_patterns, correct_infc_lamed_he
from words import parse_nme_dss, to_hebrew, get_prs, DSSWordProcessor


# words.py

@pytest.mark.parametrize('args, expected', [
    (('DBRJM', 'DBR/', 'a', 'pl', 'm', 'subs', ''), ('DBR', 'JM')),     # masculine plural
    (('DBRJ', 'DBR/', 'c', 'pl', 'm', 'subs', ''), ('DBR', 'J')),       # plural construct
    (('TWRH', 'TWRH/', 'a', 'sg', 'f', 'subs', ''), ('TWR', 'H')),      # feminine singular
    (('TMJMM', 'TMJM/', None, 'pl', 'm', 'adjv', ''), ('TMJM', 'M')),  # only one M is removed
])
def test_parse_nme_dss(args, expected):
    assert parse_nme_dss(*args) == expected


def test_to_hebrew_uses_final_forms():
    assert to_hebrew('MLK') == 'מלך'
    assert to_hebrew('KMW') == 'כמו'


def test_to_hebrew_without_text_or_with_unknown_final_character():
    assert to_hebrew('') == ''
    assert to_hebrew(None) == ''
    assert to_hebrew('ML1') == ''


def test_get_prs():
    assert get_prs('+') == ''
    assert get_prs('+HM') == 'HM'


def make_dss_hiphil(stem, vt, gn, nu, ps):
    """A DSSWordProcessor without corpus, for testing the methods that only use its attributes."""
    word = DSSWordProcessor.__new__(DSSWordProcessor)
    word.vs, word.vt, word.gender, word.number, word.person = 'hif', vt, gn, nu, ps
    word.lexeme, word.glyphs, word.book, word.stem = 'CLM[', 'H' + stem, 'Isaiah', stem
    return word


def test_strip_verbal_ending_removes_only_the_ending():
    word = make_dss_hiphil('CLMTM', 'perf', 'm', 'pl', 'p2')
    word.strip_verbal_ending()
    assert word.stem == 'CLM'


def test_strip_verbal_ending_keeps_stem_without_ending():
    word = make_dss_hiphil('CLM', 'perf', 'm', 'sg', 'p3')
    word.strip_verbal_ending()
    assert word.stem == 'CLM'


# parse_matres_mt.py

@pytest.mark.parametrize('word, expected', [
    ('R;>CIJT', 'CPMCPMC'),   # rēʾšît: aleph and yod are vowel letters
    ('DAWID', 'CPCPC'),       # dawid: consonantal waw
    ('QOWL', 'CPMC'),         # qôl: waw after holem is a vowel letter
])
def test_matres_parser(word, expected):
    assert MatresParserBHSA(word).type_string == expected


def test_add_dashes():
    assert add_dashes('KOL-HA', 'CPCCP') == 'CPC-CP'


# selection.py

def test_feature_mask():
    words = pd.DataFrame({'sp': ['subs', 'verb', 'verb', 'verb', 'adjv'],
                          'vs': ['NA', 'qal', 'hif', None, 'NA'],
                          'vt': ['NA', 'ptca', 'perf', 'ptcp', 'NA'],
                          'lex': ['DBR/', 'KTB[', 'CLK[', 'KTB[', 'VWB/']})
    assert list(feature_mask(words, 'subs_adjv', 'mt')) == [True, False, False, False, True]
    assert list(feature_mask(words, 'ptc_qal', 'dss')) == [False, True, False, False, False]
    # The SP has no verbal stem, so all participles are selected.
    assert list(feature_mask(words, 'ptc_qal', 'sp')) == [False, True, False, True, False]
    assert list(feature_mask(words, 'hiph_triliteral', 'mt')) == [False, False, True, False, False]
    with pytest.raises(ValueError):
        feature_mask(words, 'unknown', 'mt')


# steps.py

@pytest.mark.parametrize('pattern, c_count, expected', [
    ('CMC', 2, [1]),
    ('CMCC', 3, ([1], [])),
    ('CCMC', 3, ([], [2])),
    ('CMCMC', 3, ([1], [3])),
])
def test_get_vowel_indices(pattern, c_count, expected):
    assert get_vowel_indices_first_and_last_syllables(pattern, c_count) == expected


@pytest.mark.parametrize('pattern, vowel_letters, syllable_type, expected', [
    ('CMCC', 'W', 'first', 'CMC'),
    ('CMCC', '', 'last', 'CC'),
    ('MCC', '', 'single', 'CCC'),
])
def test_get_syllable_pattern(pattern, vowel_letters, syllable_type, expected):
    assert get_syllable_pattern(pattern, vowel_letters, syllable_type) == expected


def test_add_matres_patterns():
    data = pd.DataFrame({'tf_id': [1, 2, 3], 'g_cons': ['HDBR', 'DBR', 'DBR'], 'stem': ['DBR', 'DBR', 'DBR']})
    with pytest.warns(UserWarning):  # the pattern of word 3 is too long
        result = add_matres_patterns(data, {1: 'CCCC', 3: 'CCCC'})
    assert list(result.pattern_g_cons) == ['CCCC', '', 'CCCC']
    assert list(result.pattern) == ['CCC', '', 'CCC']


def test_add_syllable_rows():
    data = pd.DataFrame({'tf_id': [1, 2, 3], 'stem': ['KTWB', 'QWL', 'B'], 'pattern': ['CCMC', 'CMC', 'C'],
                         'rec_signs': ['nnnn', 'nnn', 'n']})
    result = add_syllable_rows(data)
    assert list(zip(result.tf_id, result.type, result.vowel_letter, result.has_vowel_letter)) == [
        (1, 'last', 'W', 1), (1, 'first', '', 0), (2, 'single', 'W', 1)]


def test_remove_reconstructed_syllables():
    data = pd.DataFrame({'stem': ['KTWB', 'KTWB'], 'rec_signs_stem': ['nnrn', 'nnrn'],
                         'vowel_letter': ['W', ''], 'type': ['last', 'first']})
    assert list(remove_reconstructed_syllables(data).type) == ['first']


def test_split_off_other_vowel_endings_removes_one_letter():
    data = pd.DataFrame({'stem': ['THWW'], 'pattern': ['CCCM']})
    result = split_off_other_vowel_endings(data)
    assert list(result.stem) == ['THW']
    assert list(result.other_vowel_ending) == ['W']
    assert list(result.pattern) == ['CCC']


def test_remove_final_yod():
    data = pd.DataFrame({'lex': ['<NJ/', 'XLJ/', 'GWJ/'], 'stem': ['<NJ', 'XLJ>', 'GWJ'],
                         'pattern': ['CCC', 'CCCC', 'CMC'], 'other_vowel_ending': ['', '', '']})
    result = remove_final_yod(data)
    assert list(result.stem) == ['<N', 'XL', 'GWJ']  # GWJ/ has a consonantal yod
    assert list(result.other_vowel_ending) == ['J', 'J>', '']
    assert list(result.pattern) == ['CC', 'CC', 'CMC']


def test_add_neighboring_vowel_letter_uses_most_frequent_non_empty_vowel_letter():
    # Most rows of the lexeme have no vowel letter in the last syllable; the most frequent vowel letter is W.
    data = pd.DataFrame({'lex': ['BLT/'] * 3, 'type': ['last'] * 3,
                         'stem': ['BWLWT', 'BWLT', 'BLT'], 'g_cons': ['BWLWT', 'BWLT', 'BLT'],
                         'pattern': ['CMCMC', 'CMCC', 'CCC'], 'pattern_g_cons': ['CMCMC', 'CMCC', 'CCC'],
                         'vowel_letter': ['W', '', '']})
    assert list(add_neighboring_vowel_letter(data).neigh_vowel_letter) == [1, 1, 0]


def test_add_neighboring_vowel_letter_suffix():
    data = pd.DataFrame({'lex': ['QWL/'], 'type': ['single'], 'stem': ['QWL'], 'g_cons': ['QWLWT'],
                         'pattern': ['CMC'], 'pattern_g_cons': ['CMCMC'], 'vowel_letter': ['W']})
    assert list(add_neighboring_vowel_letter(data).neigh_vowel_letter) == [1]


def test_remove_syllables_without_variation():
    data = pd.DataFrame({'tf_id': [1, 2, 3, 4, 5, 6],
                         'lex': ['QWL/', 'QWL/', 'QWL/', 'MLK/', 'MLK/', 'MLK/'],
                         'type': ['single'] * 6,
                         'stem': ['QWL', 'QL', 'QWL', 'MLK', 'MLK', 'MLK'],
                         'pattern': ['CMC', 'CC', 'CMC', 'CCC', 'CCC', 'CCC'],
                         'vowel_letter': ['W', '', 'W', '', '', '']})
    assert list(remove_syllables_without_variation(data, entropy_threshold=0.05).lex) == ['QWL/'] * 3


# verb_steps.py

def test_make_ptc_patterns():
    data = pd.DataFrame({'stem': ['JWCB', 'QWTL'], 'g_cons': ['JWCBT', 'QWTLJM']})
    result = make_ptc_patterns(data)
    assert list(result.pattern) == ['CMCC', 'CMCC']
    assert list(result.pattern_g_cons) == ['CMCCC', 'CMCCMC']


def test_correct_infc_lamed_he():
    data = pd.DataFrame({'stem': ['BNWT', 'BNT', 'BN'], 'pattern': ['CCMC', 'CCC', 'CC'], 'nme': ['', '', '']})
    result = correct_infc_lamed_he(data)
    assert list(result.stem) == ['BN', 'BN']
    assert list(result.nme) == ['WT', 'T']
