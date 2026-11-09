################################################################################
# Chapter 11: the manuscripts of Isaiah (2026-11-03)
#
# Replaces the "Isaiah manuscripts" sections of the old scripts
# (verbs/script_*_cleaned.R, nouns_adjectives/nouns_adjectives_cleaned.R).
# Plan, audit (phase 0) and decisions: Claude doc "Chapter 11 revision: Isaiah
# manuscripts" (https://claude.ai/artifact/ChZiXJCzim1WBLpvt5Px7d). Decisions
# (author, 2026-11-03):
#   1. Refit on the cleaned chapter 8-9 data with the priors of chapters 8-9
#      (book_priors(): normal(0, 1.5), exponential(1) for the lexeme sd).
#   2. has_vowel_letter ~ scroll + has_suffix + (1 | lex) for every feature
#      (verbs since 2026-11-04, author; before: scroll + (1 | lex), because the
#      suffix coding of the participles differed between MT and the scrolls,
#      which the data of 2026-11-03 corrected); for final-syllable and
#      monosyllabic waw also scroll x has_suffix.
#   3. Five-form rule (a scroll enters a model with more than five forms).
#      Contrasts on fewer than 20 forms or on a scroll whose forms are all full
#      or all defective are flagged and not called credible.
#   4. Fixed contrasts against MT Isaiah. Reported: medians and 95% quantile
#      intervals.
#   5. Parallels (the same lexeme in the same verse, paired by occurrence;
#      hiphil by the stored MT match, as in chapter 9) per scroll and feature.
#   6. Figure 11.1: observed share of full forms in MT Isaiah per feature.
# Data: ../clustering/data/cleaned_*.tsv (from ../clustering/export_cleaned_data.R);
# the consonantal forms for the parallel lists come from the raw files.
#
# Run:  Rscript isaiah_analysis.R   (fits once into MODEL_FOLDER, reloads after)
################################################################################

suppressMessages({
  library(tidyverse)
})
source('C:/Users/geitb/Dropbox/monograph_orthography/verbs/analysis_verbs/functions.R')

HERE <- 'C:/Users/geitb/Dropbox/monograph_orthography/isaiah'
DATA <- 'C:/Users/geitb/Dropbox/monograph_orthography/clustering/data'
RAW <- 'C:/Users/geitb/Kopenhagen/KopenhagenResearch/scripts_research/hebrew_spelling_variation/data'
MODEL_FOLDER <- 'D:/brms_models_spelling/isaiah'
RES <- file.path(HERE, 'results'); FIG <- file.path(HERE, 'figures')
for (d in c(RES, FIG, file.path(RES, 'parallel_lists'), MODEL_FOLDER)) dir.create(d, showWarnings = FALSE, recursive = TRUE)

MIN_FORMS <- 6        # a scroll enters a model with more than five forms
SMALL <- 20           # contrasts on fewer forms are flagged
ONLY_DATA <- Sys.getenv('ISA_ONLY_DATA') == '1'   # parallels and counts only, no models

FEATURES <- tribble(
  ~feature,               ~label,                                        ~raw,                              ~noun, ~interaction,
  'final_w',              'Final syllable, optional {h:ו}',              'nouns_adjectives.csv',            TRUE,  TRUE,
  'final_y',              'Final syllable, optional {h:י}',              'nouns_adjectives.csv',            TRUE,  FALSE,
  'single_w',             'Monosyllabic, optional {h:ו}',                'nouns_adjectives.csv',            TRUE,  TRUE,
  'single_y',             'Monosyllabic, optional {h:י}',                'nouns_adjectives.csv',            TRUE,  FALSE,
  'first_w',              'First syllable, optional {h:ו}',              'nouns_adjectives.csv',            TRUE,  FALSE,
  'first_y',              'First syllable, optional {h:י}',              'nouns_adjectives.csv',            TRUE,  FALSE,
  'ptca_qal',             'Qal active participle',                       'ptca_qal.csv',                    FALSE, FALSE,
  'ptcp_qal',             'Qal passive participle',                      'ptcp_qal.csv',                    FALSE, FALSE,
  'infc_qal_triliteral',  'Qal infinitive construct, triliteral',        'infc_qal_triliteral.csv',         FALSE, FALSE,
  'infc_qal_lamed_he',    'Qal infinitive construct, {h:ל״ה}',            'infc_qal_lamed_he.csv',           FALSE, FALSE,
  'infa_qal',             'Qal infinitive absolute',                     'infa_qal.csv',                    FALSE, FALSE,
  'hiphil_triliteral',    'Triliteral hiphil',                           'hiphil_triliteral_with_hireq.csv', FALSE, FALSE,
  'niph_hiph_pe_yod',     'Niphal, hiphil, hophal of {h:פ״י}',            'niph_hiph_pe_yod.csv',            FALSE, FALSE)

