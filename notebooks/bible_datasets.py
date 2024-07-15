from align_config import dss_version, sp_version
from tf.app import use

MT = use('etcbc/bhsa')
Fmt, Tmt, Lmt = MT.api.F, MT.api.T, MT.api.L

SP = use('dt-ucph/sp', version=sp_version)
Fsp, Tsp, Lsp = SP.api.F, SP.api.T, SP.api.L

DSS = use('etcbc/dss', version=dss_version)
Fdss, Tdss, Ldss = DSS.api.F, DSS.api.T, DSS.api.L