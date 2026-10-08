"""
Parses the vowel letters (matres lectionis) in the vocalized text of the MT.
"""


class VocalizedGraphicalUnits:
    """
    Produces a list of vocalized graphical units of the MT in ETCBC transliteration (self.vocalized_text),
    and a corresponding list of word ids (self.word_ids).
    Input:
    F, L: text-fabric api of the BHSA.
    verse_node: text-fabric verse node of the BHSA.
    """

    def __init__(self, F, L, verse_node):
        self.F = F
        self.L = L
        self.verse_node = verse_node
        self.vocalized_text = self.make_vocalized_verse()
        self.word_ids = self.make_word_ids_list_for_graphical_units()

    def make_word_ids_list_for_graphical_units(self):
        word_nodes = ''.join(
            [f'{w} ' if self.F.g_word.v(w)[-1] != '-' else f'{w}-' for w in self.L.d(self.verse_node, 'word')]).split()
        return word_nodes

    def make_vocalized_verse(self):
        vocalized_verse = ''.join(
            [f'{self.F.g_word.v(w)} ' if self.F.g_word.v(w)[-1] != '-' else self.F.g_word.v(w)
             for w in self.L.d(self.verse_node, 'word')])
        vocalized_verse = ''.join([char for char in vocalized_verse if not char.isdigit()]).replace(',', '').split()
        return vocalized_verse


class MatresParserBHSA:
    """
    Converts a vocalized word into a string sequence,
    showing consonants (C), pointing (P), and matres (M).
    E.g. word_text = R;>CIJT (רֵאשִׁ֖ית, in ETCBC transctiption)
    type_string = CPMCPMC

    Input:
    word_text: vocalized hebrew word in transcription.
    """

    def __init__(self, word_text):

        self.consonants = {'<', '>', 'B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P',
                           'Q', 'R', 'S', 'T', 'V', 'W', 'X', 'Y', 'Z', '#', '_', '&'}
        self.potential_matres = {'>', 'J', 'W', 'H'}
        self.pointing = {':', '.', ';', '@', 'E', 'O', 'A', 'I', 'U'}
        self.vowel_signs = {';', '@', 'E', 'O', 'A', 'I', 'U'}
        self.matres_vowels = {'W.'}

        self.word_text = word_text
        self.all_cons_groups = self._split_word()
        self.type_string = ''

        self.parse_matres()

    def _split_word(self):
        all_cons_groups = []
        cons_group = ''
        for char in self.word_text:
            if char in self.consonants:
                if cons_group:
                    all_cons_groups.append(cons_group)
                cons_group = char
            else:
                cons_group += char
        all_cons_groups.append(cons_group)
        return all_cons_groups

    def parse_matres(self):

        char_groups = [w.replace('-', '').replace(',', '').replace('&', '_') for w in self.all_cons_groups]
        for idx, char_group in enumerate(char_groups):
            if len(char_group) > 1:
                self._parse_cons_with_pointing(idx, char_group, char_groups)
            else:
                self._parse_bare_cons(idx, char_group, char_groups)

    def _parse_cons_with_pointing(self, idx, char_group, char_groups):
        for char in char_group:
            if char in self.pointing:
                self.type_string += 'P'
            elif char in self.consonants:
                if 'W.' in char_group:
                    if idx == 0:
                        self.type_string += 'C'
                    elif char_groups[idx - 1][-1] not in self.vowel_signs:
                        self.type_string += 'M'
                    else:
                        self.type_string += 'C'
                else:
                    self.type_string += 'C'
            else:
                self.type_string += char

    def _parse_bare_cons(self, idx, char_group, char_groups):
        if char_group == '_':
            self.type_string += '_'
        elif char_group not in self.potential_matres:
            self.type_string += 'C'
        else:
            self.type_string += self._define_type_of_single_char(char_group, idx, char_groups)

    def _define_type_of_single_char(self, char, idx, char_groups):

        if idx + 1 <= len(char_groups) - 1:
            cons_condition = {'>': char_groups[idx + 1] in self.matres_vowels}

            if char in cons_condition:
                if cons_condition[char]:
                    return 'C'

        mother_condition = {'>': char_groups[idx - 1][-1] in self.pointing or (
                    idx == len(char_groups) - 1 and (self.word_text.endswith('W>') or self.word_text.endswith('J>'))),
                            'J': char_groups[idx - 1][-1] in {';', 'I', 'E'} or char_groups[idx - 1] == '>',
                            'W': char_groups[idx - 1][-1] in {'O', 'U'} or char_groups[idx - 1][-1] == '>',
                            'H': idx == len(char_groups) - 1
                            }

        if mother_condition[char]:
            return 'M'
        return 'C'


def get_matres_patterns_and_prefixes(F, L):
    """
    Returns a dictionary with for every word node of the MT a tuple (pattern, prefix):
    pattern: the vowel letter pattern of the word, e.g. CCMCMC, without pointing.
    prefix: the g_cons of the words written together with the word in front of it, e.g. the article.
            Only the last word of a graphical unit gets a prefix.
    Ketiv/qere cases are not included.
    """
    patterns_and_prefixes = {}
    for verse in F.otype.s('verse'):
        voc_verse = VocalizedGraphicalUnits(F, L, verse)
        for w, w_ids in zip(voc_verse.vocalized_text, voc_verse.word_ids):
            if '*' in w:  # do not include ketiv/qere cases
                continue

            tf_indices = [int(idx) for idx in w_ids.split('-')]
            parsed_matres = add_dashes(w, MatresParserBHSA(w).type_string)
            for tf_id, word_matres in zip(tf_indices, parsed_matres.split('-')):
                if len(tf_indices) > 1 and tf_id == tf_indices[-1]:
                    prefix = ''.join([F.g_cons.v(w) for w in tf_indices[:-1]])
                else:
                    prefix = ''
                patterns_and_prefixes[tf_id] = (word_matres.replace('P', ''), prefix)
    return patterns_and_prefixes


def add_dashes(text, structure):
    """add dashes in the structure (str) at the indices where they occur in the text (str)"""
    for idx, char in enumerate(text):
        if char == '-':
            structure = f'{structure[:idx]}-{structure[idx:]}'
    return structure
