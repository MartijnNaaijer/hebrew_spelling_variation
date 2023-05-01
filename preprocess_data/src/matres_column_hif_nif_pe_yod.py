import numpy as np
import pandas as pd


class MatresColumnAdderHifNifPeYod:
    def __init__(self, data):
        self.data = data
        self.add_type_column()
        self.add_column_vowel_letter()
        self.add_column_has_vowel_letter()

    def add_type_column(self):
        self.data['type'] = 'first'

    def add_column_vowel_letter(self):
        self.data['vowel_letter'] = np.where(self.data.g_cons.str[1].isin(['W', 'J']), self.data.g_cons.str[1], '')

    def add_column_has_vowel_letter(self):
        self.data['has_vowel_letter'] = np.where(self.data.vowel_letter.isin(['W', 'J']), 1, 0)
