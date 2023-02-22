class InvalidDataRemover:
    """
    From the dataset, two types of data are removed:
    1. Words with a stem consisting of one letter,
       e.g. lexemes like PH/, "mouth", and FH/, "sheep".
    2. Syllables with reconstructed letters in it are removed.
       This involves the vowel letter and the consonant before and after it.
       If one of these letters is reconstructed, the syllable is not taken into consideration.

    """
    def __init__(self, data):
        self.data = data

        self.remove_short_stems(1)
        self.syllable_recs = self.find_reconstructed_syllables()
        self.data_complete_syllables = self.select_non_reconstructed_syllables()

    def remove_short_stems(self, stem_length):
        """Remove verbs with a short stem.
        Input:
          stem_length: int
          Length of the stem.
        """
        self.data = self.data[self.data['stem'].str.len().gt(stem_length)]

    def find_reconstructed_syllables(self):
        """Finds out if a syllable contains reconstructed signs.
        Output:
            rec_syllables: list Contains value for every row in dataset, with value 1 (reconstructed letters in syllable)
                                or 0 (no reconstructed letters in syllable).
        """

        rec_syllables = []
        for rec_signs, vowels, syll_type, stem in zip(self.data.rec_signs_stem, self.data.vowel_letter,
                                                      self.data.type, self.data.stem):
            if isinstance(vowels, float):
                vowels = ''

            start_idx, end_idx = self.get_indices_of_syllable_in_stem(stem, vowels, syll_type)
            syll_rec_signs = rec_signs[start_idx: end_idx]
            rec_syllables.append(self.contains_reconstructed_sign(syll_rec_signs))
        return rec_syllables

    @staticmethod
    def get_syllable_length(vowels):
        return 2 + len(vowels)

    def get_indices_of_syllable_in_stem(self, stem, vowels, syll_type):
        stem_indices = {'single': (0, len(stem)),
                        'first': (0, self.get_syllable_length(vowels)),
                        'last': (-self.get_syllable_length(vowels), len(stem))}
        return stem_indices[syll_type]

    @staticmethod
    def contains_reconstructed_sign(reconstructed_signs):
        if reconstructed_signs.count('r') > 0:
            return 1
        return 0

    def select_non_reconstructed_syllables(self):
        self.data['syllable_recs'] = self.syllable_recs
        self.data = self.data[self.data['syllable_recs'] == 0]
        self.data.drop(columns=['syllable_recs'])
        return self.data
