import numpy as np
import pandas as pd

from data_classes import F, Fdss, Ldss
from special_data import POTENTIALLY_FEMININE_WORDS


class FinalAlephConverter:
    """
    If the stem ends on aleph (III-aleph roots), this letter is converted to a consonant, to harmonize these cases.
    """
    def __init__(self, data):
        self.data = data
        self.convert_final_aleph()

    def convert_final_aleph(self):
        self.data.pattern = np.where(self.data.stem.str[-1] == '>', self.data.pattern.str[:-1] + 'C', self.data.pattern)


class FeminineTStripper:
    """Move final T in feminine words to nme on basis of set of lexemes from BHSA.
    """

    def __init__(self, data):
        self.data = data

        self.fem_t_words = self.find_feminine_t_words()
        self.fem_t_words = set.union(self.fem_t_words, POTENTIALLY_FEMININE_WORDS)
        self.t_word_list = self.check_t_words()

        self.adapt_pattern_column()
        self.adapt_stem_column()
        self.adapt_nme_column()

    @staticmethod
    def find_feminine_t_words():
        """Find all lexemes in BHSA that are feminine and have nominal ending T in lexeme.
        We can use this to remove nominal ending T in DSS words.
        Output:
            lex_set: set. Set containing lexemes.
        """
        lex_set = set()
        for w in F.otype.s('word'):
            lexendswitht = F.lex.v(w).strip('/').strip('=')[-1] == 'T'
            isfeminine = F.gn.v(w) == 'f'
            issubstantive = F.sp.v(w) == 'subs'
            issingular = F.nu.v(w) == 'sg'
            contains_t_nme = 'T' in F.g_nme.v(w)
            if all([lexendswitht, isfeminine, issubstantive, issingular, contains_t_nme]):
                lex_set.add(F.lex.v(w))
            lex_set = {lex for lex in lex_set if not lex.rstrip('/').rstrip('=').endswith('WT')}
        return lex_set

    def check_t_words(self):
        return [lex in self.fem_t_words and stem[-1] == 'T' for lex, stem in zip(self.data.lex, self.data.stem)]

    def adapt_pattern_column(self):
        self.data['pattern'] = np.where(self.t_word_list, self.data.pattern.str[:-1], self.data.pattern)

    def adapt_stem_column(self):
        self.data['stem'] = np.where(self.t_word_list, self.data.stem.str[:-1], self.data.stem)

    # TODO implement like functions above. Therefore nme column may not contain float values (nan).
    def adapt_nme_column(self):
        nme = []
        for t_word, nme_val in zip(self.t_word_list, self.data.nme):
            if not isinstance(nme_val, str):
                nme_val = ''
            if t_word:
                nme.append('T' + nme_val)
            else:
                nme.append(nme_val)
        self.data['nme'] = nme


class OtherVowelEndingsColumnAdder:
    """"""
    def __init__(self, data):
        self.data = data
        self.vowel_count = None
        self.count_matres_at_end_of_pattern()
        self.add_column_other_vowel_endings()
        self.remove_other_vowel_ending_from_stem()
        self.shorten_pattern()

    def count_matres_at_end_of_pattern(self):
        self.data['vowel_count'] = self.data.pattern.str.split('C').str[-1].str.count('M')

    def add_column_other_vowel_endings(self):
        other_vowel_ending = []
        for _, row in self.data.iterrows():
            vowel_count = row['vowel_count']
            stem = row['stem']
            if not vowel_count:
                other_vowel_ending.append('')
                continue
            try:
                other_vowel_ending.append(stem[-int(vowel_count):])
            except:
                other_vowel_ending.append('')
        self.data['other_vowel_ending'] = other_vowel_ending
        self.data = self.data.drop(columns=['vowel_count'])

    def remove_other_vowel_ending_from_stem(self):
        self.data['stem'] = [str(stem).rstrip(ending) for stem, ending in
                             zip(self.data.stem, self.data.other_vowel_ending)]

    def shorten_pattern(self):
        self.data.pattern = [pattern[:len(stem)] if isinstance(pattern, str) else '' for pattern,
                             stem in zip(self.data.pattern, self.data.stem)]


