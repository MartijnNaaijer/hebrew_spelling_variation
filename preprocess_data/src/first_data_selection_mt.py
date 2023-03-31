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
                                                (self.data.vs.isin({'nif', 'hif', 'hof'}))]
            return niph_hiphil_pe_yod_data

        elif self.relevant_data == 'hiph_triliteral':
            hiphil_triliteral_data = self.data[(self.data.sp == 'verb') &
                                               (self.data.vs == 'hif') &
                                               (self.data.lex.str[0] != 'J') &
                                               (self.data.lex.str[2] != 'H') &
                                               (self.data.lex.str[1] != self.data.lex.str[2]) &
                                               (self.data.vt != 'impf')
            ]
            return hiphil_triliteral_data
        elif self.relevant_data == 'particles':
            particles_data = self.data[self.data.lex.isin(['KJ', 'L>', 'MJ'])]

            return particles_data
        elif self.relevant_data == 'inf_abs_qal':
            qal_inf_abs_data = self.data[(self.data.sp == 'verb') &
                                         (self.data.vt == 'infa') &
                                         (self.data.vs == 'qal')]
            return qal_inf_abs_data
        elif self.relevant_data == 'yiq_wayq_hollow':
            yiq_wayq_hollow = self.data[(self.data.sp == 'verb') &
                                         (self.data.vt.isin(['wayq', 'impf'])) &
                                         (self.data.lex.str[1].isin(['W', 'J'])) &
                                         (self.data.vs == 'qal')]
            return yiq_wayq_hollow

