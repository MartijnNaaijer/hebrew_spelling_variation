"""


"""

# Solution for masculine words with feminine plural endings.
fem_end_words = {'DWR/', 'MQWM/', '>RMWN/', '>WYR/', 'M>WR/', 'M<WN/', 'LWX/', '>RX/', 'ZMJR/', '<WN/'}

# words from which nme T should be stripped
fem_ending_numbers = {'CLJCJT/', 'XMJCJT/'}

# We want to keep these in the analysis.
relevant_wt_words = {'>XWT/', 'MLKWT/', 'XMWT/', '<DWT/', 'KBDT/', '>LMNWT/'}

CONSONANTAL_J_LEXEMES = {'GWJ/', 'DWJ/', 'QWJ/', 'XJJM/', 'GWJ/', 'XJJM/', 'YPWJ/', 'KJLJ/', 'PWYJ/', 'PLJLJH/'}

j_lexemes = ['<BJ/', '<CTJ/', '<DJ/', '<J/', '<LJ/', '<NJ=/', '<PJ/', '>BWJ/', '>J=/', '>JTJ/', '>NJ/', '>PRSJ/',
             '>PRSKJ/', '>PRSTKJ/', '>RJ/', 'BKJ/', 'BLJ/', 'BLWJ/', 'CBJ/', 'CJ/', 'CLJ/', 'CMJM/', 'CNJ/', 'CPJ/',
             'CTJ/', 'CTJ=/', 'DJ/', 'DLJ/', 'DMJ/', 'DMJ=/', 'DPJ/', 'DWJ/', 'DXJ', 'FDJ/', 'GBJ/', 'GDJ/',
             'HBHBJ/', 'HJ/', 'JPJ/', 'KJ/', 'KSWJ/', 'LJLJ/', 'LWJ/', 'M<J/', 'MJM/', 'MC<J/', 'MCJ/', 'MRJ/',
             'MXJ/', 'NCJ/', 'NDJ/', 'NHJ/', 'NJ/', 'NQJ/', 'PLMNJ/', 'PRJ/', 'PTJ/', 'QCJ/', 'QLJ/', 'QRJ/',
             'R<J/', 'R>J=/', 'RJ/', 'RZJ/', 'SKJ/', 'TPTJ/', 'TXNTJ', 'TXTJ/', 'VRPLJ/', 'XFWPJ/', 'XJJM/',
             'XLJ/', 'XRJ=/', 'XWRJ/', 'XYJ/', 'XYJ=/', 'YBJ/', 'YJ/', 'YLJ/', 'YRJ/', 'YRPJ/']

df_columns = ['tf_id', 'scroll',
              'book', 'chapter',
              'verse', 'lex',
              'g_cons', 'stem',
              'pattern', 'pattern_g_cons',
              'vs', 'vt',
              'nu', 'gn',
              'ps', 'sp',
              'prs', 'nme',
              'hloc', 'prefix',
              'rec_signs', 'cor_signs',
              'heb_g_cons']

POTENTIALLY_FEMININE_WORDS = {'<FR=/', '<FRH=/', '>RB</', '>XD/', 'CB</',
                              'CC/', 'CLC/', 'CMNH/', 'CNJM/', 'TC</', 'XMC/'}

# For >XWT/ singular and plural are >XWT, stem is different.
USELESS_PLURALS = ['JWM/', '>JC/', '<JR/', '<DWT/', '>XWT/', '>CPT/']

# >WN/ is sometimes awen, with suffix onka, MWT/ and TWK/, ZJT/ are similar.
# 'XV>T/', 'YB>/' are bit noisy, maybe separate analysis.
REMOVE_LEXEMES = {'BJT/', '>JN/', '>JL=/', 'LJLH/', 'GJ>/',
                  'XJL/', 'MJM/', '<JN/', 'PTJ/', 'MWT/',
                  'R>M/', 'R>CWN/', 'TWK/', '>WN=/',
                  'LJLJT/', 'XJH/', 'FM>L/', 'R>C/',
                  'N>D/', 'YWN/', 'XV>T/', 'YB>/', 'ZJT/'}
# 'FM>L/', 'R>C/', 'N>D/' and 'YWN/' vary between one vowel letter
# and two vowel letters, which is not studied.
# Words with hardly variation in spelling. R>M/ is a special case
# 'R>CWN/' has special patterns, look later