ms_label <- function(s) recode(s, MT = 'MT Isaiah', '1QisaaI' = '1QIsa\u1d43 I', '1QisaaII' = '1QIsa\u1d43 II')
md_label <- function(x) str_replace_all(x, '\\{h:([^}]*)\\}', function(m) heb_md(str_sub(m, 4, -2)))
plain_label <- function(x) str_replace_all(x, '\\{h:([^}]*)\\}', '\\1')
ms_order <- function(s) {
  lv <- c('MT', '1QisaaI', '1QisaaII', '1Q8', sort(setdiff(unique(s), c('MT', '1QisaaI', '1QisaaII', '1Q8'))))
  factor(s, levels = intersect(lv, unique(s)))
}

# ---- Data ------------------------------------------------------------------------

raw_forms <- local({
  cache <- list()
  function(file) {
    if (is.null(cache[[file]])) {
      r <- read_tsv(file.path(RAW, file), col_types = cols(.default = 'c'), progress = FALSE)
      if (!'mt_match' %in% names(r)) r$mt_match <- NA_character_
      cache[[file]] <<- r |>
        transmute(tf_id = as.integer(tf_id), g_cons, heb_g_cons, mt_match = suppressWarnings(as.integer(mt_match))) |>
        distinct(tf_id, .keep_all = TRUE)
    }
    cache[[file]]
  }
})

read_isaiah <- function(feature, raw) {
  read_tsv(file.path(DATA, paste0('cleaned_', feature, '.tsv')), col_types = cols(.default = 'c'),
           progress = FALSE) |>
    filter(book2 == 'Isaiah') |>
    mutate(tf_id = as.integer(tf_id), chapter = as.integer(chapter), verse = as.integer(verse),
           has_vowel_letter = as.integer(has_vowel_letter), has_suffix = factor(has_suffix, levels = c('0', '1'))) |>
    left_join(raw_forms(raw), by = 'tf_id') |>
    arrange(tf_id)
}

# ---- Parallels ---------------------------------------------------------------------

# As parallel_forms() / parallel_forms_matched() of chapters 8-9 (same lexeme in
# the same verse, paired by occurrence; hiphil by the stored MT match), but
# keeping the MT form for the lists. Since 2026-11-05 the non-hiphil features
# call parallel_forms() itself with the raw occurrences (raw_occurrences() in
# functions.R): the old numbering after the cleaning shifted the pairing when
# an earlier form was dropped (1Q8 Isa 49:7 QDWC, 4Q57 Isa 22:13 >KWL).
RAW_CLASS <- c(final_w = 'nominal', final_y = 'nominal', single_w = 'nominal', single_y = 'nominal',
               first_w = 'nominal', first_y = 'nominal', ptca_qal = 'ptc_qal', ptcp_qal = 'ptc_qal',
               infc_qal_triliteral = 'infc_qal', infc_qal_lamed_he = 'infc_qal', infa_qal = 'infa_qal',
               niph_hiph_pe_yod = 'niph_hiph_pe_yod')
