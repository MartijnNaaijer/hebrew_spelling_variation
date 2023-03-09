import collections
import os

from Bio import pairwise2
from Bio.Seq import Seq
import pandas as pd

from config import data_path
from data_classes import F, L, T, Fdss, Ldss, Tdss, Scroll
from special_data import j_lexemes, df_columns, fem_end_words

FILE_NAME = 'matres_dss.csv'


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

    if lex == 'BMH/' and stem.endswith('T'):
        stem = stem.rstrip('T')
        nme = 'T' + nme

    if lex in {'HWH/', 'PLJLJH/', 'LJLJT/', '<W<JM/'} and stem.endswith('J'):
        stem = stem.rstrip('J')
        nme = 'J' + nme

    if lex == 'YJH/' and stem.endswith('>'):
        stem = stem.rstrip('>')
        nme = '>' + nme

    return stem, nme


class DSSMatresProcessor:
    """
    Parser for vowel letters in the Biblical DSS. This is done by comparing a stem of a word in the DSS with
    stems of the same lexeme in the MT.
    """
    def __init__(self, corpus, relevant_data, matres_pattern_dict):
        self.corpus = corpus
        self.relevant_data = relevant_data
        self.matres_pattern_dict = matres_pattern_dict

        self.biblical_sections = self.collect_biblical_sections()
        self.matres_dss_dict = {}
        self.dss_matres_df = None

        self.process_dss_scrolls()
        self.save_dss_data()

    @staticmethod
    def collect_biblical_sections():
        """
        returns set of tuples with biblical sections based on MT,
        e.g., ('Genesis', 1, 1)
        """
        return set(Scroll.scrolls['MT'].verses.keys())

    def check_word_conditions(self, word_obj):
        is_hebrew = word_obj.lang == 'Hebrew'
        if self.relevant_data == 'subs_adjv':
            is_sp_relevant = word_obj.sp in ['subs', 'adjv']
        elif self.relevant_data == 'ptc_qal':
            is_sp_relevant = word_obj.sp == 'verb' and word_obj.vt in ['ptca', 'ptcp'] and word_obj.vs == 'qal'
        elif self.relevant_data == 'infc_qal':
            is_sp_relevant = word_obj.sp == 'verb' and word_obj.vt == 'infc' and word_obj.vs == 'qal'
        elif self.relevant_data == 'nega_lo':
            is_sp_relevant = word_obj.lex == 'L>'
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
                    bo, ch, ve = section
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
                        pattern = self.get_matres_pattern(int(w_obj.tf_word_id))

                        if len(w_obj.g_cons) != len(pattern):
                            print(w_obj.tf_word_id, w_obj.stem, w_obj.g_cons, stem, pattern)

                        self.matres_dss_dict[w_obj.tf_word_id] = [w_obj.tf_word_id, scroll_name,
                                                                  bo, ch, ve, w_obj.lex,
                                                                  w_obj.g_cons, stem, pattern[:len(stem)],
                                                                  pattern, w_obj.vs, w_obj.vt,
                                                                  w_obj.number, w_obj.gender, w_obj.person,
                                                                  w_obj.sp, w_obj.prs_cons, nme_dss, w_obj.hloc,
                                                                  w_obj.prefix_g_cons, w_obj.rec_signs,
                                                                  w_obj.cor_signs]

    def get_matres_pattern(self, tf_id):
        return self.matres_pattern_dict[tf_id]

    def save_dss_data(self):
        dss_matres_df = pd.DataFrame(self.matres_dss_dict).T
        dss_matres_df.columns = df_columns
        self.dss_matres_df = dss_matres_df
        dss_matres_df.to_csv(os.path.join(data_path, FILE_NAME), sep='\t', index=False)


class MatresPatternDataSet:
    """
    Create dictionary (matres_predictions_dict) with matres_pattern for each word in biblical DSS.
    keys: int are text fabric ids of words.
    values : str are matres patterns.
    """
    def __init__(self, matres_predictions_file_name: str):
        self.matres_predictions_file_name = matres_predictions_file_name
        self.matres_predictions_dict = self.matres_predictions_dict()

    def matres_predictions_dict(self):
        df = pd.read_csv(os.path.join(data_path, self.matres_predictions_file_name), sep='\t', header=None)
        df.columns = ['tf_id', 'g_cons', 'matres_pattern']
        matres_dict = {int(tf_id): matres_pattern for tf_id, matres_pattern in zip(df.tf_id, df.matres_pattern)}
        return matres_dict
