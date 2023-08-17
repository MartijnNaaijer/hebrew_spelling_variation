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
NOUNS_ADJECTIVES = 'nouns_adjectives_with_sp.csv'
ALL_DATASETS = ['nouns_adjectives.csv',
                'hiphil_triliteral.csv',
                'infa_qal.csv',
                'infc_qal_lamed_he.csv',
                'infc_qal_triliteral.csv',
                'niph_hiph_pe_yod.csv',
                'particles.csv',
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


#def test_all_lex_type_have_same_consonant_counts(input_df):
    """Check that the count of C in every stem is equal for a lexeme/type combination.
    """
#    for lex, typ in set(zip(input_df.lex, input_df.type)):
#        lex_typ_dat = input_df[(input_df.lex == lex) & (input_df.type == typ)]
#        cons_counts = len({pat[1:].count('C') for pat in set(lex_typ_dat.pattern)})
#        assert cons_counts == 1

# def test_absence_of_verbal_elements(input_df):
 #   assert 'qal' not in list(input_df.vs)
    # assert len(set(input_df.vt)) == 1


def test_all_stems_should_have_same_length_as_stem_patterns(input_df):
    assert all([len(stem) == len(stem_pattern) for stem, stem_pattern in zip(input_df.stem, input_df.pattern)])


def test_that_all_datasets_have_same_columns(input_df_list):
    columns_set = {tuple(df.columns) for df in input_df_list}
    assert len(columns_set) == 1


def test_scrolls_col_mt_great_scroll_and_others_should_be_there(input_df_list):
    """Check if MT and 1QIsaa occur in each dataset,
    and check if more than 3 different scrolls are found in each dataset."""
    scrolls_per_df_set = {tuple(set(df.scroll)) for df in input_df_list}
    assert all(['MT' in all_scrolls for all_scrolls in scrolls_per_df_set])
    assert all(['1Qisaa' in all_scrolls for all_scrolls in scrolls_per_df_set])
    assert all([len(all_scrolls) > 3 for all_scrolls in scrolls_per_df_set])


# TODO: check that MT in scrolls, together with other scrolls
# Check that all datasets have same column names.