pair_parallels <- function(dat, feature) {
  mt <- dat |> filter(scroll == 'MT') |>
    select(mt_tf = tf_id, mt_full = has_vowel_letter, mt_heb = heb_g_cons)
  p <- if (feature == 'hiphil_triliteral') {
    dat |> filter(scroll != 'MT', !is.na(mt_match)) |> inner_join(mt, by = c('mt_match' = 'mt_tf'))
  } else {
    parallel_forms(dat, occ = raw_occurrences(RAW_CLASS[[feature]], folder = RAW)) |>
      select(-mt_full, -pattern) |>
      inner_join(mt, by = c('mt_tf_id' = 'mt_tf'))
  }
  p |> mutate(pattern = case_when(mt_full == 1 & has_vowel_letter == 1 ~ 'both full',
                                  mt_full == 0 & has_vowel_letter == 0 ~ 'both defective',
                                  mt_full == 0 & has_vowel_letter == 1 ~ 'scroll fuller',
                                  TRUE ~ 'MT fuller'))
}

parallel_summary <- function(p, feature) {
  p |> count(scroll, pattern) |>
    pivot_wider(names_from = pattern, values_from = n, values_fill = 0) |>
    (\(t) { for (c in c('both full', 'both defective', 'scroll fuller', 'MT fuller')) if (!c %in% names(t)) t[[c]] <- 0L; t })() |>
    transmute(feature, manuscript = scroll, parallels = `both full` + `both defective` + `scroll fuller` + `MT fuller`,
              both_full = `both full`, both_defective = `both defective`, scroll_fuller = `scroll fuller`,
              mt_fuller = `MT fuller`)
}

# ---- Models ------------------------------------------------------------------------

model_data <- function(dat) {
  keep <- dat |> count(scroll) |> filter(n >= MIN_FORMS) |> pull(scroll)
  dat |> filter(scroll %in% keep) |> mutate(scroll = relevel(factor(scroll), ref = 'MT'))
}

# Since 2026-11-04 the verbs also get has_suffix (author): the data of
# 2026-11-03 code the suffix and the nominal endings of the participles in the
# scrolls as in MT, so the old reason for leaving it out is gone. A feature
# whose Isaiah forms all have the same suffix value gets no suffix term.
# Features refitted on the data of 2026-11-03 (verbs: new formula; final_w and
# single_w: has_suffix changed for a few 1QIsaa forms) get the file prefix
# isa_d2_; the isa_ fits of 2026-11-03 stay.
REFIT_D2 <- c('final_w', 'single_w', 'ptca_qal', 'ptcp_qal', 'infc_qal_triliteral', 'infc_qal_lamed_he',
              'infa_qal', 'hiphil_triliteral', 'niph_hiph_pe_yod')
has_suffix_term <- function(dat) n_distinct(dat$has_suffix) > 1

fit_feature <- function(feature, dat, noun, interaction = FALSE) {
  f <- if (interaction) has_vowel_letter ~ scroll * has_suffix + (1 | lex)
       else if (has_suffix_term(dat)) has_vowel_letter ~ scroll + has_suffix + (1 | lex)
       else has_vowel_letter ~ scroll + (1 | lex)
  prefix <- if (feature %in% REFIT_D2) 'isa_d2_' else 'isa_'
  fit_model(paste0(prefix, feature, if (interaction) '_suffix' else '', '.rds'), f, dat, book_priors(1.5))
}

fixed_effects <- function(m, feature, model) {
  d <- as_draws_df(m)
  map_dfr(grep('^b_', names(d), value = TRUE), \(v) tibble(parameter = sub('^b_', '', v), value = d[[v]])) |>
    group_by(parameter) |>
    summarise(med = median(value), l95 = quantile(value, 0.025), u95 = quantile(value, 0.975), .groups = 'drop') |>
    mutate(feature, model, .before = 1)
}

convergence <- function(m, feature, model) {
  s <- posterior::summarise_draws(as_draws_df(m), 'rhat', 'ess_bulk')
  tibble(feature, model, max_rhat = max(s$rhat, na.rm = TRUE),
         min_ess_bulk = min(s$ess_bulk, na.rm = TRUE),
         divergent = sum(filter(nuts_params(m), Parameter == 'divergent__')$Value))
}

