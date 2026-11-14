################################################################################
# Chapter 11 follow-up (author, 2026-11-13): three checks on the Isaiah models.
#
#   A. Part II - Part I of 1QIsaa: posterior difference of the two contrasts with
#      MT Isaiah, from the stored main models (and per suffix status from the
#      scroll x suffix models). No refit.
#   B. Prior sensitivity: the main models (13) and the scroll x suffix models (2)
#      refitted with book_priors(2.5), the prior of chapters 8-9, instead of 1.5.
#      Files isa_p25_<feature>[_suffix].rds in MODEL_FOLDER.
#   C. Paired model on the parallel attestations: per feature, every parallel
#      (scroll form + its MT form) is a pair;
#        has_vowel_letter ~ witness + (1 | lex) + (1 | pair),  witness: MT (reference) or the scroll,
#      so the scroll coefficient is a within-pair contrast (like-for-like: same
#      lexeme, same verse). The MT form is repeated for every scroll it is paired
#      with (one pair per scroll form). Manuscripts with fewer than 6 parallels
#      are left out. final_w and single_w also witness x has_suffix (suffix of
#      the scroll form). Priors book_priors(1.5). Files isa_pair_<feature>[_suffix].rds.
#      Flags: fewer than 20 parallels; all differing parallels in one direction
#      (then the size of the contrast depends on the prior; its sign does not).
#
# Run from the repository root, after isaiah_analysis.R:
#   Rscript analysis/ch11_isaiah/isaiah_followup.R   (fits once into MODEL_FOLDER, reloads after)
# Results: results/followup_*.tsv
################################################################################

# definitions of the main script (everything before its Run section)
local({
  ex <- parse('analysis/ch11_isaiah/isaiah_analysis.R', keep.source = TRUE)
  start <- vapply(attr(ex, 'srcref'), \(s) s[1], 1L)
  run <- min(start[vapply(ex, \(e) any(grepl('all_est', deparse(e))), TRUE)])
  for (i in which(start < run)) eval(ex[[i]], envir = globalenv())
})
suppressMessages(library(brms))

main_file <- function(feature, interaction = FALSE)
  paste0(if (feature %in% REFIT_D4) 'isa_d4_' else if (feature %in% REFIT_D2) 'isa_d2_' else 'isa_', feature,
         if (interaction) '_suffix' else '', '.rds')
# data release v1.4.0: the refits of the features in REFIT_D4 get 'd4_' in their file names
d4 <- function(feature) if (feature %in% REFIT_D4) 'd4_' else ''
formula_for <- function(dat, interaction) {
  if (interaction) has_vowel_letter ~ scroll * has_suffix + (1 | lex)
  else if (has_suffix_term(dat)) has_vowel_letter ~ scroll + has_suffix + (1 | lex)
  else has_vowel_letter ~ scroll + (1 | lex)
}
summ <- function(x) tibble(med = median(x), l95 = quantile(x, 0.025), u95 = quantile(x, 0.975),
                           pd = max(mean(x > 0), mean(x < 0)))

part_diff <- list(); prior_cmp <- list(); prior_suffix <- list(); paired <- list(); paired_suffix <- list()
paired_conv <- list(); prior_conv <- list()

