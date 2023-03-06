import pandas as pd


class BasicMTDataSelector:
    def __init__(self, data, relevant_data):
        self.data = data
        self.relevant_data = relevant_data

    def select_data(self):
        if self.relevant_data == 'subs_adjv':
            return self.data[self.data.sp.isin(['subs', 'adjv'])]
        elif self.relevant_data == 'ptc_qal':
            participle_qal_data = self.data[(self.data.sp == 'verb') &
                                            (self.data.vt.isin(['ptca', 'ptcp'])) &
                                            (self.data.vs == 'qal')]
            return participle_qal_data
