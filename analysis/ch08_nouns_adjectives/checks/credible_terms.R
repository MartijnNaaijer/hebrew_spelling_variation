# Check of 2026-10-25 (see ../../KFOLD_ISSUE.md). Usage: Rscript credible_terms.R [firstw|singlew|finalw|affix_waw|affix_yod]
# Fixed-effect terms with pd >= 0.975 (median, 95% quantile interval) of the candidate models.
suppressPackageStartupMessages({ library(tidyverse); library(brms) })
MF <- 'D:/brms_models_spelling/analysis_nouns'
spec <- list(firstw = c('M3','M4','M5','M6','nB','M6_no_barr','M6_no_dominant'), singlew = c('M3','M4','M5','M6','nB','M6_no_dominant'),
             finalw = c('M3','M4','M5','M6','nB','M6_no_dominant','M6_no_1QIsaa','M6_1QIsaa_split'),
             affix_waw = c('A0','A1','A2','A3','A2_no_dominant'), affix_yod = c('A0','A1','A2','A3','A2_no_dominant'))
if (length(commandArgs(TRUE)) > 0) spec <- spec[commandArgs(TRUE)[1]]
for (tag in names(spec)) for (id in spec[[tag]]) {
  m <- readRDS(file.path(MF, paste0('na_', tag, '_', id, '.rds')))
  dr <- as_draws_df(m) |> select(starts_with('b_'), -b_Intercept)
  t <- tibble(term = sub('^b_', '', names(dr)), est = map_dbl(dr, median),
              lo = map_dbl(dr, quantile, 0.025), hi = map_dbl(dr, quantile, 0.975),
              pd = map_dbl(dr, \(x) max(mean(x > 0), mean(x < 0)))) |>
    filter(pd >= 0.975) |> mutate(across(est:hi, \(x) round(x, 2)), pd = round(pd, 3))
  cat('\n==', tag, id, '(credible terms) ==\n'); print(as.data.frame(t))
  rm(m, dr); gc()
}
