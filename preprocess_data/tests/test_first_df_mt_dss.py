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
DATA_FILE = 'mt_dss_new_matres_pattern.csv'


@pytest.fixture(scope="module")
def input_df():
    df = pd.read_csv(os.path.join(ROOT_DIR, DATA_FOLDER, DATA_FILE), sep='\t')
    return df


def test_all_lex_type_have_same_consonant_counts(input_df):
    """Check that the count of C in every stem is equal for a lexeme/type combination.
    """
    for lex, typ in set(zip(input_df.lex, input_df.type)):
        lex_typ_dat = input_df[(input_df.lex == lex) & (input_df.type == typ)]
        cons_counts = len({pat[1:].count('C') for pat in set(lex_typ_dat.pattern)})
        assert cons_counts == 1

# def test_absence_of_verbal_elements(input_df):
 #   assert 'qal' not in list(input_df.vs)
    # assert len(set(input_df.vt)) == 1
