# hebrew_spelling_variation
Data and analysis of spelling variation in MT, biblical DSS and SP.

The datasets can be found in the folder "data".

The relevant files are:\

nouns_adjectives.csv\
hiphil_triliteral.csv\
infa_qal.csv\
infc_qal_lamed_he.csv\
infc_triliteral.csv\
niph_hiph_pe_yod.csv\
ptca_qal.csv\
ptcp_qal.csv\

Each row in these files corresponds with a vowel in a word in a particular biblical document, and contains information about the use of a vowel letter and other characteristics of the word.



The preprocessing pipeline consists of the following steps:

1. Uniformize data from different Hebrew sub-corpora (MT, DSS and SP) using classes in data_classes.py.
2. Parse the vowel letters in the MT (parse_matres_mt.py).
3. Parse vowel letters in DSS.
