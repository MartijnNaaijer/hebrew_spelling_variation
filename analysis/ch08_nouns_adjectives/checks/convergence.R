# Check of 2026-10-25 (k-fold check). Usage: Rscript convergence.R firstw|singlew|finalw|affix_waw|affix_yod
# Max Rhat, min ESS, divergences, treedepth hits, SDs and affix effects of every stored fit.
suppressPackageStartupMessages({ library(tidyverse); library(brms); library(posterior) })
source('analysis/paths.R')
MF <- file.path(MODEL_ROOT, 'analysis_nouns')
tag <- commandArgs(TRUE)[1]
files <- list.files(MF, paste0('^na_', tag, '_.*[.]rds$'))
out <- map_dfr(files, function(f) {
  m <- readRDS(file.path(MF, f))
  s <- summarise_draws(as_draws_array(m$fit), rhat, ess_bulk, ess_tail)
  np <- nuts_params(m)
  fe <- fixef(m)
  vc <- VarCorr(m)
  r <- tibble(model = sub('[.]rds$', '', sub(paste0('na_', tag, '_'), '', f)), n = nrow(m$data),
         max_rhat = round(max(s$rhat, na.rm = TRUE), 3), min_bulk = round(min(s$ess_bulk, na.rm = TRUE)),
         min_tail = round(min(s$ess_tail, na.rm = TRUE)),
         div = sum(np$Value[np$Parameter == 'divergent__']),
         treedepth = sum(np$Value[np$Parameter == 'treedepth__'] >= 10),
         sd_book = round(vc$scr_book2$sd[1, 1], 2), sd_book_lex = round(vc$`scr_book2:lex`$sd[1, 1], 2),
         suffix = if ('has_suffix1' %in% rownames(fe)) sprintf('%.2f [%.2f, %.2f]', fe['has_suffix1', 1], fe['has_suffix1', 3], fe['has_suffix1', 4]) else '',
         prefix = if ('has_prefix1' %in% rownames(fe)) sprintf('%.2f [%.2f, %.2f]', fe['has_prefix1', 1], fe['has_prefix1', 3], fe['has_prefix1', 4]) else '')
  rm(m); gc(); r
})
print(out, n = 50, width = 250)