AD_HOC_REMOVALS = {
    2032301: "4Q70	Jeremiah	22	16	>BJWN/	>BWN	>BWN REASON: consonant J is missing",
    2086958: "11Q7	Psalms	2	3	MWSRH/	MWSDRWTJMW	MWSDR	CMCCC REASON: extra D",
    1913690: "1Qisaa	Isaiah	51	7	GDWPH/	MGDPWTM	MGDP	CCCC RESON: extra M",
    1924169: "1Q8	Isaiah	51	7	GDWPH/	MGDPTM	MGDP	CCCC REASON: extra M",
    1894989: "1Qisaa	Isaiah	1	7	MHPKH/	M>PKT	M>PK	CMCCC REASON: H -> > change",
    1899746: "1Qisaa	Isaiah	13	19	MHPKH/	M>PKT	M>PK	CMCC	REASON: H -> > change",
    1915807: "1Qisaa	Isaiah	58	4	>GRP/	GWRP	GWRP	CMCC REASON: > has dropped",
    2025173: "4Q58	Isaiah	57	19	QRWB/	RQRWB	RQRWB	CCCMC REASON: extra R",
    1910344: "1Qisaa	Isaiah	42	19	<WR/	><W>R	><W>R	MCCMC REASON: extra >",
    384518: "MT	Nehemiah	3	13	>CPT/	CPWT	CPWT	CCMC REASON: first > dropped",
    375652:	"MT	Daniel	8	22	MLKWT/	MLKJWT	MLKJ	CCCC REASON, useless plural",
    1996997: "4Q51	1_Samuel	1	24	CLC/	MCLC	MCLC	CCCC REASON: extra M",
    1909165: "1Qisaa	Isaiah	40	9	>LHJM/	>LWHHKMH	>LWHH	CCMCC	 REASON: extra H",
    1905212: "1Qisaa	Isaiah	30	13	<WN/	<HWWN	<HWWN	CCCMC REASON: extra H",
    1907885: "1Qisaa	Isaiah	37	13	<JR/	L<JR	L<JR REASON extra L",
    2048323: "4Q83	Psalms	69	13	NGJNH/	JNGNW	JNGN	MCCC REASON starts with J, prob verb TODO in data",
    1902070: "1Qisaa	Isaiah	22	1	XZJWN/	XZWWN	XZWWN	CCMMC REASON: misses J",
    201936: "MT	2_Kings	10	33	R>WBNJ/	R>WBNJ	R>WBN	CMMCC REASON: strange vocalization",
    331986: "MT	Psalms	119	87	PQWDJM/	PQWDJK	PQWD	CCCC REASON strange case with CCCC",
    1940345: "4Q7	Genesis	1	5	JWM/	JWMM	JWMM	CMCC REASON double M at end of stem",
    1901047: "1Qisaa	Isaiah	18	2	QW==/	QWQW	QWQ	CMC	CMCM REASON: verdubbeling van stam",
    1901165: "1Qisaa	Isaiah	18	7	QW==/	QWQW	QWQ	CMC	CMCM REASON: verdubbeling van stam",
    1904091: "1Qisaa	Isaiah	28	8	QJ>/	QJH	QJ	CC REASON: > aan eind IPV H",
    2066698: "4Q135	Deuteronomy	5	30	>HL/	>HLJLJKM	>HLJL	CCCMC REASON: ADDITION OF JL",
    1993941: "4Q45 Deuteronomy 15 9 >BJWN/ JWN JWN CCC CCC, REASON: >B IS MISSING",
    1944264: "4Q11 Exodus 18 20 XQ/ JM JM CC CC REASON: XQ SI MISSING",
    1974715:	"4Q27	Numbers	26	17	>R>LJ/	>RJ>LJ	>RJ>L",
    2013028: "4Q53	2_Samuel	14	25	QDQD/	QWQDW	QWQD	CMCC REASON: D is missing",
    2078672: "8Q4	Deuteronomy	11	16	>LHJM/	>LWJM	>LW	CCC	CCCMC REASON H IS MISSING",
    2028922: "4Q64	Isaiah	29	3	MYWRH/	MYWWT	MYW	CCC	CCCMC REASON: R IS MISSING",
    2054387: "4Q98g Psalms 89 23 <WLH/ <L CC: MISSING CONSONANT W",
    464999: "SP	Leviticus	11	19	DWKJPT/	DGJPT	DGJPT: CONSONANT G IPV K",
    509232:	"SP	Deuteronomy	14	18	DWKJPT/	DGJPT	DGJPT: CONSONANT G IPV K",
    409975:	"SP	Genesis	10	4	DDNJ=/	RWDNJM	RWDN: CONSONANT R IPV D",
    492388:	"SP	Numbers	23	24	LBJ>/	LBJH	LBJ	CCC: > has dropped",
    492643:	"SP	Numbers	24	9	LBJ>/	LBJH	LBJH: > has dropped",
    519944:	"SP	Deuteronomy	33	20	LBJ>/	LBJH	LBJ",
    493495:	"SP	Numbers	26	17	>R>LJ/	>RWLJ	>RWL: consonantal > has dropped",
    491737:	"SP	Numbers	22	30	<WD/	HWDK	HWD: g_cons has no <",
    246733: "MT Jeremiah 24 1 DWD=/ DWD>J DWD>: exceptional case with > at end",
    }
