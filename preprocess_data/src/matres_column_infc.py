import numpy as np
import pandas as pd


class InfcLamedHeCorrector:
    """
    Infc of lamed-he verbs end on WT or T.
    This is moved from the stem to nme
    """
    def __init__(self, data):
        self.data = data
        self.remove_final_wt()
        self.remove_final_t()
        self.remove_short_stems()

    def remove_final_wt(self):
        has_extra_wt = np.where((self.data.stem.str[-2:] == 'WT'), True, False)

        self.data['stem'] = np.where(has_extra_wt, self.data.stem.str[:-2], self.data.stem)
        self.data['pattern'] = np.where(has_extra_wt, self.data.pattern.str[:-2], self.data.pattern)
        self.data['nme'] = np.where(has_extra_wt, 'WT' + self.data.nme, self.data.nme)
        #self.data['has_nme'] = np.where(has_extra_wt, 1, self.data.has_nme)

    def remove_final_t(self):
        has_extra_t = np.where((self.data.stem.str[-1] == 'T') &
                               ((self.data.stem.str.len() > 2))
                               , True, False)

        self.data['stem'] = np.where(has_extra_t, self.data.stem.str[:-1], self.data.stem)
        self.data['pattern'] = np.where(has_extra_t, self.data.pattern.str[:-1], self.data.pattern)
        self.data['nme'] = np.where(has_extra_t, 'T' + self.data.nme, self.data.nme)
        #self.data['has_nme'] = np.where(has_extra_t, 1, self.data.has_nme)

    def remove_short_stems(self):
        self.data = self.data[self.data.stem.str.len() > 1]
