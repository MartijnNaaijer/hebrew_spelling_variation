class VowelLetterInSubsequentSyllableAdder:
    def __init__(self, data):
        self.data = data
        self.neighboring_vowel_letter_list = []
        self.make_list_with_neighboring_vowel_letter()
        self.data['neigh_vowel_letter'] = self.neighboring_vowel_letter_list

    def make_list_with_neighboring_vowel_letter(self):
        for stem_pattern, word_pattern, syll_type, vowel_letter, stem, g_cons in zip(self.data.pattern,
                                                                                     self.data.pattern_g_cons, self.data.type,
                                                                                     self.data.vowel_letter, self.data.stem,
                                                                                     self.data.g_cons):
            suffix_pattern = word_pattern[len(stem_pattern):]
            suffix = g_cons[len(stem):]
            if syll_type == 'single':
                vowel_letter_in_suffix_present = self.check_if_suffix_starts_with_vowel_letter(suffix_pattern, suffix, vowel_letter)
                self.neighboring_vowel_letter_list.append(vowel_letter_in_suffix_present)
            elif syll_type == 'last':
                vowel_letter_in_suffix_present = self.check_if_suffix_starts_with_vowel_letter(suffix_pattern, suffix, vowel_letter)
                vowel_letter_in_first_syllable_present = self.check_if_first_syllable_has_vowel_letter(stem_pattern, stem, vowel_letter)
                if vowel_letter_in_suffix_present or vowel_letter_in_first_syllable_present:
                    self.neighboring_vowel_letter_list.append(1)
                else:
                    self.neighboring_vowel_letter_list.append(0)
            elif syll_type == 'first':
                vowel_letter_in_suffix_present = self.check_if_suffix_starts_with_vowel_letter(suffix_pattern, suffix, vowel_letter)
                vowel_letter_in_last_syllable_present = self.check_if_last_syllable_has_vowel_letter(stem_pattern, stem, vowel_letter)
                if vowel_letter_in_suffix_present or vowel_letter_in_last_syllable_present:
                    self.neighboring_vowel_letter_list.append(1)
                else:
                    self.neighboring_vowel_letter_list.append(0)

    @staticmethod
    def check_if_suffix_starts_with_vowel_letter(suffix_pattern, suffix, vowel_letter):
        if not suffix_pattern:
            return 0
        else:
            if suffix_pattern[0] == 'M' and suffix[0] == vowel_letter:
                return 1
            else:
                return 0

    @staticmethod
    def check_if_first_syllable_has_vowel_letter(stem_pattern, stem, vowel_letter):
        if stem_pattern[1] == 'M' and stem[1] == vowel_letter:
            return 1
        else:
            return 0

    @staticmethod
    def check_if_last_syllable_has_vowel_letter(stem_pattern, stem, vowel_letter):
        if stem_pattern[-2] == 'M' and stem[-2] == vowel_letter:
            return 1
        else:
            return 0
