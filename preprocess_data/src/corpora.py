"""
Loads the three Text-Fabric corpora:
- MT: Biblia Hebraica Stuttgartensia Amstelodamensis (github.com/etcbc/bhsa)
- DSS: the biblical Dead Sea Scrolls (github.com/etcbc/dss)
- SP: the Samaritan Pentateuch (github.com/dt-ucph/sp)

The corpora are loaded once, on the first call of load_corpora().
"""
from dataclasses import dataclass
from functools import cache

from config import bhsa_version, dss_version, sp_version


@dataclass(frozen=True)
class CorpusApi:
    F: object
    L: object
    T: object


@dataclass(frozen=True)
class Corpora:
    mt: CorpusApi
    dss: CorpusApi
    sp: CorpusApi


def _api(app):
    return CorpusApi(app.api.F, app.api.L, app.api.T)


@cache
def load_corpora():
    from tf.app import use

    dss = use('etcbc/dss:clone', checkout='clone', version=dss_version, provenanceSpec=dict(moduleSpecs=[]))
    sp = use('dt-ucph/sp:clone', checkout='clone', version=sp_version, provenanceSpec=dict(moduleSpecs=[]))
    mt = use('etcbc/bhsa', version=bhsa_version)
    mt.load(['g_prs', 'g_nme', 'g_pfm', 'g_vbs', 'g_vbe'])
    return Corpora(mt=_api(mt), dss=_api(dss), sp=_api(sp))
