"""
A dataset is created containing nouns and adjectives that show orthographic variation in their stem. With "stem", we
the consonantal representation of a word without suffixes (nominal endings and pronominal suffixes) and without prefixed
words (article or preposition).

"""

import pandas as pd

from data_classes import Corpus
from add_hebrew_text_column import HebrewTextAdder
from first_data_selection_mt import BasicMTDataSelector
from parse_matres_mt import MTMatresProcessor
from parse_matres_dss import DSSMatresProcessor, MatresPatternDataSet
from various_manipulations import FinalAlephConverter, FeminineTStripper, OtherVowelEndingsColumnAdder, \
    FinalYodRemover, MTDSSHelpColumnsAdder, MatresColumnAdder, RecCorColumnsAdder
from process_invalid_data import InvalidDataRemover
from remove_useless_lexemes_and_plurals import UselessRowsRemover, SyllablesWithoutVariationRemover

from special_data import USELESS_PLURALS, REMOVE_LEXEMES, AD_HOC_REMOVALS

# For participles
from remove_useless_participle_roots import UselessParticiplesRemover
from matres_column_participles import ParticiplesCorrector, MatresColumnAdderActiveParticiples

# For infc
from matres_column_infc import InfcLamedHeCorrector, MatresColumnAdderInfinitiveConstructLamedHe, InfcOtherCorrector, \
     MatresColumnAdderInfinitiveConstructTriliteral


def main():

    corpus = Corpus('biblical')

    matres_processor_mt = MTMatresProcessor(corpus)
    mt = matres_processor_mt.mt_matres_df

    matres_pattern_dataset = MatresPatternDataSet('dss_predictions_per_word.txt')

    ####################################################
    # Nouns adjectives
    #mt_dss_nouns_adjvs = get_nouns_adjective_data(corpus, mt, matres_pattern_dataset)
    #mt_dss_nouns_adjvs.to_csv('../data/mt_dss_new_matres_pattern.csv', sep='\t', index=False)

    ####################################################

    # ptca en ptcp qal
    # ptca, ptcp = get_participle_qal_data(corpus, mt, matres_pattern_dataset)
    # ptca = ptca.sort_values(by=['tf_id'])
    # ptcp = ptcp.sort_values(by=['tf_id'])
    # ptca.to_csv('../data/ptca.csv', sep='\t', index=False)
    # ptcp.to_csv('../data/ptcp.csv', sep='\t', index=False)
    # TODO: patterns "CCMC" are strange, "CMCC" is expected.

    # lamed_he_infc, other_infc = get_qal_infinitive_construct_data(corpus, mt, matres_pattern_dataset)
    # print(other_infc.shape)
    # print(lamed_he_infc.shape)
    # lamed_he_infc.to_csv('../data/lamed_he_infc.csv', sep='\t', index=False)
    # other_infc.to_csv('../data/other_infc.csv', sep='\t', index=False)
    # # TODO: add some columns, see nouns_adjvs

    #niph_hiph_pe_yod = get_niphal_hiphil_pe_yod_data(corpus, mt, matres_pattern_dataset)
    #print(niph_hiph_pe_yod.shape)
    #niph_hiph_pe_yod.to_csv('../data/niph_hiph_pe_yod.csv', sep='\t', index=False)

    lo = get_negation_lo(corpus, mt, matres_pattern_dataset)
    print(lo.shape)
    lo.to_csv('../data/lo.csv', sep='\t', index=False)


def get_niphal_hiphil_pe_yod_data(corpus, mt, matres_pattern_dataset):
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='niph_hiph_pe_yod')
    mt_niph_hiph_pe_yod_df = basic_mt_data_selector.select_data()

    mt_niph_hiph_pe_yod_df = mt_niph_hiph_pe_yod_df[(mt_niph_hiph_pe_yod_df.vs == 'hif') |
                                                    ((mt_niph_hiph_pe_yod_df.vs == 'nif') &
                                                     mt_niph_hiph_pe_yod_df.vt.isin({'perf', 'ptca'}))]

    # exclude lexeme JVB[

    return mt_niph_hiph_pe_yod_df


def get_triliteral_hiphil(corpus, mt, matres_pattern_dataset):
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='hiph_triliteral')
    mt_niph_hiph_pe_yod_df = basic_mt_data_selector.select_data()

    # TODO: have look at combinations of ps, nu gn, vt:
    # ((self.data.vt == 'perf') & (self.data.ps == 'p3') |
    # (self.data.vt == 'impf') & (self.data.gn != 'f') & (self.data.nu == 'pl')
    # (self.data.vt == 'ptca'))

    return mt_niph_hiph_pe_yod_df


def get_negation_lo(corpus, mt, matres_pattern_dataset):
    basic_mt_data_selector = BasicMTDataSelector(data=mt, relevant_data='nega_lo')
    mt_nega_lo = basic_mt_data_selector.select_data()

    matres_parser_dss = DSSMatresProcessor(corpus,
                                           relevant_data='nega_lo',
                                           matres_pattern_dict=matres_pattern_dataset.matres_predictions_dict)

    mt_dss_nega_lo_df = pd.concat([mt_nega_lo, matres_parser_dss.dss_matres_df])
    mt_dss_nega_lo_df = mt_dss_nega_lo_df.sort_values(by=['tf_id'])

    hebrew_text_adder = HebrewTextAdder(mt_dss_nega_lo_df)
    mt_dss_nega_lo_df = hebrew_text_adder.data

    # Correct in data: 1957484 is lex L, rest is good, remove deviating cases (L, LH, LW, etc in analysis)

    return mt_dss_nega_lo_df


def get_qal_infinitive_absolute(corpus, mt, matres_pattern_dataset):
    pass


if __name__ == '__main__':
    main()
