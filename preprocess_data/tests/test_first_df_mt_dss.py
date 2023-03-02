"""
Consistency checks of data after first parsing.
Words are not analyzed on level of syllables yet.

"""

import os
import pandas as pd
import pytest

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_FOLDER = 'data'
DATA_FILE = 'mt_dss_after_manual_correction.csv'
print(ROOT_DIR)


@pytest.fixture(scope="module")
def input_df():
    df = pd.read_csv(os.path.join(ROOT_DIR, DATA_FOLDER, DATA_FILE), sep=';')
    return df


def test_absence_of_verbal_elements(input_df):
    assert 'qal' not in list(input_df.vs)
    # assert len(set(input_df.vt)) == 1
