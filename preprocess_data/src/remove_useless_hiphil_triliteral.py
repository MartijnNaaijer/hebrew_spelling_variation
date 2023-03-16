class UselessHiphilTriliteral:
    def __init__(self, data):
        self.data = data
        self.relevant_combinations = self.select_relevant_forms()

    def select_relevant_forms(self):
        data_copy = self.data.copy()
        data_selected = data_copy[((data_copy.vt == 'perf') & (data_copy.ps == 'p3')) |
                              ((data_copy.vt == 'impf') & ~((data_copy.ps.isin(['p2', 'p3'])) & (data_copy.nu == 'pl') & (data_copy.gn == 'f'))) |
                              ((data_copy.vt == 'impv') & ~((data_copy.nu == 'sg') & (data_copy.gn == 'm'))) |
                              (data_copy.vt.isin(['infc', 'ptca']))]
        return data_selected