class FinalYodRemover:
    """
    Removes final yod from stems and adds it to column other_vowel_ending, even if this yod has consonantal value.
    """
    def __init__(self, data):
        self.data = data
        self.cons_j_lexemes = {'GWJ/', 'DWJ/', 'QWJ/', 'XJJM/'}
        self.j_lexemes_list = self.check_final_j_lexemes_and_stems()
        self.j_aleph_lexemes_list = self.check_final_j_aleph_lexemes_and_stems()

        self.add_j_to_other_vowel_endings()
        self.remove_j_from_stem()
        self.remove_final_sign_from_pattern()

        self.add_j_aleph_to_other_vowel_endings()
        self.remove_j_aleph_from_stem()
        self.remove_final_j_aleph_from_pattern()

    def check_final_j_lexemes_and_stems(self):
        return [((lex[-1] == 'J' or lex in {'CLJCJT', 'XMJCJT'}) and stem[-1] == 'J' and lex_whole not in self.cons_j_lexemes) for lex, stem, lex_whole
                in zip(self.data.lex.str.strip('/').str.strip('='),
                self.data.stem, self.data.lex)]

    def add_j_to_other_vowel_endings(self):
        self.data.other_vowel_ending = np.where(self.j_lexemes_list, 'J' + self.data.other_vowel_ending.astype(str),
                                                self.data.other_vowel_ending)

    def remove_j_from_stem(self):
        self.data.stem = np.where(self.j_lexemes_list, self.data.stem.str[:-1],
                                  self.data.stem)

    def remove_final_sign_from_pattern(self):
        self.data.pattern = np.where(self.j_lexemes_list, self.data.pattern.str[:-1],
                                     self.data.pattern)

    def check_final_j_aleph_lexemes_and_stems(self):
        return [(lex[-1] == 'J' and stem[-2:] == 'J>') for lex, stem in zip(self.data.lex.str.strip('/').str.strip('='),
                                                                            self.data.stem)]

    def add_j_aleph_to_other_vowel_endings(self):
        self.data.other_vowel_ending = np.where(self.j_aleph_lexemes_list, 'J>' + self.data.other_vowel_ending.astype(str),
                                                self.data.other_vowel_ending)

    def remove_j_aleph_from_stem(self):
        self.data.stem = np.where(self.j_aleph_lexemes_list, self.data.stem.str[:-2],
                                  self.data.stem)

    def remove_final_j_aleph_from_pattern(self):
        self.data.pattern = np.where(self.j_aleph_lexemes_list, self.data.pattern.str[:-2],
                                     self.data.pattern)


class MTDSSHelpColumnsAdder:
    """"""
    def __init__(self, mt_dss_data):
        self.mt_dss_data = mt_dss_data
        self.add_line_and_column_in_manuscript()
        self.add_extra_columns()

    def add_line_and_column_in_manuscript(self):
        """
        Add columns line and column to dataframe.
        Note, these are not necessarily integers. It can also be an identifier of a fragment.
        """
        line_ids = [Ldss.u(w, 'line')[0] if scroll not in {'MT', 'SP'} else -1 for w, scroll in zip(self.mt_dss_data['tf_id'], self.mt_dss_data['scroll'])]
        self.mt_dss_data['line'] = [Fdss.line.v(line_id) if line_id != -1 else '-' for line_id in line_ids]
        self.mt_dss_data['column'] = [Fdss.fragment.v(line_id) if line_id != -1 else '-' for line_id in line_ids]

    def add_extra_columns(self):
        """
        Make column scr_book.
        Make number of binary columns (Values 0 (absent) and 1 (present):
        - has_vowel_letter
        - has_prs
        - has_prefix
        - has_hloc
        - has_nme
        """
        self.mt_dss_data['has_prs'] = (self.mt_dss_data['prs'].str.len() > 0).astype(int)
        self.mt_dss_data['has_prefix'] = (self.mt_dss_data['prefix'].str.len() > 0).astype(int)
        self.mt_dss_data['has_hloc'] = (self.mt_dss_data['hloc'].str.len() > 0).astype(int)
        self.mt_dss_data['has_nme'] = (self.mt_dss_data['nme'].str.len() > 0).astype(int)