# Contrast with MT Isaiah (logit) and probability of full spelling for a
# typical lexeme (random intercepts at 0); unsuffixed forms when the model has
# a suffix term.
scroll_estimates <- function(m, dat, feature) {
  d <- as_draws_df(m)
  scrolls <- levels(dat$scroll)
  map_dfr(scrolls, function(s) {
    contrast <- if (s == 'MT') rep(0, nrow(d)) else d[[paste0('b_scroll', s)]]
    tibble(manuscript = s, contrast = contrast, prob = plogis(d$b_Intercept + contrast))
  }) |>
    group_by(manuscript) |>
    summarise(across(c(contrast, prob), list(med = median, l95 = \(x) quantile(x, 0.025),
                                             u95 = \(x) quantile(x, 0.975),
                                             l66 = \(x) quantile(x, 0.17), u66 = \(x) quantile(x, 0.83))),
              pd = max(mean(contrast > 0), mean(contrast < 0)), .groups = 'drop') |>
    left_join(dat |> group_by(manuscript = as.character(scroll)) |>
                summarise(n = n(), full = sum(has_vowel_letter), suffixed = sum(has_suffix == '1'),
                          lexemes = n_distinct(lex), .groups = 'drop'), by = 'manuscript') |>
    mutate(feature, .before = 1,
           separated = manuscript != 'MT' & (full == 0 | full == n),
           small = manuscript != 'MT' & n < SMALL,
           credible = manuscript != 'MT' & !separated & !small & (contrast_l95 > 0 | contrast_u95 < 0))
}

# Contrast with MT Isaiah per suffix status from the interaction model.
suffix_estimates <- function(m, dat, feature) {
  d <- as_draws_df(m)
  map_dfr(setdiff(levels(dat$scroll), 'MT'), function(s) {
    b <- d[[paste0('b_scroll', s)]]
    i <- d[[paste0('b_scroll', s, ':has_suffix1')]]
    bind_rows(tibble(manuscript = s, suffix = 'unsuffixed', value = b),
              tibble(manuscript = s, suffix = 'suffixed', value = b + i),
              tibble(manuscript = s, suffix = 'difference', value = i))
  }) |>
    group_by(manuscript, suffix) |>
    summarise(med = median(value), l95 = quantile(value, 0.025), u95 = quantile(value, 0.975),
              l66 = quantile(value, 0.17), u66 = quantile(value, 0.83), .groups = 'drop') |>
    left_join(dat |> count(manuscript = as.character(scroll), suffix = if_else(has_suffix == '1', 'suffixed', 'unsuffixed'),
                           name = 'n'), by = c('manuscript', 'suffix')) |>
    mutate(feature, .before = 1)
}

# ---- Figures -----------------------------------------------------------------------

scroll_plot <- function(est, noun) {   # noun: the model has a suffix term (caption)
  est |>
    mutate(manuscript = fct_rev(ms_order(manuscript)), weak = separated | small) |>
    ggplot(aes(y = manuscript, x = 100 * prob_med)) +
    geom_linerange(aes(xmin = 100 * prob_l95, xmax = 100 * prob_u95, colour = weak), linewidth = 0.6) +
    geom_linerange(aes(xmin = 100 * prob_l66, xmax = 100 * prob_u66, colour = weak), linewidth = 1.6) +
    geom_point(aes(colour = weak, fill = weak), shape = 21, size = 2.4) +
    geom_point(aes(x = 100 * full / n), shape = 4, size = 1.8, colour = BOOK_INK_2) +
    scale_colour_manual(values = c(`FALSE` = BOOK_BLUE, `TRUE` = BOOK_GREY), guide = 'none') +
    scale_fill_manual(values = c(`FALSE` = BOOK_BLUE, `TRUE` = 'white'), guide = 'none') +
    scale_y_discrete(labels = \(x) paste0(ms_label(x), ' (', est$n[match(x, est$manuscript)], ')')) +
    scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, 20)) +
    labs(x = 'Full spelling (percent)', y = NULL,
         # three lines: the second line used to run off the right edge (2026-11-04)
         caption = paste0('Point: median; thick and thin line: 66% and 95% interval (typical lexeme',
                          if (noun) ', unsuffixed forms' else '', ').\n',
                          'Cross: observed share. Grey: fewer than 20 forms, or all forms full or all defective.\n',
                          'Number of forms in brackets.')) +
    theme_book() + theme(panel.grid.major.y = element_blank())
}

