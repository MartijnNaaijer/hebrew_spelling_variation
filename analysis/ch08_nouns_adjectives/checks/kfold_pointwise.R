# Check of 2026-10-25 (k-fold check). Usage: Rscript kfold_pointwise.R firstw|singlew
# Pointwise k-fold elpd by fold, corpus group and form; folds rebuilt as in analysis.R (set.seed(2026)).
suppressPackageStartupMessages({ library(tidyverse); library(brms); library(posterior) })
source('analysis/paths.R')
MF <- file.path(MODEL_ROOT, 'analysis_nouns')
args <- commandArgs(TRUE); tag <- args[1]
ids <- c('M0','M1','M2','M3','M4','M5','M6','nB')
m0 <- readRDS(file.path(MF, paste0('na_', tag, '_M0.rds')))
d <- m0$data; rm(m0); gc()
extra <- readRDS(file.path(MF, paste0('na_', tag, '_M3.rds')))$data
d <- bind_cols(d, extra[, setdiff(names(extra), names(d)), drop = FALSE])
set.seed(2026); d$fold <- loo::kfold_split_grouped(K = 5, x = as.character(d$scr_book2))
pw <- map_dfc(set_names(ids), \(id) readRDS(file.path(MF, paste0('kfold_na_', tag, '_', id, '_k5.rds')))$pointwise[, 'elpd_kfold'])
d <- bind_cols(d, pw)
cat('\n== elpd by fold (sum) ==\n')
d |> group_by(fold) |> summarise(n = n(), books = n_distinct(scr_book2), across(all_of(ids), sum)) |>
  mutate(across(all_of(ids), \(x) round(x - M2))) |> print()
cat('\n== worst forms M3 vs M2 ==\n')
d |> mutate(diff = M3 - M2) |> arrange(diff) |> select(fold, scr_book2, lex, corpus_group, has_suffix, has_prefix, has_vowel_letter, M2, M3, diff) |> head(12) |> print(width = 200)
cat('\n== M3 - M2 by fold x group ==\n')
d |> group_by(fold, corpus_group) |> summarise(n = n(), diff = round(sum(M3 - M2)), .groups = 'drop') |> filter(abs(diff) > 5) |> print(n = 40)
cat('\n== fold composition: corpus_group ==\n'); print(table(d$fold, d$corpus_group))
