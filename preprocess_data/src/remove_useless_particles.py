import pandas as pd


class UselessParticleRemover:
    def __init__(self, data):
        self.data = data
        self.remove_rows_without_pattern()

    def remove_rows_without_pattern(self):
        self.data = self.data[[pat.count('C') > 0 for pat in self.data.pattern]]

    def select_allowed_g_cons(self):
        allowed_values = {'K>', 'KJ', 'KJ>', 'KJH', 'L>', 'LH', 'LW', 'LW>', 'MJ', 'MJ>', 'MJJ'}
        self.data = self.data[self.data.g_cons.isin(allowed_values)]