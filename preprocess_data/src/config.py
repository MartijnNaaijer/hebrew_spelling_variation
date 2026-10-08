from pathlib import Path

bhsa_version = '2021'
dss_version = '1.9'
sp_version = '6.0.3'  # if made higher, json file with pattern_data_sp should also be updated!

# The input files are read from data_path, the datasets are written there too (unless main.py --out is used).
data_path = str(Path(__file__).resolve().parents[2] / 'data')

matres_patterns_mt_dss_file = 'pattern_data_mt_dss.json'
matres_patterns_sp_file = f'pattern_data_sp_{sp_version}.json'

entropy = 0.05
