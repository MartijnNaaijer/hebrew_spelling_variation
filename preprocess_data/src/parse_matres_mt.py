import pandas as pd

from data_classes import F, L, T, Fdss, Ldss, Tdss


class VocalizedGraphicalUnits:
    """
    Produces a list of vocalized graphical units of the MT in ETCBC transliteration (self.vocalized_text),
    and a corresponding list of word ids (self.word_ids).
    Input:
    verse_node: text-fabric verse node of the BHSA.
    """

    def __init__(self, verse_node):
        self.verse_node = verse_node
        self.vocalized_text = self.make_vocalized_verse()
        self.word_ids = self.make_word_ids_list_for_graphical_units()

    def make_word_ids_list_for_graphical_units(self):
        word_nodes = ''.join(
            [f'{w} ' if F.g_word.v(w)[-1] != '-' else f'{w}-' for w in L.d(self.verse_node, 'word')]).split()
        return word_nodes

    def make_vocalized_verse(self):
        vocalized_verse = ''.join(
            [f'{F.g_word.v(w)} ' if F.g_word.v(w)[-1] != '-' else F.g_word.v(w) for w in L.d(self.verse_node, 'word')])
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
                           'Q', 'R', 'S', 'T', 'V', 'W', 'X', 'Y', 'Z', '#'}
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

        char_groups = [w.replace('-', '').replace(',', '').replace('&', '') for w in self.all_cons_groups]
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
        if char_group not in self.potential_matres:
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
                            'J': char_groups[idx - 1][-1] in {';', 'I', 'E'},
                            'W': char_groups[idx - 1][-1] in {'O', 'U'} or char_groups[idx - 1][-1] == '>',
                            'H': idx == len(char_groups) - 1
                            }

        if mother_condition[char]:
            return 'M'
        return 'C'


class MTMatresProcessor:

    def __init__(self, corpus):
        self.corpus = corpus
        self.matres_pattern_dict = {}
        self.bhsa_export_dict = {}
        self.mt_matres_df = None
        self.get_matres_patterns_in_mt()
        self.add_matres_and_prefix_to_words()
        self.export_mt_data()
        self.save_mt_dataset()

    def get_matres_patterns_in_mt(self):

        for verse in F.otype.s('verse'):
            voc_verse = VocalizedGraphicalUnits(verse)
            for w, w_ids in zip(voc_verse.vocalized_text, voc_verse.word_ids):

                if '*' in w:  # do not include ketiv qere cases
                    continue

                parsed_matres = self.parse_matres(w)
                for tf_id, word_text, word_matres in zip(w_ids.split('-'), w.split('-'), parsed_matres.split('-')):

                    tf_id = int(tf_id)
                    tf_indices = [int(idx) for idx in w_ids.split('-')]
                    if len(tf_indices) > 1 and tf_id == tf_indices[-1]:
                        prefix_g_cons = ''.join([F.g_cons.v(w) for w in tf_indices[:-1]])
                    else:
                        prefix_g_cons = ''

                    word_matres_no_pointing = word_matres.replace('P', '')
                    self.matres_pattern_dict[tf_id] = (word_matres, word_matres_no_pointing, prefix_g_cons)

    @staticmethod
    def add_dashes(text, structure):
        """add dashes in the structure (str) at the indices where they occur in the text (str)"""
        for idx, char in enumerate(text):
            if char == '-':
                structure = f'{structure[:idx]}-{structure[idx:]}'
        return structure

    def parse_matres(self, word_text):
        matres_parser = MatresParserBHSA(word_text)
        parsed_matres = matres_parser.type_string
        parsed_word = matres_parser.all_cons_groups
        parsed_matres = self.add_dashes(word_text, parsed_matres)
        return parsed_matres

    def add_matres_and_prefix_to_words(self):
        for verse in self.corpus.scrolls['MT'].verses:
            verse_obj = self.corpus.scrolls['MT'].verses[verse]
            for word_obj in verse_obj.words:
                matres_pat_with_pointing, matres_pat_no_pointing, prefixed_g_cons = self.matres_pattern_dict.get(
                    word_obj.tf_word_id, ('', '', ''))
                word_obj.matres_pattern = matres_pat_no_pointing
                word_obj.prefix_g_cons = prefixed_g_cons

    def export_mt_data(self):
        for verse in self.corpus.scrolls['MT'].verses:
            bo, ch, ve = verse
            verse_obj = self.corpus.scrolls['MT'].verses[verse]
            for word in verse_obj.words:
                if word.lang != 'Hebrew':
                    continue
                g_cons = word.g_cons
                stem = word.stem
                # TODO: lines below in distinct function.
                # Below are plural as lexeme, occurring only as plural.
                no_ut_lexemes = {'TWY>WT/', 'NVJCWT/', 'TWLDWT/', 'BXWRWT/', '<LLWT/', 'XMDWT/'}
                if word.gender == 'f' and word.lex.rstrip('/').rstrip('=').endswith('WT') and word.sp == 'subs' and not stem.endswith('T') and word.lex not in no_ut_lexemes:
                    nme = word.nme_cons.strip('T')
                    stem += 'T'
                else:
                    nme = word.nme_cons

                matres_pattern_stem = self.get_stem_matres_pattern(g_cons, stem, word.matres_pattern)
                export_bhsa_list = [word.tf_word_id, 'MT', bo, ch, ve, word.lex, g_cons, stem,
                                    matres_pattern_stem, word.matres_pattern, word.vs, word.vt,
                                    word.number, word.gender, word.person, word.sp, word.prs_cons, nme, word.hloc,
                                    word.prefix_g_cons, '0' * len(word.g_cons), '0' * len(word.g_cons),]

                self.bhsa_export_dict[word.tf_word_id] = export_bhsa_list

    @staticmethod
    def get_stem_matres_pattern(g_cons, stem, matres_pattern):
        stem_start_idx = g_cons.find(stem)
        matres_pattern_stem = matres_pattern[stem_start_idx:stem_start_idx+len(stem)]
        return matres_pattern_stem

    def save_mt_dataset(self):
        mt_matres_df = pd.DataFrame(self.bhsa_export_dict).T
        mt_matres_df.columns = ['tf_id', 'scroll',
                                'book', 'chapter',
                                'verse', 'lex',
                                'g_cons', 'stem',
                                'pattern', 'pattern_g_cons',
                                'vs', 'vt',
                                'nu', 'gn', 'ps',
                                'sp', 'prs',
                                'nme', 'hloc',
                                'prefix_g_cons', 'rec_signs', 'cor_signs']
        self.mt_matres_df = mt_matres_df
        mt_matres_df.to_csv('../data/matres_mt.csv', sep='\t', index=False)
