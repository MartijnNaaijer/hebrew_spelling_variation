import numpy as np
import pandas as pd


class UselessParticiplesRemover:
    def __init__(self, data):
        self.data = data
        self.data_with_pattern = self.remove_rows_without_pattern()
        self.data_longer_pattern = self.remove_short_pattern()
        self.data_no_hollow_roots = self.remove_hollow_roots()
        self.no_ayin_ayin_data = self.remove_ayin_ayin_verbs()
        self.no_lamed_he_data = self.remove_lamed_he_verbs()
        self.clean_ptc_data = self.remove_irregular_patterns()

    def remove_rows_without_pattern(self):
        data_copy = self.data.copy()
        return data_copy[[pat.count('C') > 0 for pat in data_copy.pattern]]

    def remove_short_pattern(self):
        data_copy = self.data_with_pattern.copy()
        return data_copy[data_copy.pattern.str.len() > 2]

    def remove_hollow_roots(self):
        data_copy = self.data_longer_pattern.copy()
        return data_copy[~data_copy.lex.str[1].isin(['W', 'J'])]

    def remove_ayin_ayin_verbs(self):
        """Remove ayin ayin verbs where last consonant has dropped"""
        data_no_hollow_copy = self.data_no_hollow_roots.copy()
        return data_no_hollow_copy[~((data_no_hollow_copy.lex.str[1] == data_no_hollow_copy.lex.str[2]) &
                                   (data_no_hollow_copy.stem.str.len == 2))]

    def remove_lamed_he_verbs(self):
        no_ayin_ayin_copy = self.no_ayin_ayin_data.copy()
        return no_ayin_ayin_copy[no_ayin_ayin_copy.lex.str[2] != 'H']

    def remove_irregular_patterns(self):
        return self.no_lamed_he_data[((self.no_lamed_he_data.vt == 'ptca') &
                                     (self.no_lamed_he_data.pattern.isin(['CCC', 'CMCC']))) |
                                     (self.no_lamed_he_data.vt == 'ptcp')]


class PassiveParticipleNMECleaner:
    def __init__(self, data):
        self.data = data
        self.remove_nme_t_from_stem()

    def remove_nme_t_from_stem(self):
        has_nme_t = np.where((self.data.stem.str[-1] == 'T') &
                                       (self.data.lex.str.strip('[').str.strip('=').str[-1] != 'T'),
                             True, False)
        self.data.stem = np.where(has_nme_t, self.data.stem.str[:-1], self.data.stem)
        self.data.pattern = np.where(has_nme_t, self.data.pattern.str[:-1], self.data.pattern)
        self.data.nme = np.where(has_nme_t, 'T' + self.data.nme, self.data.nme)
        self.data.has_nme = np.where(has_nme_t, 1, self.data.has_nme)