import numpy as np
import pandas as pd


class InfcLamedHeCorrector:
    """
    Infc of lamed-he verbs end on WT or T.
    This is moved from the stem to nme
    """
    def __init__(self, data):
        self.data = data
        self.remove_final_wt()
        self.remove_final_t()
        self.remove_short_stems()
        self.select_cases_with_t_in_nme()

    def remove_final_wt(self):
        has_extra_wt = np.where((self.data.stem.str[-2:] == 'WT'), True, False)

        self.data['stem'] = np.where(has_extra_wt, self.data.stem.str[:-2], self.data.stem)
        self.data['pattern'] = np.where(has_extra_wt, self.data.pattern.str[:-2], self.data.pattern)
        self.data['nme'] = np.where(has_extra_wt, 'WT' + self.data.nme, self.data.nme)

    def remove_final_t(self):
        has_extra_t = np.where((self.data.stem.str[-1] == 'T') &
                               (self.data.stem.str.len() > 2)
                               , True, False)

        self.data['stem'] = np.where(has_extra_t, self.data.stem.str[:-1], self.data.stem)
        self.data['pattern'] = np.where(has_extra_t, self.data.pattern.str[:-1], self.data.pattern)
        self.data['nme'] = np.where(has_extra_t, 'T' + self.data.nme, self.data.nme)

    def remove_short_stems(self):
        self.data = self.data[self.data.stem.str.len() > 1]

    def select_cases_with_t_in_nme(self):
        self.data = self.data[self.data.nme.str.contains('T')]


class MatresColumnAdderInfinitiveConstructLamedHe:
    def __init__(self, data):
        self.data = data
        self.add_type_column()
        self.add_column_vowel_letter()
        self.add_column_has_vowel_letter()

    def add_type_column(self):
        self.data['type'] = 'nme'

    def add_column_vowel_letter(self):
        self.data['vowel_letter'] = np.where(self.data.nme.str.contains('W'), 'W', '')

    def add_column_has_vowel_letter(self):
        self.data['has_vowel_letter'] = np.where(self.data.nme.str.contains('W'), 1, 0)


class InfcOtherCorrector:
    """
    Infc of lamed-he verbs end on WT or T.
    This is moved from the stem to nme
    """
    def __init__(self, data):
        self.data = data
        self.move_final_t_to_nme()
        self.remove_useless_lexemes()
        self.remove_hollow_roots()
        self.remove_monosyllabic_ayin_ayin_verbs()
        self.remove_pe_yod_verbs()
        self.remove_pe_nun_he_verbs_with_ending_t()
        self.remove_verbs_with_dropped_first_consonant()
        self.remove_nme_t()
        self.remove_verbs_with_prs()
        self.remove_irregular_patterns()

    def move_final_t_to_nme(self):
        has_extra_t = np.where((self.data.stem.str[-1] == 'T') &
                               (self.data.stem.str.len() > 1) &
                               (self.data.lex.str[2] != 'T')
                               , True, False)

        self.data['stem'] = np.where(has_extra_t, self.data.stem.str[:-1], self.data.stem)
        self.data['pattern'] = np.where(has_extra_t, self.data.pattern.str[:-1], self.data.pattern)
        self.data['nme'] = np.where(has_extra_t, 'T' + self.data.nme, self.data.nme)

    def remove_useless_lexemes(self):
        useless_lexemes = ['NTN[', 'LQX[', 'JD<[']
        self.data = self.data[~self.data.lex.isin(useless_lexemes)]

    def remove_hollow_roots(self):
        self.data = self.data[~self.data.lex.str[1].isin(['J', 'W'])]

    def remove_monosyllabic_ayin_ayin_verbs(self):
        """Remove ayin-ayin verbs (SBB) with pattern SB. The second and third radical need to be there."""

        correct = [word.count(lex[1]) == 2 if (lex[1] == lex[2]) else True
                   for word, lex in zip(self.data.g_cons, self.data.lex)]
        self.data = self.data[correct]

    def remove_pe_yod_verbs(self):
        """These have qal infc ending in T"""
        self.data = self.data[self.data.lex.str[0] != 'J']

    def remove_pe_nun_he_verbs_with_ending_t(self):
        self.data = self.data[~((self.data.lex.str[0].isin(['H', 'N'])) & (self.data.nme.str.contains('T')))]

    def remove_verbs_with_dropped_first_consonant(self):
        self.data = self.data[(self.data.lex.str[0]) == (self.data.g_cons.str[0])]

    def remove_nme_t(self):
        self.data = self.data[~self.data.nme.str[0].isin(['T', 'H'])]

    def remove_verbs_with_prs(self):
        """With a prs, the sound shifts from o to a."""
        self.data = self.data[self.data.prs.str.len() == 0]

    def remove_irregular_patterns(self):
        """Cases with a consonant dropped, etc.
        Only a few cases."""
        self.data = self.data[~self.data.pattern.isin(['CC', 'CCCM', 'CCM'])]


class MatresColumnAdderInfinitiveTriliteral:
    def __init__(self, data):
        self.data = data
        self.add_type_column()
        self.add_column_vowel_letter()
        self.add_column_has_vowel_letter()

    def add_type_column(self):
        self.data['type'] = 'last'

    def add_column_vowel_letter(self):
        self.data['vowel_letter'] = np.where(self.data.stem.str[-2] == 'W', 'W', '')

    def add_column_has_vowel_letter(self):
        self.data['has_vowel_letter'] = np.where(self.data.stem.str[-2] == 'W', 1, 0)
