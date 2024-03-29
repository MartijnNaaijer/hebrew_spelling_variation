import numpy as np
import pandas as pd


class UselessParticiplesRemover:
    def __init__(self, data):
        self.data = data
        self.data_with_pattern = self.remove_rows_without_pattern()
        self.data_longer_pattern = self.remove_short_pattern()
        self.data_no_hollow_roots = self.remove_hollow_roots()
        self.clean_ptc_data = self.remove_ayin_ayin_verbs()

    def remove_rows_without_pattern(self):
        """MT cases have to have a pattern."""
        data_copy = self.data.copy()
        copy_cleaned = data_copy[[pat.count('C') > 0 for pat in data_copy.pattern]]
        return copy_cleaned

    def remove_short_pattern(self):
        data_copy = self.data_with_pattern.copy()
        copy_cleaned = data_copy[data_copy.pattern.str.len() > 1]
        return copy_cleaned

    def remove_hollow_roots(self):
        data_copy = self.data_longer_pattern.copy()
        return data_copy[~data_copy.lex.str[1].isin(['W', 'J'])]

    def remove_ayin_ayin_verbs(self):
        """Remove ayin ayin verbs where last consonant has dropped"""
        data_copy = self.data_no_hollow_roots.copy()
        ayin_ayin = data_copy[data_copy.lex.str[1] == data_copy.lex.str[2]]
        no_ayin_ayin = data_copy[~(data_copy.lex.str[1] == data_copy.lex.str[2])]
        ay_ay_strings = ayin_ayin.lex.str[1:3]
        ay_ay_bools = [(ay_ay_string in ay_ay_g_cons) or (vt == 'ptcp') for ay_ay_string, ay_ay_g_cons, vt in
                       zip(ay_ay_strings, ayin_ayin.g_cons, ayin_ayin.vt)]
        ayin_ayin = ayin_ayin[ay_ay_bools]
        all_data = pd.concat([ayin_ayin, no_ayin_ayin])
        all_data = all_data.sort_values(by='tf_id')

        return all_data


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
