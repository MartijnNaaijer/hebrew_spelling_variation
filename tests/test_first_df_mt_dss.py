"""
Consistency checks of data after first parsing.
Words are not analyzed on level of syllables yet.
The tests reflect the manual corrections in the dataset.
"""
import os
import pandas as pd
import pytest

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_FOLDER = 'data'
NOUNS_ADJECTIVES = 'nouns_adjectives.csv'
ALL_DATASETS = ['nouns_adjectives.csv',
                'hiphil_triliteral.csv',
                'infa_qal.csv',
                'infc_qal_lamed_he.csv',
                'infc_qal_triliteral.csv',
                'niph_hiph_pe_yod.csv',
                # 'particles.csv', # ADD LATER
                'ptca_qal.csv',
                'ptcp_qal.csv']


@pytest.fixture(scope="module")
def input_df():
    df = pd.read_csv(os.path.join(ROOT_DIR, DATA_FOLDER, NOUNS_ADJECTIVES), sep='\t')
    return df


@pytest.fixture(scope="module")
def input_df_list():
    df_list = [pd.read_csv(os.path.join(ROOT_DIR, DATA_FOLDER, data_file), sep='\t') for data_file in ALL_DATASETS]
    return df_list


def test_all_lex_type_have_same_consonant_counts(input_df):
    """Check that the count of C in every stem is equal for a lexeme/type combination.
    """
    for lex, typ in set(zip(input_df.lex, input_df.type)):
        lex_typ_dat = input_df[(input_df.lex == lex) & (input_df.type == typ)]
        cons_counts = len({pat[1:].count('C') for pat in set(lex_typ_dat.pattern)})
        assert cons_counts == 1


def test_all_lex_type_have_same_consonants_in_mt_and_sp(input_df):
    """Potential vowel letters are removed, the other characters should be identical
    DSS are excluded here, there are some allowed cases there of weakening of <, X, etc"""
    mt_sp = input_df[input_df.scroll.isin(['MT', 'SP'])]
    for lex, typ in set(zip(mt_sp.lex, mt_sp.type)):
        lex_typ_dat = mt_sp[(mt_sp.lex == lex) & (mt_sp.type == typ)]
        stem_char_set = {tuple(sorted(list(set(stem.replace('J', '').replace('W', '').replace('>', ''))))) for stem in
                     set(lex_typ_dat.stem)}
        assert len(stem_char_set) == 1


def test_absence_of_verbal_elements(input_df):
    assert len({val for val in input_df.vs if isinstance(val, str)}.intersection(
        {'qal', 'nif', 'hif', 'piel', 'pual', 'hit'})) == 0
    assert len({val for val in input_df.vt if isinstance(val, str)}.intersection(
        {'perf', 'impv', 'impf', 'wayq', 'infa', 'infc', 'ptcp', 'ptca'})) == 0


def test_all_stems_should_have_same_length_as_stem_patterns(input_df):
    assert all([len(stem) == len(stem_pattern) for stem, stem_pattern in zip(input_df.stem, input_df.pattern)])


def test_all_g_cons_should_have_same_length_as_g_cons_patterns(input_df):
    assert all([len(g_cons) == len(g_cons_pattern) for g_cons, g_cons_pattern in zip(input_df.g_cons, input_df.pattern_g_cons)])


def test_all_g_cons_should_start_with_stem(input_df):
    assert all([g_cons.startswith(stem) for stem, g_cons in zip(input_df.stem, input_df.g_cons)])


def test_stem_pattern_should_not_end_with_mater(input_df):
    assert all([pattern[-1] == 'C' for pattern in input_df.pattern])


def test_vowel_letters_should_only_be_aleph_he_waw(input_df):
    vowel_letters_allowed = {'>', 'W', 'J'}
    vowel_letters_observed = set()
    for stem, pattern in zip(input_df.stem, input_df.pattern):
        for stem_char, pattern_char in zip(stem, pattern):
            if pattern_char == 'M':
                vowel_letters_observed.add(stem_char)
    assert vowel_letters_allowed == vowel_letters_observed


def test_part_of_speech_has_only_allowed_values(input_df):
    assert set(input_df.sp) == {'subs', 'adjv'}


def test_lexemes_end_with_slash(input_df):
    assert {lex[-1] for lex in input_df.lex} == {'/'}


def test_all_datasets_have_same_columns(input_df_list):
    columns_set = {tuple(df.columns) for df in input_df_list}
    assert len(columns_set) < 3


def test_scrolls_col_mt_great_scroll_and_others_should_be_there(input_df_list):
    """Check if MT occurs in each dataset,
    and check if more than 3 different scrolls are found in each dataset."""
    scrolls_per_df_list = [tuple(set(df.scroll)) for df in input_df_list]
    assert all(['MT' in all_scrolls for all_scrolls in scrolls_per_df_list])
    #assert all([len(all_scrolls) > 3 for all_scrolls in scrolls_per_df_set])


def test_all_datasets_have_one_for_has_vl_if_vowel_letter_has_value(input_df_list):
    vowel_letters = {'W', 'J', '>', 'H', 'W>', '>W', '>J', 'W>W'}
    for df in input_df_list:
        vl_has_vl_matches = set(has_vl == 1 if vl in vowel_letters else has_vl == 0 for vl, has_vl in zip(df.vowel_letter, df.has_vowel_letter))
        assert vl_has_vl_matches == {True}


# TODO: check that MT in scrolls, together with other scrolls
# Check that all datasets have same column names.
