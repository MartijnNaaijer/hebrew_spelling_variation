import os
from pathlib import Path

bhsa_version = '2021'
dss_version = '1.9'
sp_version = '6.0.3' # if made higher, json file with pattern_data_sp should also be updated!

# Input files are read from data_path, the datasets are written to output_path.
# Set the environment variable SPELLING_OUTPUT_DIR (or use main.py --out) to write them elsewhere.
data_path = str(Path(__file__).resolve().parents[2] / 'data')
output_path = os.environ.get('SPELLING_OUTPUT_DIR', data_path)

matres_patterns_mt_dss_file = 'pattern_data_mt_dss.json'
matres_patterns_sp_file = f'pattern_data_sp_{sp_version}.json'

entropy = 0.05
