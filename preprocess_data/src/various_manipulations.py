import numpy as np
import pandas as pd

from data_classes import Fdss, Ldss


class FinalAlephConverter:
    """
    If the stem ends on aleph (III-aleph roots), this letter is converted to a consonant, to harmonize these cases.
    """
    def __init__(self, data):
        self.data = data
        self.convert_final_aleph()

    def convert_final_aleph(self):
        self.data.pattern = np.where(self.data.stem.str[-1] == '>', self.data.pattern.str[:-1] + 'C', self.data.pattern)
