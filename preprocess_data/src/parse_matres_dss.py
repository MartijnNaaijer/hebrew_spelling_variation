import collections

from Bio import pairwise2
from Bio.Seq import Seq
import pandas as pd

from config import data_path
from data_classes import F, L, T, Fdss, Ldss, Tdss, Scroll
from special_data import j_lexemes, df_columns, fem_end_words


def parse_nme_dss(stem, lex, state, nu, gn, sp, suff):
    """
    :param stem: initial stem (needs further parsing)
    :param lex: lexeme
    :param state: state a or c
    :param nu: number
    :param gn: gender
    :param sp: part of speech
    :param suff: pronominal suffix
    :return: stem and nme
    """
    nme = ''
    lex_no_special_signs = lex.strip('/').strip('=')

    if lex in j_lexemes:
        if suff and stem.endswith('JJ') and nu == 'pl':
            stem = stem.removesuffix('J')
            nme += 'J'
    else:
        if suff and stem.endswith('J') and nu == 'pl':
            stem = stem.removesuffix('J')
            nme += 'J'

    if sp == 'adjv' and len(lex) > 1 and stem.endswith('H') and lex_no_special_signs[-1] != 'H':
        stem = stem.removesuffix('H')
        nme += 'H'
    elif sp == 'adjv' and len(lex) > 1 and stem.endswith('T') and lex_no_special_signs[-1] != 'T' and nu == 'sg':
        stem = stem.removesuffix('T')
        nme += 'T'
    elif sp == 'adjv' and len(lex) > 1 and stem.endswith('TJ') and lex_no_special_signs[-2:] != 'TJ' and nu == 'sg':
        stem = stem.removesuffix('TJ')
        nme += 'TJ'
    elif sp == 'adjv' and lex_no_special_signs[-1] == 'J' and len(lex) > 1 and stem.endswith('JM'):
        stem = stem.removesuffix('JM')
        nme += 'JM'
    elif sp == 'adjv' and lex_no_special_signs[-1] == 'J' and len(lex) > 1 and stem.endswith('JN'):
        stem = stem.removesuffix('JN')
        nme += 'JN'
    elif sp == 'adjv' and lex_no_special_signs[-1] == 'J' and len(lex) > 1 and stem.endswith('WT'):
        stem = stem.removesuffix('WT')
        nme += 'WT'
    elif sp == 'adjv' and lex_no_special_signs[-1] == 'J' and len(lex) > 1 and stem.endswith('T'):
        stem = stem.removesuffix('T')
        nme += 'T'
    elif sp == 'adjv' and lex_no_special_signs[-1] == 'J' and len(lex) > 1 and stem.endswith('J'):
        stem = stem.removesuffix('J')
        nme = 'J' + nme

    if (stem.endswith('J') and state == 'c' and nu in {'du', 'pl'} and lex not in j_lexemes) or \
            (stem.endswith('J') and sp == 'prep'):
        stem = stem.removesuffix('J')
        nme += 'J'
    elif stem.endswith('W') and sp == 'prep':
        stem = stem.removesuffix('W')
        nme += 'W'
    elif lex in j_lexemes and stem.endswith('JJM') and len(stem) > 3:
        stem = stem.removesuffix('JM')
        nme = 'JM' + nme
    elif lex in j_lexemes and stem.endswith('JM') and len(stem) > 2:
        stem = stem.removesuffix('M')
        nme = 'M' + nme
    elif lex not in j_lexemes and stem.endswith('JM') and nu in {'du', 'pl'} and len(stem) > 2:
        stem = stem.removesuffix('JM')
        nme = 'JM' + nme
    elif lex not in j_lexemes and stem.endswith('M') and nu in {'du', 'pl'} and len(stem) > 2 and (lex_no_special_signs[-1] != 'M' or lex == '>LHJM/'):
        stem = stem.removesuffix('M')
        nme = 'M' + nme

    if stem.endswith('WT') and nu == 'pl':
        stem = stem.removesuffix('WT')
        nme = 'WT' + nme
    if stem.endswith('WTJ') and nu == 'pl':
        stem = stem.removesuffix('WTJ')
        nme = 'WTJ' + nme
    elif stem.endswith('T') and nu == 'pl' and gn == 'f':
        stem = stem.removesuffix('T')
        nme = 'T' + nme

    if lex_no_special_signs[-1] == 'H' and nu == 'sg':
        if stem.endswith('TJ'):
            stem = stem.removesuffix('TJ')
            nme = 'TJ' + nme
        elif stem[-1] == 'T':
            stem = stem.removesuffix('T')
            nme = 'T' + nme
        elif stem[-1] == 'H' and lex != '>LWH/':
            stem = stem.removesuffix('H')
            nme = 'H' + nme

    # Ugly ad hoc solution for Jer 17:18 in 4Q70. Better solution?
    if lex == 'CBRWN/' and stem == 'CBRWNM':
        stem = 'CBRWN'
        nme = 'M'

    # Aramaic plural
    if stem.endswith('JN') and gn == 'm' and nu == 'pl' and not nme:
        stem = stem[:-2]
        nme = 'JN'

    # Ugly hardcoded solution for H/> exchange
    if lex in {'DBWRH/', 'GBWRH/', 'PLJVH/', 'MNWSH/', 'MBWSH/', 'PH/', 'DWD=/'} and stem.endswith('>'):
        stem = stem[:-1]
        nme = '>' + nme

    if lex in fem_end_words:
        if nu == 'pl' and stem.endswith('T'):
            stem = stem[:-1]
            nme = 'T' + nme
        elif nu == 'pl' and stem.endswith('WT'):
            stem = stem[:-2]
            nme = 'WT' + nme

    if lex == 'CWCN/' and stem.endswith('H'):
        stem = stem.rstrip('H')
        nme += 'H'

    if lex == 'CLC/' and stem.endswith('H'):
        stem = stem.rstrip('H')
        nme = 'H' + nme

    if lex == 'GDL/' and stem.endswith('H'):
        stem = stem.rstrip('H')
        nme = 'H' + nme

    if lex == 'XV>/' and stem.endswith('H'):
        stem = stem.rstrip('H')
        nme = 'H' + nme

    if lex == 'P<LH/' and stem.endswith('T'):
        stem = stem.rstrip('T')
        nme = 'T' + nme

    if lex == 'XJH/' and stem.endswith('T'):
        stem = stem.rstrip('T')
        nme = 'T' + nme

    if lex == 'TMJM/' and stem.endswith('JMM'):
        stem = stem.rstrip('M')
        nme = 'M' + nme

    return stem, nme


