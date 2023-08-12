class HebrewTextAdder:
    def __init__(self, g_cons):
        self.g_cons = g_cons
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

    def get_hebrew_g_cons(self):
        if self.g_cons:
            try:
                heb_str = ''.join([self.alphabet_dict_lat_heb[c] if c in self.alphabet_dict_lat_heb else '_'
                                   for c in self.g_cons[:-1]])
                heb_str = heb_str + self.final_alphabet_dict_lat_heb[self.g_cons[-1]]
                return heb_str
            except:
                return ''
        else:
            return ''
