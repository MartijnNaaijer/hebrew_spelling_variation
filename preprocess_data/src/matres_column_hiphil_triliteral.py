import numpy as np
import pandas as pd


class MatresColumnAdderHifTriliteral:
    def __init__(self, data):
        self.data = data
        self.add_type_column()
        self.add_column_vowel_letter()
        self.add_column_has_vowel_letter()

    def add_type_column(self):
        self.data['type'] = 'last'

    def add_column_vowel_letter(self):
        self.data['vowel_letter'] = np.where(self.data.stem.str[-2] == 'J', 'J', '')

    def add_column_has_vowel_letter(self):
        self.data['has_vowel_letter'] = np.where(self.data.vowel_letter == 'J', 1, 0)