class DSSMatresProcessor:
    """
    Parser for vowel letters in the Biblical DSS. This is done by comparing a stem of a word in the DSS with
    stems of the same lexeme in the MT.
    """
    def __init__(self, corpus, relevant_sps):
        self.corpus = corpus
        self.relevant_sps = relevant_sps
        self.stems_dict = self.make_stems_dict()
        self.biblical_sections = self.collect_biblical_sections()
        self.matres_dss_dict = {}
        self.dss_matres_df = None

        self.process_dss_scrolls()
        self.save_dss_data()

    def make_stems_dict(self):
        """
        Returns stems_dict: dictionary
        Key: lexeme from BHSA
        Value: set containing tuples with (g_cons, matres_pattern, prefix)
        """
        stems_dict = collections.defaultdict(set)

        for verse in Scroll.scrolls['MT'].verses:
            verse_obj = Scroll.scrolls['MT'].verses[verse]
            for word_obj in verse_obj.words:
                if word_obj.sp in self.relevant_sps:
                    pattern = word_obj.matres_pattern[:len(word_obj.stem)]
                    matres_info = (word_obj.stem, pattern, word_obj.prefix_g_cons)
                    if pattern:
                        stems_dict[word_obj.lex].add(matres_info)
        return stems_dict

    def collect_biblical_sections(self):
        """
        returns set of tuples with biblical sections based on MT,
        e.g., ('Genesis', 1, 1)
        """
        return set(Scroll.scrolls['MT'].verses.keys())

    def check_word_conditions(self, word_obj):
        is_hebrew = word_obj.lang == 'Hebrew'
        is_sp_relevant = word_obj.sp in self.relevant_sps
        return all([is_hebrew, word_obj.lex, word_obj.g_cons, is_sp_relevant])

    @staticmethod
    def parse_prefix_g_cons_dss(tf_id):
        prefix_g_cons = ''
        previous_word_id = tf_id - 1
        while Fdss.after.v(previous_word_id) is None:
            prev_word_g_cons = Fdss.g_cons.v(previous_word_id)
            if prev_word_g_cons is None:
                prev_word_g_cons = ''
            prefix_g_cons = prev_word_g_cons + prefix_g_cons
            previous_word_id = previous_word_id - 1
        return prefix_g_cons

    def process_dss_scrolls(self):
        for scroll_name in Scroll.scrolls:
            if scroll_name == 'MT':
                continue
            for section in self.biblical_sections:
                if section in Scroll.scrolls[scroll_name].verses:
                    verse_obj = Scroll.scrolls[scroll_name].verses[section]
                    word_objects = [word for word in verse_obj.words if self.check_word_conditions(word)]
                    for w_obj in word_objects:
                        w_obj.prefix_g_cons = self.parse_prefix_g_cons_dss(w_obj.tf_word_id)
                        stem = w_obj.g_cons.removesuffix(w_obj.hloc).removesuffix(w_obj.prs_cons)
                        if not stem:
                            continue
                        stem, nme_dss = parse_nme_dss(stem, w_obj.lex, w_obj.state, w_obj.number,
                                                      w_obj.gender, w_obj.sp,
                                                      w_obj.prs_cons)
                        w_obj.stem, w_obj.nme_cons = stem, nme_dss

                        cases = self.stems_dict.get(w_obj.lex, '')
                        prefixes_bhsa = [case[2] for case in cases]
                        if w_obj.prefix_g_cons in prefixes_bhsa:
                            cases = [case for case in cases if case[2] == w_obj.prefix_g_cons]
                        if cases:
                            bo, ch, ve = section
                            pattern = self.parse_matres(cases, stem, w_obj.g_cons, w_obj.prefix_g_cons,
                                                        bo, ch, ve, scroll_name)
                            w_obj.matres_pattern = pattern

                            self.matres_dss_dict[w_obj.tf_word_id] = [w_obj.tf_word_id, scroll_name,
                                                                      bo, ch, ve, w_obj.lex,
                                                                      w_obj.g_cons, stem, pattern[:len(stem)],
                                                                      pattern, w_obj.vs, w_obj.vt,
                                                                      w_obj.number, w_obj.gender, w_obj.person,
                                                                      w_obj.sp, w_obj.prs_cons, nme_dss, w_obj.hloc,
                                                                      w_obj.prefix_g_cons, w_obj.rec_signs,
                                                                      w_obj.cor_signs]

    def parse_matres(self, cases, stem, g_cons, prefix_g_cons, bo, ch, ve, scroll_name):
        alignment_and_mater_data = AlignAndMaterData()
        for case in cases:
            stem_l, matres_pattern_l, prefix_g_cons_bhsa = case
            if not (stem_l and stem):
                continue
            if prefix_g_cons and prefix_g_cons_bhsa:
                if not ((prefix_g_cons_bhsa in prefix_g_cons) or (prefix_g_cons in prefix_g_cons_bhsa)):
                    continue
            mt_dss_alignments = MTDSSAlignments(stem_l, stem, matres_pattern_l)
            alignment_and_mater_data.alignments.append(mt_dss_alignments)

        if not alignment_and_mater_data.alignments:  # returns empty pattern, only a few cases.
            return ''
        all_dash_counts = [al.dash_count for al in alignment_and_mater_data.alignments]

        min_dashes = min(all_dash_counts)

        dss_patterns_one_word = []
        for alignment_data in alignment_and_mater_data.alignments:

            if alignment_data.dash_count == min_dashes:
                dashed_pattern = mt_dss_alignments.add_dashes()

                dss_pattern_builder = DSSPatternBuilder(dashed_pattern, mt_dss_alignments.dss_aligned)
                dss_pattern = dss_pattern_builder.build_dss_pattern()

                dss_patterns_one_word.append((g_cons, mt_dss_alignments.dss_aligned.replace('-', ''), dss_pattern, bo, ch, ve, scroll_name))
        pattern_counts = collections.Counter(dss_patterns_one_word)

        pattern = self.select_pattern(pattern_counts)

        return pattern

    @staticmethod
    def select_pattern(pattern_counts):
        pattern = ''
        if len(pattern_counts) == 1:
            pattern = list(pattern_counts.keys())[0][2]

        elif len(pattern_counts) > 1:
            counts = list(pattern_counts.values())
            if counts.count(max(counts)) == 1:
                for k, v in pattern_counts.items():
                    if v == max(counts):
                        pattern = k[2]
            else:
                all_patterns = [k[2] for k in pattern_counts.keys()]
                pattern = ''
                for pat in all_patterns:
                    if pat.count('M') > pattern.count('M'):
                        pattern = pat
        return pattern

    def save_dss_data(self):
        dss_matres_df = pd.DataFrame(self.matres_dss_dict).T
        dss_matres_df.columns = df_columns
        self.dss_matres_df = dss_matres_df
        dss_matres_df.to_csv(data_path, sep='\t', index=False)


