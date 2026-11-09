##############################################################
# analysis_nouns: configuration of the noun and adjective analyses (chapter 8)
#
# The data folder, book groups, QSP scroll list and factor levels are those of
# the verb analyses (one copy, in ../shared/config.R); only
# the model folder and the noun-specific settings are set here.
##############################################################

source('analysis/paths.R')
source(file.path(SHARED_DIR, 'config.R'))

# Model fits of analysis_nouns (the old fits in models_rstanarm stay untouched)
MODEL_FOLDER <- file.path(MODEL_ROOT, 'analysis_nouns')
dir.create(MODEL_FOLDER, showWarnings = FALSE, recursive = TRUE)

DATASET <- 'nouns_adjectives.csv'

# Corpus group (7 levels): the MT split by group of books, SP, and the scrolls
# as one group per corpus. Reference level MT Pentateuch, as in the verb
# analyses; SP is a level of its own (author, 2026-10-19); the non-QSP scrolls
# are one group, the book's split (law_phase3) is a comparison model only.
CORPUS_GROUP_LEVELS <- c('MT Pentateuch', 'MT Former Prophets', 'MT LBH',
                         'MT other books', 'SP', 'Non-QSP', 'QSP')

# The six datasets of chapter 8: syllable position (column `type`) and vowel
# letter (most frequent vowel letter of the lexeme in that position).
NOUN_DATASETS <- tibble::tribble(
  ~id,         ~type,    ~letter, ~section, ~label,
  'final_w',   'last',   'W',     '8.2.2',  'final syllable, optional waw',
  'final_y',   'last',   'J',     '8.2.3',  'final syllable, optional yod',
  'single_w',  'single', 'W',     '8.3.2',  'monosyllabic stem, optional waw',
  'single_y',  'single', 'J',     '8.3.3',  'monosyllabic stem, optional yod',
  'first_w',   'first',  'W',     '8.4.2',  'first syllable, optional waw',
  'first_y',   'first',  'J',     '8.4.3',  'first syllable, optional yod'
)

# Counts in the manuscript of 2026-09-10 (forms, lexemes), for comparison only.
BOOK_COUNTS <- tibble::tribble(
  ~id,        ~book_forms, ~book_lexemes,
  'final_w',  19639,       376,
  'final_y',  4695,        134,
  'single_w', 15334,       106,
  'single_y', 1197,        37,
  'first_w',  9741,        148,
  'first_y',  787,         NA    # "23 {or 24?}" in the text
)
