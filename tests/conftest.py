import os
import sys

# Make the modules in preprocess_data/src importable in the tests.
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'preprocess_data', 'src'))