class DSSPatternBuilder:
    def __init__(self, dashed_mt_pattern, dss_alignment):
        self.dashed_mt_pattern = dashed_mt_pattern
        self.dss_alignment = dss_alignment
        self.dss_pattern = ''

    def build_dss_pattern(self):
        """
        Builds the matres pattern for a DSS word by comparing its dashed consonantal representation with the dashed
        MT matres pattern.
        """
        for idx, (pattern_char, char) in enumerate(zip(self.dashed_mt_pattern, self.dss_alignment)):
            if '-' in self.dss_alignment and idx == len(
                    self.dss_alignment.rstrip('-')) - 1 and char in {'>', 'J', 'W'}:
                self.dss_pattern += 'M'
                continue
            if char == '-':
                continue
            if pattern_char in {'M', 'C'}:
                self.dss_pattern += pattern_char
            else:
                if char in {'>', 'J', 'W'}:
                    self.dss_pattern += 'M'
                else:
                    self.dss_pattern += 'C'
        return self.dss_pattern


class MTDSSAlignments:

    def __init__(self, mt_text, dss_text, mt_pattern):
        self.mt_text = mt_text
        self.dss_text = dss_text
        self.mt_aligned, self.dss_aligned = self.align_words()
        self.mt_pattern = mt_pattern
        self.mt_pattern_dash = self.mt_pattern
        self.dash_count = self.count_dashes()

    def align_words(self):
        alignments = pairwise2.align.globalxx(Seq(self.mt_text), Seq(self.dss_text))
        mt_aligned = (alignments[0][0]).strip(' ')
        dss_aligned = (alignments[0][1]).strip(' ')
        return mt_aligned, dss_aligned

    def count_dashes(self):
        return (self.mt_aligned + self.dss_aligned).count('-')

    def add_dashes(self):
        """Add dashes in the pattern (str) at the indices where they occur in the aligned text (str)"""
        for idx, char in enumerate(self.mt_aligned):
            if char == '-':
                self.mt_pattern_dash = f'{self.mt_pattern_dash[:idx]}-{self.mt_pattern_dash[idx:]}'
        return self.mt_pattern_dash


class AlignAndMaterData:
    def __init__(self):
        self.alignments = []


class DSSMatresParser:
    def __init__(self, cases, stem, g_cons, prefix_g_cons, bo, ch, ve, scroll_name):
        self.cases = cases
        self.stem = stem
        self.g_cons = g_cons
        self.prefix_g_cons = prefix_g_cons
        self.bo = bo
        self.ch = ch
        self.ve = ve
        self.scroll_name = scroll_name