suffix_plot <- function(se) {
  se |> filter(suffix != 'difference') |>
    mutate(manuscript = fct_rev(ms_order(manuscript)), suffix = factor(suffix, c('unsuffixed', 'suffixed'))) |>
    ggplot(aes(y = manuscript, x = med, colour = suffix)) +
    geom_vline(xintercept = 0, colour = BOOK_GREY, linewidth = 0.4) +
    geom_linerange(aes(xmin = l95, xmax = u95), linewidth = 0.6, position = position_dodge(width = 0.5)) +
    geom_linerange(aes(xmin = l66, xmax = u66), linewidth = 1.6, position = position_dodge(width = 0.5)) +
    geom_point(size = 2.2, position = position_dodge(width = 0.5)) +
    scale_colour_manual(values = c(unsuffixed = BOOK_BLUE, suffixed = BOOK_ORANGE)) +
    scale_y_discrete(labels = ms_label) +
    labs(x = 'Difference from MT Isaiah (logit): fuller \u2192', y = NULL,
         caption = 'Point: median; thick and thin line: 66% and 95% interval.') +
    theme_book() + theme(panel.grid.major.y = element_blank())
}

save_fig <- function(p, name, width = 16, height = 9) {
  ggsave(file.path(FIG, paste0(name, '.png')), p, width = width, height = height, units = 'cm', dpi = 600,
         device = ragg::agg_png, bg = 'white')
  ggsave(file.path(FIG, paste0(name, '.pdf')), p, width = width, height = height, units = 'cm', device = cairo_pdf)
}

# ---- Self-tests (phase 0 audit, cleaned data) --------------------------------------

self_tests <- function(par, counts) {
  chk <- function(f, s, want) {
    got <- par |> filter(feature == f, manuscript == s) |>
      with(c(both_full, both_defective, scroll_fuller, mt_fuller))
    if (!identical(as.integer(got), as.integer(want))) stop('parallels ', f, ' ', s, ': ', paste(got, collapse = '/'))
  }
  chk('final_w', '1Q8', c(89, 75, 6, 18)); chk('single_w', '1Q8', c(42, 69, 0, 9))  # final_w 1Q8 2026-11-05 (raw-text pairing, Isa 49:7)
  chk('ptca_qal', '1Q8', c(13, 35, 25, 1)); chk('ptca_qal', '4Q55', c(2, 3, 5, 0))
  chk('hiphil_triliteral', '1QisaaII', c(151, 3, 6, 5)); chk('niph_hiph_pe_yod', '1QisaaII', c(74, 0, 1, 0))
  chk('infc_qal_triliteral', '1QisaaI', c(3, 14, 35, 0))
  n <- function(f, s) counts |> filter(feature == f, manuscript == s) |> pull(n)
  stopifnot(n('final_w', 'MT') == 825, n('hiphil_triliteral', 'MT') == 266, n('ptca_qal', '4Q60') == 6)
  message('self-tests passed')
}

# ---- Run ---------------------------------------------------------------------------

