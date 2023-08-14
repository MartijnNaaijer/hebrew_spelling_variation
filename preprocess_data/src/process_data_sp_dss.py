import os

import pandas as pd

from config import data_path
from data_classes import Scroll
from special_data import df_columns


class SpDssDataProcessor:
    """
    Processor for DSS and SP data.
    Loops through the biblical verses, makes a selection from the corpus
    based on the relevant data, and stores every relevant word in a dictionary,
    which is saved as a csv file for further inspection.
    """
    def __init__(self, corpus, sub_corpus, relevant_data):
        self.corpus = corpus
        self.sub_corpus = sub_corpus
        self.relevant_data = relevant_data

        self.biblical_sections = self.collect_biblical_sections()
        self.word_info_dict = {}
        self.matres_df = None

        self.process_scrolls()
        self.file_name = self.make_file_name()
        self.save_data()

    def collect_biblical_sections(self):
        """
        returns set of tuples with biblical sections based on MT,
        e.g., ('Genesis', 1, 1)
        """
        return set(Scroll.scrolls['MT'].verses.keys())

    def check_word_conditions(self, word_obj):
        is_hebrew = word_obj.lang == 'Hebrew'
        if self.relevant_data == 'subs_adjv':
            is_relevant = word_obj.sp in ['subs', 'adjv']
        elif self.relevant_data == 'ptc_qal':
            is_relevant = word_obj.sp == 'verb' and \
                          word_obj.vt in ['ptca', 'ptcp'] and \
                          word_obj.vs == 'qal'
        elif self.relevant_data == 'infc_qal':
            is_relevant = word_obj.sp == 'verb' and \
                          word_obj.vt == 'infc' and \
                          word_obj.vs == 'qal'
        elif self.relevant_data == 'particles':
            is_relevant = word_obj.lex in {'KJ', 'MJ', 'L>'}
        elif self.relevant_data == 'inf_abs_qal':
            is_relevant = word_obj.sp == 'verb' and \
                          word_obj.vt == 'infa' and \
                          word_obj.vs == 'qal'
        elif self.relevant_data == 'niph_hiph_pe_yod':
            is_relevant = word_obj.sp == 'verb' and \
                          word_obj.lex[0] == 'J' and \
                          word_obj.vs in {'hif', 'nif', 'hof'}
        elif self.relevant_data == 'hiph_triliteral':
            is_relevant = word_obj.sp == 'verb' and \
                          word_obj.vs == 'hif' and \
                          word_obj.lex[1] not in {'W', 'J'} and \
                          word_obj.lex[0] != 'J' and \
                          word_obj.lex[2] != 'H' and \
                          (word_obj.lex[1] != word_obj.lex[2]) #and \
                          #word_obj.vt != 'impf'
        return all([is_hebrew, word_obj.lex, word_obj.g_cons, is_relevant])

    def process_scrolls(self):
        for scroll_name in Scroll.scrolls:
            if self.sub_corpus == 'dss':
                if scroll_name in {'MT', 'SP'}:
                    continue
            elif self.sub_corpus == 'sp':
                if scroll_name != 'SP':
                    continue
            for section in self.biblical_sections:
                if section in Scroll.scrolls[scroll_name].verses:
                    bo, ch, ve = section
                    verse_obj = Scroll.scrolls[scroll_name].verses[section]
                    word_objects = [word for word in verse_obj.words if (self.check_word_conditions(word) and word.stem)]
                    for w_obj in word_objects:
                        self.word_info_dict[w_obj.tf_word_id] = [w_obj.tf_word_id, scroll_name,
                                                                  bo, ch, ve, w_obj.lex,
                                                                  w_obj.g_cons, w_obj.stem, w_obj.stem_pattern,
                                                                  w_obj.pattern, w_obj.vs, w_obj.vt,
                                                                  w_obj.number, w_obj.gender, w_obj.person,
                                                                  w_obj.sp, w_obj.prs_cons, w_obj.nme_cons, w_obj.hloc,
                                                                  w_obj.prefix, w_obj.rec_signs,
                                                                  w_obj.cor_signs, w_obj.heb_g_cons]

    def make_file_name(self):
        return f'all_{self.sub_corpus}_{self.relevant_data}.csv'

    def save_data(self):
        matres_df = pd.DataFrame(self.word_info_dict).T
        matres_df.columns = df_columns
        self.matres_df = matres_df
        matres_df.to_csv(os.path.join(data_path, self.file_name), sep='\t', index=False)
