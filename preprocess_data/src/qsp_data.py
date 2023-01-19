"""
A number of DSS have a number of special morphological, orthographic and other features,
called Qumran Scribal Practice bu Emanuel Tov (See, e.g., Tov, Textual Criticism of the Hebrew Bible, 3rd ed, 2012.

These scrolls are:
2Qexodb ? = 2Q3
4qexodb,j? = 4Q13, 4Q20
2qnumb ? = 2Q7
4qnumb = 4Q27
1qdeuta = 1Q4
2qdeutc = 2Q12
4qdeutj,k1,k2,m =  4Q37 4Q38 4Q38a 4Q40

4qsamc = 4Q53
1qisaa = 1Qisaa
4qisac = 4Q57
2qjer = 2Q13
4qxiic,e,g = 4Q78 4Q80 4Q82
4qphyl A B G-I J-K L-N O P Q =
    A:4Q128 B:4Q129 G:4Q134 H:4Q135 I:4Q136 J:4Q137 K:4Q138 L:4Q139 M:4Q140 N:4Q141 O:4Q142 P:4Q143 Q:4Q144
4qrpa,b,c = 4Q158, 4Q364, 4Q365
4qpso ? = 4Q96
4qlam = 4Q111
4qqoha = 4Q109
11qps a,b,c?,d? 11Q5 11Q6 11Q7 11Q8

QSP_SCROLLS contains all these scroll names, BEST_QSP_SCROLLS contains the best examples,
according to Tov (2012, 104).
"""

QSP_SCROLLS = ['2Q3', '4Q13', '4Q20', '2Q7', '4Q27', '1Q4', '2Q12', '4Q37', '4Q38', '4Q38a', '4Q40', '4Q53',
               '1Qisaa', '4Q57', '2Q13', '4Q78', '4Q80', '4Q82', '4Q128', '4Q129', '4Q134', '4Q135', '4Q136',
               '4Q137', '4Q138', '4Q139', '4Q140', '4Q141', '4Q142', '4Q143', '4Q144', '4Q158', '4Q364',
               '4Q365', '4Q96', '4Q111', '4Q109', '11Q5', '11Q6', '11Q7', '11Q8']


BEST_QSP_SCROLLS = ['4Q27', '1Q4', '4Q38a', '4Q40', '4Q53', '1Qisaa', '2Q13', '4Q78', '4Q128', '4Q129',
                    '4Q137', '4Q138', '4Q139', '4Q140', '4Q141']