all_est <- list(); all_fixed <- list(); all_conv <- list(); all_par <- list(); all_counts <- list(); all_suffix <- list()
for (k in seq_len(nrow(FEATURES))) {
  ft <- FEATURES[k, ]
  message('== ', ft$feature)
  dat <- read_isaiah(ft$feature, ft$raw)
  all_counts[[k]] <- dat |> count(manuscript = scroll) |> mutate(feature = ft$feature, .before = 1)
  # parallels
  par <- pair_parallels(dat, ft$feature)
  all_par[[k]] <- parallel_summary(par, ft$feature)
  par |> filter(pattern %in% c('scroll fuller', 'MT fuller')) |>
    arrange(ms_order(scroll), chapter, verse, tf_id) |>
    transmute(manuscript = scroll, reference = paste0('Isa. ', chapter, '.', verse), lexeme = etcbc_to_hebrew(lex),
              lex, scroll_form = heb_g_cons, mt_form = mt_heb, scroll_suffix = as.character(has_suffix),
              fuller = if_else(pattern == 'scroll fuller', 'scroll', 'MT')) |>
    write_tsv(file.path(RES, 'parallel_lists', paste0(ft$feature, '.tsv')))
  if (ONLY_DATA) next
  # model
  md <- model_data(dat)
  m <- fit_feature(ft$feature, md, ft$noun)
  all_conv[[length(all_conv) + 1]] <- convergence(m, ft$feature, 'main')
  all_fixed[[length(all_fixed) + 1]] <- fixed_effects(m, ft$feature, 'main')
  est <- scroll_estimates(m, md, ft$feature)
  all_est[[k]] <- est
  save_fig(scroll_plot(est, has_suffix_term(md)), paste0('fig_ch11_', ft$feature), height = 2.2 + 0.75 * nrow(est))
  rm(m); gc()
  if (ft$interaction) {
    mi <- fit_feature(ft$feature, md, ft$noun, interaction = TRUE)
    all_conv[[length(all_conv) + 1]] <- convergence(mi, ft$feature, 'scroll x suffix')
    all_fixed[[length(all_fixed) + 1]] <- fixed_effects(mi, ft$feature, 'scroll x suffix')
    se <- suffix_estimates(mi, md, ft$feature)
    all_suffix[[length(all_suffix) + 1]] <- se
    save_fig(suffix_plot(se), paste0('fig_ch11_', ft$feature, '_suffix'), height = 2.2 + 0.9 * n_distinct(se$manuscript))
    rm(mi); gc()
  }
}

est <- bind_rows(all_est); par <- bind_rows(all_par); counts <- bind_rows(all_counts)
self_tests(par, counts)
write_tsv(par, file.path(RES, 'parallels.tsv'))
write_tsv(counts, file.path(RES, 'forms_per_manuscript.tsv'))
if (ONLY_DATA) quit(save = 'no')
write_tsv(est, file.path(RES, 'models.tsv'))
write_tsv(bind_rows(all_conv), file.path(RES, 'convergence.tsv'))
write_tsv(bind_rows(all_fixed), file.path(RES, 'fixed_effects.tsv'))
write_tsv(par, file.path(RES, 'parallels.tsv'))
write_tsv(counts, file.path(RES, 'forms_per_manuscript.tsv'))
write_tsv(bind_rows(all_suffix), file.path(RES, 'suffix_contrasts.tsv'))

# Figure 11.1: observed share of full forms in MT Isaiah (Jeffreys interval)
shares <- counts |> filter(manuscript == 'MT') |>
  left_join(est |> filter(manuscript == 'MT') |> select(feature, full), by = 'feature') |>
  left_join(FEATURES |> select(feature, label), by = 'feature') |>
  mutate(share = full / n, lower = qbeta(0.025, full + 0.5, n - full + 0.5),
         upper = qbeta(0.975, full + 0.5, n - full + 0.5))
write_tsv(shares |> mutate(label = plain_label(label)), file.path(RES, 'mt_shares.tsv'))
p <- shares |>
  mutate(label = fct_reorder(md_label(paste0(label, ' (', n, ')')), share)) |>
  ggplot(aes(y = label, x = 100 * share)) +
  geom_linerange(aes(xmin = 100 * lower, xmax = 100 * upper), colour = BOOK_BLUE, linewidth = 0.6) +
  geom_point(colour = BOOK_BLUE, size = 2.4) +
  scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, 20)) +
  labs(x = 'Full spelling in MT Isaiah (percent)', y = NULL,
       caption = 'Point: observed share; line: 95% interval. Number of forms in brackets.') +
  theme_book() + markdown_y() + theme(panel.grid.major.y = element_blank())
save_fig(p, 'fig_ch11_mt_shares', height = 11)
message('done')