for (k in seq_len(nrow(FEATURES))) {
  ft <- FEATURES[k, ]
  message('== ', ft$feature)
  dat <- read_isaiah(ft$feature, ft$raw)
  md <- model_data(dat)
  has_parts <- all(c('1QisaaI', '1QisaaII') %in% levels(md$scroll))

  # ---- A + B: main model, prior 1.5 (stored) and 2.5 (new) ----
  m15 <- fit_model(main_file(ft$feature), formula_for(md, FALSE), md, book_priors(1.5))
  m25 <- fit_model(paste0('isa_p25_', d4(ft$feature), ft$feature, '.rds'), formula_for(md, FALSE), md, book_priors(2.5))
  prior_conv[[length(prior_conv) + 1]] <- convergence(m25, ft$feature, 'main, prior 2.5')
  e15 <- scroll_estimates(m15, md, ft$feature); e25 <- scroll_estimates(m25, md, ft$feature)
  prior_cmp[[k]] <- inner_join(
    e15 |> select(feature, manuscript, n, full, small, separated, med_15 = contrast_med, l95_15 = contrast_l95,
                  u95_15 = contrast_u95, credible_15 = credible),
    e25 |> select(manuscript, med_25 = contrast_med, l95_25 = contrast_l95, u95_25 = contrast_u95,
                  credible_25 = credible), by = 'manuscript') |>
    filter(manuscript != 'MT') |>
    mutate(excl0_15 = l95_15 > 0 | u95_15 < 0, excl0_25 = l95_25 > 0 | u95_25 < 0)
  if (has_parts) {
    for (pr in list(list(m15, '1.5'), list(m25, '2.5'))) {
      d <- as_draws_df(pr[[1]])
      part_diff[[length(part_diff) + 1]] <- summ(d$b_scroll1QisaaII - d$b_scroll1QisaaI) |>
        mutate(feature = ft$feature, model = 'main', prior = pr[[2]], suffix = 'all', .before = 1)
    }
  }
  rm(m15, m25); gc()

  if (ft$interaction) {
    i15 <- fit_model(main_file(ft$feature, TRUE), formula_for(md, TRUE), md, book_priors(1.5))
    i25 <- fit_model(paste0('isa_p25_', d4(ft$feature), ft$feature, '_suffix.rds'), formula_for(md, TRUE), md, book_priors(2.5))
    prior_conv[[length(prior_conv) + 1]] <- convergence(i25, ft$feature, 'scroll x suffix, prior 2.5')
    prior_suffix[[length(prior_suffix) + 1]] <- inner_join(
      suffix_estimates(i15, md, ft$feature) |> select(feature, manuscript, suffix, n, med_15 = med, l95_15 = l95, u95_15 = u95),
      suffix_estimates(i25, md, ft$feature) |> select(manuscript, suffix, med_25 = med, l95_25 = l95, u95_25 = u95),
      by = c('manuscript', 'suffix'))
    for (pr in list(list(i15, '1.5'), list(i25, '2.5'))) {
      d <- as_draws_df(pr[[1]])
      b1 <- d$b_scroll1QisaaI; b2 <- d$b_scroll1QisaaII
      s1 <- d$`b_scroll1QisaaI:has_suffix1`; s2 <- d$`b_scroll1QisaaII:has_suffix1`
      part_diff[[length(part_diff) + 1]] <- bind_rows(
        summ(b2 - b1) |> mutate(suffix = 'unsuffixed'),
        summ((b2 + s2) - (b1 + s1)) |> mutate(suffix = 'suffixed')) |>
        mutate(feature = ft$feature, model = 'scroll x suffix', prior = pr[[2]], .before = 1)
    }
    rm(i15, i25); gc()
  }

  # ---- C: paired model on the parallels ----
  par <- pair_parallels(dat, ft$feature)
  keep <- par |> count(scroll) |> filter(n >= MIN_FORMS) |> pull(scroll)
  par <- par |> filter(scroll %in% keep) |> mutate(pair = paste(scroll, tf_id))
  pd_long <- bind_rows(
    par |> transmute(pair, lex, witness = scroll, has_vowel_letter, has_suffix),
    par |> transmute(pair, lex, witness = 'MT', has_vowel_letter = mt_full, has_suffix)) |>
    mutate(witness = relevel(factor(witness), ref = 'MT'))
  psum <- parallel_summary(par, ft$feature) |>
    transmute(manuscript, parallels, scroll_fuller, mt_fuller, p_sign)
  mp <- fit_model(paste0('isa_pair_', d4(ft$feature), ft$feature, '.rds'),
                  has_vowel_letter ~ witness + (1 | lex) + (1 | pair), pd_long, book_priors(1.5))
  paired_conv[[length(paired_conv) + 1]] <- convergence(mp, ft$feature, 'paired')
  d <- as_draws_df(mp)
  paired[[k]] <- map_dfr(setdiff(levels(pd_long$witness), 'MT'),
                         \(s) summ(d[[paste0('b_witness', s)]]) |> mutate(manuscript = s, .before = 1)) |>
    left_join(psum, by = 'manuscript') |>
    mutate(feature = ft$feature, .before = 1,
           small = parallels < SMALL, one_direction = (scroll_fuller == 0) != (mt_fuller == 0),
           credible = !small & (l95 > 0 | u95 < 0))
  if (all(c('1QisaaI', '1QisaaII') %in% levels(pd_long$witness)))
    part_diff[[length(part_diff) + 1]] <- summ(d$b_witness1QisaaII - d$b_witness1QisaaI) |>
      mutate(feature = ft$feature, model = 'paired', prior = '1.5', suffix = 'all', .before = 1)
  rm(mp); gc()
  if (ft$interaction) {
    mpi <- fit_model(paste0('isa_pair_', d4(ft$feature), ft$feature, '_suffix.rds'),
                     has_vowel_letter ~ witness * has_suffix + (1 | lex) + (1 | pair), pd_long, book_priors(1.5))
    paired_conv[[length(paired_conv) + 1]] <- convergence(mpi, ft$feature, 'paired, witness x suffix')
    d <- as_draws_df(mpi)
    paired_suffix[[length(paired_suffix) + 1]] <- map_dfr(setdiff(levels(pd_long$witness), 'MT'), function(s) {
      b <- d[[paste0('b_witness', s)]]; i <- d[[paste0('b_witness', s, ':has_suffix1')]]
      bind_rows(summ(b) |> mutate(suffix = 'unsuffixed'), summ(b + i) |> mutate(suffix = 'suffixed'),
                summ(i) |> mutate(suffix = 'difference')) |> mutate(manuscript = s, .before = 1)
    }) |>
      left_join(par |> mutate(suffix = if_else(has_suffix == '1', 'suffixed', 'unsuffixed')) |>
                  count(manuscript = scroll, suffix, pattern) |>
                  pivot_wider(names_from = pattern, values_from = n, values_fill = 0) |>
                  (\(t) { for (c in c('scroll fuller', 'MT fuller')) if (!c %in% names(t)) t[[c]] <- 0L; t })() |>
                  mutate(parallels = rowSums(across(-c(manuscript, suffix)))) |>
                  select(manuscript, suffix, parallels, scroll_fuller = `scroll fuller`, mt_fuller = `MT fuller`),
                by = c('manuscript', 'suffix')) |>
      mutate(feature = ft$feature, .before = 1)
    rm(mpi); gc()
  }
}

write_tsv(bind_rows(part_diff), file.path(RES, 'followup_part2_minus_part1.tsv'))
write_tsv(bind_rows(prior_cmp), file.path(RES, 'followup_prior_sensitivity.tsv'))
write_tsv(bind_rows(prior_suffix), file.path(RES, 'followup_prior_sensitivity_suffix.tsv'))
write_tsv(bind_rows(paired), file.path(RES, 'followup_paired.tsv'))
write_tsv(bind_rows(paired_suffix), file.path(RES, 'followup_paired_suffix.tsv'))
write_tsv(bind_rows(prior_conv, paired_conv), file.path(RES, 'followup_convergence.tsv'))
message('done')
