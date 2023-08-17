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

print(ROOT_DIR)

#df= pd.read_csv(os.path.join(ROOT_DIR, DATA_FOLDER, NOUNS_ADJECTIVES), sep='\t')
#print(df.shape)