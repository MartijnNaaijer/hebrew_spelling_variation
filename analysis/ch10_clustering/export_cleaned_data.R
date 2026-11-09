################################################################################
# Chapter 10: export the cleaned datasets of chapters 8 and 9 (2026-11-03)
#
# The cluster analysis of chapter 10 uses exactly the data of the regression
# chapters (decision 3, Claude doc "Chapter 10 revision: cluster analysis").
#   - nouns and adjectives: read_nouns() + noun_dataset() for the six datasets
#     (functions_nouns.R), as in every chapter 8 script;
#   - verbs: each chapter 9 analysis.R is run only up to its section 2 (data,
#     corrections, exclusions and predictors). Section 1 fits nothing and writes
#     nothing (checked 2026-11-03); models start in section 3.
# Nothing is fitted. Output: data/cleaned_<dataset>.tsv and data/manifest.tsv.
#
# Run:  Rscript export_cleaned_data.R
################################################################################

suppressMessages(library(tidyverse))

OUT <- 'C:/Users/geitb/Dropbox/monograph_orthography/clustering/data'
dir.create(OUT, showWarnings = FALSE)

KEEP <- c('dataset', 'tf_id', 'scroll', 'book', 'book2', 'scr_book2', 'chapter', 'verse', 'lex', 'type', 'lex_vl',
          'vt', 'has_vowel_letter', 'has_suffix', 'has_prs', 'has_nme', 'has_hloc', 'has_prefix', 'corpus',
          'corpus_group')

write_clean <- function(d, id) {
  d$dataset <- id
  d <- d[, intersect(KEEP, names(d))]
  d <- mutate(d, across(everything(), as.character))
  write_tsv(d, file.path(OUT, paste0('cleaned_', id, '.tsv')))
  tibble(dataset = id, forms = nrow(d), documents = n_distinct(d$scr_book2),
         MT = sum(d$scroll == 'MT'), SP = sum(d$scroll == 'SP'), DSS = sum(!d$scroll %in% c('MT', 'SP')))
}

manifest <- list()

# ---- Nouns and adjectives (chapter 8) ----
local({
  ANALYSIS_DIR <- 'C:/Users/geitb/Dropbox/monograph_orthography/nouns_adjectives/analysis_nouns'
  source(file.path(ANALYSIS_DIR, 'config.R'), local = TRUE)
  source(file.path(VERBS_DIR, 'functions.R'), local = TRUE)
  source(file.path(ANALYSIS_DIR, 'functions_nouns.R'), local = TRUE)
  dat_all <- read_nouns()
  for (id in NOUN_DATASETS$id) {
    manifest[[id]] <<- write_clean(noun_dataset(dat_all, id), id)
  }
})

# ---- Verbs (chapter 9): each script up to its section 2 ----
VERB_DIR <- 'C:/Users/geitb/Dropbox/monograph_orthography/verbs/analysis_verbs'
for (id in c('ptca_qal', 'ptcp_qal', 'infc_qal_triliteral', 'infc_qal_lamed_he', 'infa_qal',
             'hiphil_triliteral', 'niph_hiph_pe_yod')) {
  lines <- read_lines(file.path(VERB_DIR, id, 'analysis.R'))
  end <- grep('^# ---- 2', lines)[1] - 1
  stopifnot(!is.na(end), !any(grepl('fit_model|load_model|readRDS|saveRDS|write_|ggsave|save_book', lines[1:end]) &
                                !grepl('^\\s*#', lines[1:end])))
  env <- new.env()
  suppressMessages(eval(parse(text = lines[1:end]), envir = env))
  manifest[[id]] <- write_clean(env$dat, id)
  rm(env); gc()
}

manifest <- bind_rows(manifest)
write_tsv(manifest, file.path(OUT, 'manifest.tsv'))
print(manifest, n = Inf)
