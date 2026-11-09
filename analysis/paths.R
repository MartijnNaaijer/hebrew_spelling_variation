################################################################################
# Paths of the R analyses, relative to the repository root.
#
# Run every script from the repository root, e.g.
#   Rscript analysis/ch09_verbs/ptca_qal/analysis.R
# Each script starts with source('analysis/paths.R').
#
# Model fits are not in the repository. They are written to and read from
# MODEL_ROOT: the environment variable SPELLING_MODEL_DIR if it is set,
# otherwise analysis/models/ (ignored by git). Below MODEL_ROOT, each analysis
# has its own folder (analysis_nouns, analysis_verbs, isaiah). The folder
# models_rstanarm holds the fits of an earlier version of the analyses, which a
# few scripts compare with when they are present.
################################################################################

if (!file.exists(file.path('analysis', 'paths.R'))) {
  stop('Run the analysis scripts from the root of the hebrew_spelling_variation repository ',
       '(the working directory is now ', getwd(), ').')
}

REPO_DIR      <- normalizePath('.', winslash = '/')
DATA_FOLDER   <- file.path(REPO_DIR, 'data')            # the datasets made by preprocess_data
ANALYSIS_ROOT <- file.path(REPO_DIR, 'analysis')
SHARED_DIR    <- file.path(ANALYSIS_ROOT, 'shared')     # config.R, functions.R, fonts
CH07_DIR      <- file.path(ANALYSIS_ROOT, 'ch07_regression_illustrations')
CH08_DIR      <- file.path(ANALYSIS_ROOT, 'ch08_nouns_adjectives')
CH09_DIR      <- file.path(ANALYSIS_ROOT, 'ch09_verbs')
CH10_DIR      <- file.path(ANALYSIS_ROOT, 'ch10_clustering')
CH11_DIR      <- file.path(ANALYSIS_ROOT, 'ch11_isaiah')
CH12_DIR      <- file.path(ANALYSIS_ROOT, 'ch12_sequences')

# Cleaned datasets of chapters 8 and 9, written by ch10_clustering/export_cleaned_data.R
# and read by chapters 10, 11 and 12.
CLEANED_DATA_DIR <- file.path(CH10_DIR, 'data')

MODEL_ROOT <- Sys.getenv('SPELLING_MODEL_DIR', file.path(ANALYSIS_ROOT, 'models'))
OLD_MODEL_FOLDER <- file.path(MODEL_ROOT, 'models_rstanarm')
