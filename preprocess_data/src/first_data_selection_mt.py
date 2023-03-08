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
        elif self.relevant_data == 'infc_qal':
            infc_qal_data = self.data[(self.data.sp == 'verb') &
                                      (self.data.vt == 'infc') &
                                      (self.data.vs == 'qal')]
            return infc_qal_data
        elif self.relevant_data == 'niph_hiph_pe_yod':
            niph_hiphil_pe_yod_data = self.data[(self.data.sp == 'verb') &
                                                (self.data.lex.str[0] == 'J') &
                                                (self.data.vs.isin({'nif', 'hif'}))]

        return niph_hiphil_pe_yod_data