import numpy as np
import pandas as pd


class ParticiplesCorrector:
    """"""

    def __init__(self, data):
        self.data = data
        self.remove_empty_patterns()
        self.remove_short_patterns()
        self.give_mater_vowel_value()
        self.remove_feminine_t()
        self.make_first_letter_consonantal()
        self.select_triconsonantal_stems()

    def remove_empty_patterns(self):
        self.data = self.data.dropna(subset=['pattern'])

    def remove_short_patterns(self):
        self.data = self.data[self.data.pattern.str.len() > 2]

    def give_mater_vowel_value(self):
        """
        The model sometimes thinks that W has consonantal value, which is corrected here.
        """
        self.data['pattern'] = np.where((self.data.pattern == 'CCCC') & (self.data.g_cons.str[1] == 'W'),
                                        'CM' + self.data.pattern.str[2:],
                                        self.data.pattern)
        self.data['pattern_g_cons'] = np.where((self.data.pattern == 'CCCC') &
                                               (self.data.g_cons.str[1] == 'W'),
                                               'CW' + self.data.pattern_g_cons.str[2:],
                                               self.data.pattern_g_cons)

    def remove_feminine_t(self):
        has_extra_t = np.where((self.data.stem.str[-1] == 'T') &
                               (self.data.lex.str[:3].str[-1] != 'T') &
                               (self.data.gn == 'f') & (self.data.nu == 'sg'),
                               True, False)

        self.data['stem'] = np.where(has_extra_t, self.data.stem.str[:-1], self.data.stem)
        self.data['pattern'] = np.where(has_extra_t, self.data.pattern.str[:-1], self.data.pattern)
        self.data['nme'] = np.where(has_extra_t, 'T' + self.data.nme, self.data.nme)
        self.data['has_nme'] = np.where(has_extra_t, 1, self.data.has_nme)

    def make_first_letter_consonantal(self):
        self.data['pattern'] = 'C' + self.data.pattern.str[1:]

    def select_triconsonantal_stems(self):
        self.data = self.data[self.data.pattern.str.count('C') == 3]


class MatresColumnAdderParticiples:
    """
    """

