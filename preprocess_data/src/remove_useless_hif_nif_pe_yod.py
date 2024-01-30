class UselessHiphNiphPeYod:
    def __init__(self, data):
        self.data = data
        self.data_hif_hof_selected_nif = self.remove_consonantal_waw_in_niphal()
        self.data_no_second_h = self.remove_words_with_h_as_second_char()
        self.no_cons_waw_yod = self.remove_other_consonantal_waw_and_yods()

    def remove_consonantal_waw_in_niphal(self):
        """In Niphal, waw is a mater only in perfect and participle.
        Other tenses are removed for the Niphal.
        """
        data_hif_hof_selected_nif = self.data[((self.data.vs == 'nif') & (self.data.vt.isin(['perf', 'ptca', 'ptcp']))) |
                                              (self.data.vs.isin(['hif', 'hof']))]
        return data_hif_hof_selected_nif

    def remove_words_with_h_as_second_char(self):
        """Removes cases like: 230380 MT Isaiah 52 5 JLL[ JHJLJLW"""
        no_second_h = self.data_hif_hof_selected_nif[self.data_hif_hof_selected_nif.g_cons.str[1] != 'H']
        return no_second_h

    def remove_other_consonantal_waw_and_yods(self):
        no_cons_waw_yod = self.data_no_second_h[~((self.data_no_second_h.g_cons.str[1].isin(['J', 'W'])) &
                                                  (self.data_no_second_h.pattern.str[0] == 'C') &
                                                  (self.data_no_second_h.scroll == 'MT'))]
        print(self.data_no_second_h.shape, no_cons_waw_yod.shape)
        return no_cons_waw_yod
