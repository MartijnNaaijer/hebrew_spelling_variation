import numpy as np
import pandas as pd
from scipy.stats import entropy


class UselessRowsRemover:
    """
    Cleans the dataset in four steps:
    1. Remove words without matres pattern (generally ketiv/qere cases, that are excluded).
    2. Remove a number of ad-hoc cases, called useless_nodes here. You can find these nodes in special_data.py
       in the dict AD_HOC_REMOVALS.
    3. A number of plurals do not display spelling variation. The relevant lexemes can be found in special_data.py in
       the list USELESS_PLURALS.
    4. A number of lexemes is removed, because the letter J in its stem can be both a vowel letter or consonant, e.g.
       BJT/ and >JN/. See the list REMOVE_LEXEMES in special_data.py. These words can have variation in the
       matres pattern with identical spelling.

    """
    def __init__(self, data, useless_plurals, useless_lexemes, useless_nodes):
        self.data = data
        self.useless_plurals = useless_plurals
        self.useless_lexemes = useless_lexemes
        self.useless_nodes = useless_nodes

        self.remove_rows_without_pattern()
        self.remove_ad_hoc_removals()

        self.remove_plurals_without_mater()
        self.remove_useless_lexemes()

    def remove_rows_without_pattern(self):
        self.data = self.data[[pat.count('C') > 0 for pat in self.data.pattern]]

    def remove_ad_hoc_removals(self):
        useless_nodes = list(self.useless_nodes.keys())
        self.data = self.data[~self.data.tf_id.isin(useless_nodes)]

    def remove_plurals_without_mater(self):
        plural_no_maters = np.array([lex in self.useless_plurals and nu in {'du', 'pl'}
                                     for lex, nu in zip(self.data.lex, self.data.nu)])
        self.data = self.data[np.invert(plural_no_maters)]

    def remove_useless_lexemes(self):
        self.data = self.data[~self.data.lex.isin(self.useless_lexemes)]


class SyllablesWithoutVariationRemover:
    """
    Remove Syllables in lexemes which have very low variation, based on an entropy threshold..
    E.g., in MLK/, "king", there is nowhere any variation in the spelling of the first syllable.
    In the second syllable, there is a case of a vowel letter > (ML>KJM in MT, 2Sam 11:1). This is such a rare
    phenomenon, and also a difficult reading, that the second syllable of MLK/ is also excluded from the analysis.

    """
    def __init__(self, data, entropy_threshold):
        self.data = data
        self.entropy_threshold = entropy_threshold

        self.lex_type_dict = {}
        self.find_syllables_with_variation()
        self.data_variable_syllables = self.make_new_df()

    @staticmethod
    def get_patterns_of_syllable(pattern, vowel_letters, syllable_type):
        if not isinstance(pattern, str):
            return None
        vowel_length = len(vowel_letters) if isinstance(vowel_letters, str) else 0
        if syllable_type == 'single':
            pattern = 'C' + pattern[1:]
            return pattern
        elif syllable_type == 'first':
            syllable_pattern = pattern[:2 + vowel_length]
            return 'C' + syllable_pattern[1:]
        elif syllable_type == 'last':
            syllable_pattern = pattern[-(2 + vowel_length):]
            return syllable_pattern
        else:
            raise ValueError('No valid value for syllable type:', syllable_type)

    def find_syllables_with_variation(self):
        lexemes = set(self.data.lex)

        for lex in lexemes:
            dat_lex = self.data[self.data.lex == lex]
            syll_types = set(dat_lex.type)
            for typ in syll_types:
                dat_lex_type = dat_lex[dat_lex.type == typ]
                patterns = [self.get_patterns_of_syllable(pattern, vowel_letters, syllable_type)
                            for pattern, vowel_letters, syllable_type in
                            zip(dat_lex_type.pattern, dat_lex_type.vowel_letter, dat_lex_type.type)]
                pattern_counts = pd.Series(patterns).value_counts()
                max_count = max(pattern_counts)
                total_count = sum(pattern_counts)
                max_fraction = max_count / total_count
                rest_fraction = (total_count - max_count) / total_count
                syll_entropy = entropy([max_fraction, rest_fraction], base=2)

                # second requirement guarantees that variation is not only in pattern, but also in written text.
                if syll_entropy > self.entropy_threshold and len(set(dat_lex_type.stem)) > 1:
                    self.lex_type_dict[(lex, typ)] = dat_lex_type

    def make_new_df(self):
        dat_merge = pd.concat(self.lex_type_dict)
        return dat_merge.sort_values(by='tf_id').drop(columns=['vowel_count'])
