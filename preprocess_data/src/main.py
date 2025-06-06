"""
A dataset is created containing nouns and adjectives that show orthographic variation in their stem. With "stem", we
the consonantal representation of a word without suffixes (nominal endings and pronominal suffixes) and without prefixed
words (article or preposition).

"""

# TODO: wayyiqtol/yiqtol of hollow roots
import os

import pandas as pd

from config import data_path
from data_classes import Corpus

from parse_matres_mt import MTMatresProcessor
import pipeline_functions as pf


def main():
    corpus = Corpus('biblical')
    matres_processor_mt = MTMatresProcessor(corpus)
    mt = matres_processor_mt.mt_matres_df

    mt_dss_sp_nouns_adjvs, mt_dss_sp_nouns_adjvs_all = pf.get_nouns_adjective_data(corpus, mt)

    # Remove ad hoc words with variation between one/more matres
    mt_dss_sp_nouns_adjvs.to_csv(os.path.join(data_path, 'nouns_adjectives.csv'), sep='\t', index=False)
    mt_dss_sp_nouns_adjvs_all.to_csv(os.path.join(data_path, 'nouns_adjectives_incl_no_variation.csv'), sep='\t', index=False)

    #ptca, ptcp = pf.get_participle_qal_data(corpus, mt)
    #ptca = ptca.sort_values(by=['tf_id'])
    #ptcp = ptcp.sort_values(by=['tf_id'])
    #ptca.to_csv(os.path.join(data_path, 'ptca_qal.csv'), sep='\t', index=False)
    #ptcp.to_csv(os.path.join(data_path, 'ptcp_qal.csv'), sep='\t', index=False)
     # # TODO: patterns "CCMC" are strange, "CMCC" is expected.

    #lamed_he_infc, other_infc = pf.get_qal_infinitive_construct_data(corpus, mt)
    #print(other_infc.shape)
    #print(lamed_he_infc.shape)
    #lamed_he_infc.to_csv(os.path.join(data_path, 'infc_qal_lamed_he.csv'), sep='\t', index=False)
    #other_infc.to_csv(os.path.join(data_path, 'infc_qal_triliteral.csv'), sep='\t', index=False)

    #niph_hiph_pe_yod = pf.get_niphal_hiphil_pe_yod_data(corpus, mt)
    #print(niph_hiph_pe_yod.shape)
    #niph_hiph_pe_yod.to_csv(os.path.join(data_path, 'niph_hiph_pe_yod.csv'), sep='\t', index=False)

    #hiph_triliteral = pf.get_triliteral_hiphil(corpus, mt)
    #print(hiph_triliteral.shape)
    #hiph_triliteral.to_csv(os.path.join(data_path, 'hiphil_triliteral.csv'), sep='\t', index=False)

    #particles = pf.get_particles(corpus, mt)
    #print(particles.shape)
    #particles.to_csv(os.path.join(data_path, 'particles.csv'), sep='\t', index=False)

    #qal_inf_abs = pf.get_qal_infinitive_absolute(corpus, mt)
    #print(qal_inf_abs.shape)
    #qal_inf_abs.to_csv(os.path.join(data_path, 'infa_qal.csv'), sep='\t', index=False)


if __name__ == '__main__':
    main()
