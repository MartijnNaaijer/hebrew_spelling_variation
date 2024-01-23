import pandas as pd


class UselessParticleRemover:
    def __init__(self, data):
        self.data = data
        self.remove_rows_without_pattern()

    def remove_rows_without_pattern(self):
        self.data = self.data[((self.data.scroll == 'MT') & (self.data.pattern.str.count('C') > 0)) |
                              (self.data.scroll != 'MT')]

    def select_allowed_g_cons(self):
        allowed_values = {'K>', 'KJ', 'KJ>', 'KJH', 'L>', 'LH', 'LW', 'LW>', 'MJ', 'MJ>', 'MJJ'}
        self.data = self.data[self.data.g_cons.isin(allowed_values)]