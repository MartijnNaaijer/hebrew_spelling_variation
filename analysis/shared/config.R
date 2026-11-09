DATA_FOLDER <- 'C:/Users/geitb/Kopenhagen/KopenhagenResearch/scripts_research/hebrew_spelling_variation/data'
MODEL_FOLDER <- 'D:/brms_models_spelling/models_rstanarm'
EBH_BOOKS <- c("Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua", 
               "Judges", "1_Samuel", "2_Samuel", "1_Kings", "2_Kings"
)

LBH_BOOKS <- c("Esther", "Daniel", "Ezra", "Nehemiah", "1_Chronicles", "2_Chronicles")

LAW_BOOKS <- c("Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy")

QSP_SCROLLS = c('1Qisaa', '1QisaaI', '1QisaaII', '2Q3', '4Q13', '4Q20', '2Q7', 
                '4Q27', '1Q4', '2Q12', '4Q37', '4Q38', '4Q38a', '4Q40', '4Q53',
                '4Q57', '2Q13', '4Q78', '4Q80', '4Q82', '4Q128', '4Q129', '4Q134', 
                '4Q135', '4Q136', '4Q137', '4Q138', '4Q139', '4Q140', '4Q141', 
                '4Q142', '4Q143', '4Q144', '4Q158', '4Q364',
                '4Q365', '4Q96', '4Q111', '4Q109', '11Q5', '11Q6', '11Q7', '11Q8'
)

factor_columns <- c('has_prefix',
                    'has_prs',
                    'has_nme',
                    'has_hloc',
                    'lex',
                    'book',
                    'book2',
                    'has_vowel_letter',
                    'type',
                    'scroll'
)

law_phase2_levels <- c('MT Pentateuch', 'MT Former Prophets', 'MT LBH', 'MT Other',            
                       'SP', 'Non-QSP Pentateuch',     
                       'Non-QSP Former Prophets', 'Non-QSP LBH', 'Non-QSP Other', 
                       'QSP Pentateuch', 'QSP Former Prophets', 'QSP LBH', 'QSP Other'            
                       )

law_phase3_levels <- c('MT Pentateuch', 'MT Former Prophets', 'MT LBH', 'MT Other',            
                       'SP', 'Non-QSP Pentateuch',     
                       'Non-QSP Former Prophets', 'Non-QSP LBH', 'Non-QSP Other', 
                       'QSP')

# Verbs starting "originally" with yod, in contrast to I-waw verbs
YOD_VERBS <- c('JBC[', 'JNQ[', 'JCR[', 'JVB[', 'JQY[', 'JLL[', 'JMN[')

##############################################################
# analysis_verbs: new outputs, separate from the old fits/figures
##############################################################

# Model fits of analysis_verbs (the old fits in models_rstanarm stay untouched)
MODEL_FOLDER <- 'D:/brms_models_spelling/analysis_verbs'
dir.create(MODEL_FOLDER, showWarnings = FALSE, recursive = TRUE)

# Folder of a verb form, e.g. verb_form_dir('ptcp_qal')
verb_form_dir <- function(verb_form) file.path(ANALYSIS_DIR, verb_form)
