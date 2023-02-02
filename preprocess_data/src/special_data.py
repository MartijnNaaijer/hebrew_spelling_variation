"""


"""

# Plural as lexeme, occurring only as plural.
no_ut_lexemes = {'TWY>WT/', 'NVJCWT/', 'TWLDWT/', 'BXWRWT/', '<LLWT/', 'XMDWT/'}

# Solution for masculine words with feminine plural endings.
fem_end_words = {'DWR/', 'MQWM/', '>RMWN/', '>WYR/', 'M>WR/', 'M<WN/', 'LWX/', '>RX/', 'ZMJR/', '<WN/'}

j_lexemes = ['<BJ/', '<CTJ/', '<DJ/', '<J/', '<LJ/', '<NJ=/', '<PJ/', '>BWJ/', '>J=/', '>JTJ/', '>NJ/', '>PRSJ/',
             '>PRSKJ/', '>PRSTKJ/', '>RJ/', 'BKJ/', 'BLJ/', 'BLWJ/', 'CBJ/', 'CJ/', 'CLJ/', 'CMJM/', 'CNJ/', 'CPJ/',
             'CTJ/', 'CTJ=/', 'DJ/', 'DLJ/', 'DMJ/', 'DMJ=/', 'DPJ/', 'DWJ/', 'DXJ', 'FDJ/', 'GBJ/', 'GDJ/', 'GWJ/',
             'HBHBJ/', 'HJ/', 'JPJ/', 'KJ/', 'KJLJ', 'KSWJ/', 'LJLJ/', 'LWJ/', 'M<J/', 'MJM/', 'MC<J/', 'MCJ/', 'MRJ/',
             'MXJ/',
             'NCJ/', 'NDJ/', 'NHJ/', 'NJ/', 'NQJ/', 'PLMNJ/', 'PRJ/', 'PTJ/', 'PWYJ/', 'QCJ/', 'QLJ/', 'QRJ/', 'QWJ/',
             'R<J/', 'R>J=/', 'RJ/', 'RZJ/', 'SKJ/', 'TPTJ/', 'TXNTJ', 'TXTJ/', 'VRPLJ/', 'XFWPJ/', 'XJJM/', 'XLJ/',
             'XRJ=/', 'XWRJ/', 'XYJ/', 'XYJ=/', 'YBJ/', 'YJ/', 'YLJ/', 'YPWJ/', 'YRJ/', 'YRPJ/']

df_columns = ['tf_id', 'scroll',
              'book', 'chapter',
              'verse', 'lex',
              'g_cons', 'stem',
              'pattern', 'pattern_g_cons',
              'vs', 'vt',
              'nu', 'gn',
              'ps', 'sp',
              'prs', 'nme',
              'hloc', 'prefix_g_cons',
              'rec_signs', 'cor_signs']

POTENTIALLY_FEMININE_WORDS = {'<FR=/', '<FRH=/', '>RB</', '>XD/', 'CB</',
                              'CC/', 'CLC/', 'CMNH/', 'CNJM/', 'TC</', 'XMC/'}