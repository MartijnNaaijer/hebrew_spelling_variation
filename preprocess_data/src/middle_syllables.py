import pandas as pd


class MiddleSyllableVariationFinder:
    def __init__(self, data):
        self.data = data.query("sp in ('subs', 'adjv')")
        self.data['pattern_first_c'] = ['C' + patt[1:] if isinstance(patt, str) and len(patt) > 1 else 'CC' for patt in self.data.pattern]
        self.long_stems_df = self.data[self.data.pattern_first_c.str.count('C') > 3]
        self.lexemes = set(self.long_stems_df.lex)
        self.syll_position = {2: 'second', 3: 'third', 4: 'fourth', 5: 'fifth'}
        self.rows_with_middle_syllable_variation = {}
        self.loop_over_all_lexemes()
        self.data_with_middle_syllabi = self.merge_rows_in_df()

    def loop_over_all_lexemes(self):
        for lex in self.lexemes:
            lex_df = self.long_stems_df.query('lex==@lex').copy().reset_index()
            potential_syll_vowels = lex_df.pattern.str.split('C')
            stem_length = lex_df.pattern_first_c.loc[0].count('C')
            middle_syllable_indices = range(2, stem_length - 1)
            self.check_middle_syllables_in_lexeme(lex_df, middle_syllable_indices, potential_syll_vowels)

    def check_middle_syllables_in_lexeme(self, lex_df, middle_syllable_indices, potential_syll_vowels):
        for middle_syllable_idx in middle_syllable_indices:
            vowels_in_syllable = list(potential_syll_vowels.apply(lambda x: x[middle_syllable_idx]))
            vowels_in_syllable_set = set(vowels_in_syllable)
            if len(vowels_in_syllable_set) > 1:

                for df_idx, row in lex_df.iterrows():
                    vowel_letter = self.get_middle_vowel_letter(row.pattern_first_c, row.stem, vowels_in_syllable,
                                                                df_idx, middle_syllable_idx)
                    syll_type = self.syll_position[middle_syllable_idx]
                    self.rows_with_middle_syllable_variation[(row.tf_id, syll_type)] = self.construct_new_row(
                        row, vowel_letter, syll_type)

    @staticmethod
    def get_middle_vowel_letter(pattern, stem, vowels_in_syllable, df_idx, syllable_idx):
        if not vowels_in_syllable[df_idx]:
            vowel_letter = ''
        else:
            consonant_indices = [cons_idx for cons_idx, char in enumerate(pattern) if char == 'C']
            vowel_idx = consonant_indices[syllable_idx - 1] + 1
            vowel_letter = stem[vowel_idx]
        return vowel_letter

    @staticmethod
    def construct_new_row(row, vowel_letter, syll_type):
        new_row = row.copy()
        new_row = new_row.drop('pattern_first_c')
        new_row['type'] = syll_type
        new_row['vowel_letter'] = vowel_letter
        return new_row

    def merge_rows_in_df(self):
        new_df = pd.DataFrame(self.rows_with_middle_syllable_variation).T
        new_df = new_df.sort_values(by=['tf_id'])
        return new_df

mt_file = '../data/matres_mt.csv'

mt_data = pd.read_csv(mt_file, sep='\t')
middle_syll_finder = MiddleSyllableVariationFinder(mt_data)
print(middle_syll_finder.data_with_middle_syllabi.shape)
print(middle_syll_finder.data_with_middle_syllabi.head)
#
# lexemes = set(long_stems.lex)
#
# for lex in lexemes:
#     lex_df = long_stems.query('lex==@lex').copy().reset_index()
#
#     syll_vowels = lex_df.pattern.str.split('C')
#
#     stem_len = lex_df.pattern.loc[0].count('C')
#     indices = range(2, stem_len - 1)
#     for idx in indices:
#
#         vowels_in_syllable = list(syll_vowels.apply(lambda x: x[idx]))
#         vowels_in_syllable_set = set(vowels_in_syllable)
#
#         if len(vowels_in_syllable_set) > 1:
#
#             for df_idx, row in lex_df.iterrows():
#                 consonant_indices = [cons_idx for cons_idx, char in enumerate(row.pattern) if char == 'C']
#                 if not vowels_in_syllable[df_idx]:
#                     vowel_letter = ''
#                 else:
#                     vowel_idx = consonant_indices[idx - 1] + 1
#                     vowel_letter = row.stem[vowel_idx]
#                 print(row.lex, row.g_cons, row.stem, idx, repr(vowel_letter))
#
# def get_middle_vowel_letter(pattern, stem, vowels_in_syllable, df_idx, syllable_idx, vowels_in_syllable):
#     if not vowels_in_syllable[df_idx]:
#         vowel_letter = ''
#     else:
#         consonant_indices = [cons_idx for cons_idx, char in enumerate(pattern) if char == 'C']
#         vowel_idx = consonant_indices[syllable_idx - 1] + 1
#         vowel_letter = stem[vowel_idx]
#     return vowel_letter