class RecCorColumnsAdder:
    """"""
    def __init__(self, data):
        self.data = data
        self.add_column_reconstructed_stem()
        self.add_column_corrected_stem()

    def add_column_reconstructed_stem(self):
        recs = [rec_signs if isinstance(rec_signs, str) else '' for rec_signs in self.data.rec_signs]
        stems = [stem if isinstance(stem, str) else '' for stem in self.data.stem]

        self.data['rec_signs_stem'] = [rec[:len(stem)] for rec, stem in zip(recs, stems)]

    def add_column_corrected_stem(self):
        cors = [cor_signs if isinstance(cor_signs, str) else '' for cor_signs in self.data.cor_signs]
        stems = [stem if isinstance(stem, str) else '' for stem in self.data.stem]

        self.data['cor_signs_stem'] = [cor[:len(stem)] for cor, stem in zip(cors, stems)]


class MatresColumnAdder:
    """
    Add columns type and vowel_letter to df.
    type: str syllable type (values: first, last, single)
    vowel_letter: str (what is the vowel letter (W, J, > or a combination))

    """
    def __init__(self, data):
        self.data = data
        self.new_rows = {}

        self.add_type_and_vowel_letter_to_rows()
        self.df_with_vowel_letters = self.merge_rows_in_df()
        self.add_column_has_vowel_letter()

    def add_type_and_vowel_letter_to_rows(self):

        for _, row in self.data.iterrows():
            pattern = row['pattern']
            if isinstance(pattern, float):
                pattern = ''

            if pattern.count('C') == 1:
                continue

            if pattern.startswith('M'):
                pattern = 'C' + pattern.lstrip('M')
            c_count = pattern.count('C')

            idcs = self.get_vowel_indices_first_and_last_syllables(pattern, c_count)

            if isinstance(idcs, list):
                vowel = ''.join([row['stem'][idx] for idx in idcs])
                reconstructed_sign_count = sum([row.rec_signs[idx].count('r') for idx in idcs])
                if not reconstructed_sign_count:
                    new_row_single = self.get_type_and_vowel(row, 'single', vowel)
                    self.new_rows[('single', new_row_single['tf_id'])] = new_row_single
                else:
                    continue

            else:
                first_syl_idcs, last_syl_idcs = idcs

                last_syl_vowel = ''.join([row['stem'][idx] for idx in last_syl_idcs])
                new_row = self.get_type_and_vowel(row, 'last', last_syl_vowel)
                self.new_rows[('last', new_row['tf_id'])] = new_row

                first_syl_vowel = ''.join([row['stem'][idx] for idx in first_syl_idcs])
                new_row = self.get_type_and_vowel(row, 'first', first_syl_vowel)
                self.new_rows[('first', new_row['tf_id'])] = new_row

    @staticmethod
    def get_type_and_vowel(row, typ, vowel):
        new_row_single = row.copy()
        new_row_single['type'] = typ
        new_row_single['vowel_letter'] = vowel
        return new_row_single

    @staticmethod
    def get_vowel_indices_first_and_last_syllables(pattern, c_count):

        if not pattern:
            return [], []
        pat = pattern.strip('M')

        if c_count > 2:
            vowel_chunks = pat.split('C')
            idx_vowels_first_syll = [idx + 1 for idx in list(range(0, len(vowel_chunks[1])))]
            idx_vowels_last_syll = [idx + 1 for idx in list(range(len(pat) - 2 - len(vowel_chunks[-2]), len(pat) - 2))]
            return idx_vowels_first_syll, idx_vowels_last_syll

        vowel_chunks = pat.split('C')
        idx_vowels_syll = [idx + 1 for idx in list(range(0, len(vowel_chunks[1])))]
        return idx_vowels_syll

    def merge_rows_in_df(self):
        new_df = pd.DataFrame(self.new_rows).T
        new_df = new_df.sort_values(by=['tf_id'])
        return new_df

    def add_column_has_vowel_letter(self):
        self.df_with_vowel_letters['has_vowel_letter'] = (
                    self.df_with_vowel_letters['vowel_letter'].str.len() > 0).astype(int)
