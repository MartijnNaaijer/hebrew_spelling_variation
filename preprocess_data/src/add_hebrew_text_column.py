class HebrewTextAdder:
    def __init__(self, data):
        self.data = data
        self.alphabet_dict_heb_lat = {'א': '>',
                                      'ב': 'B',
                                      'ג': 'G',
                                      'ד': 'D',
                                      'ה': 'H',
                                      'ו': 'W',
                                      'ז': 'Z',
                                      'ח': 'X',
                                      'ט': 'V',
                                      'י': 'J',
                                      'כ': 'K',
                                      'ל': 'L',
                                      'מ': 'M',
                                      'נ': 'N',
                                      'ס': 'S',
                                      'ע': '<',
                                      'פ': 'P',
                                      'צ': 'Y',
                                      'ק': 'Q',
                                      'ר': 'R',
                                      'ש': 'F',
                                      'ת': 'T'}
        self.alphabet_dict_lat_heb = {v: k for k, v in self.alphabet_dict_heb_lat.items()}
        self.alphabet_dict_lat_heb['C'] = 'ש'
        self.final_alphabet_dict_lat_heb = {'K': 'ך', 'M': 'ם', 'N': 'ן', 'P': 'ף', 'Y': 'ץ'}
        self.final_alphabet_dict_lat_heb = {**self.alphabet_dict_lat_heb, **self.final_alphabet_dict_lat_heb}

        self.add_hebrew_g_cons_column()

    def add_hebrew_g_cons_column(self):
        heb_g_cons_list = []
        for g_cons in self.data.g_cons:
            if isinstance(g_cons, str) and g_cons:
                heb_str = ''.join([self.alphabet_dict_lat_heb[c] if c in self.alphabet_dict_lat_heb else '_'
                                   for c in g_cons[:-1]])

                heb_str = heb_str + self.final_alphabet_dict_lat_heb[g_cons[-1]]
                heb_g_cons_list.append(heb_str)
            else:
                heb_g_cons_list.append('')
        self.data['heb_g_cons'] = heb_g_cons_list
