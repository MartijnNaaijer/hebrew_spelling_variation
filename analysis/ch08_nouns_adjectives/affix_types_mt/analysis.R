################################################################################
# affix_types_mt/analysis.R
#
# Dataset:  nouns_adjectives.csv, final syllable of multisyllabic stems, MT
#           only (book §8.5): the lexemes of ../final_w (optional waw) and
#           ../final_y (optional yod) that vary in spelling within the MT.
# Outcome:  has_vowel_letter (1 = full, 0 = defective).
# Questions (book §8.5.1):
#   1. Do endings and suffixes that contain a vowel letter (-JM, -WT) lead to
#      more defective stems than those without one?
#   2. Is the effect of -WT stronger than that of -JM in waw words, and that
#      of -JM stronger in yod words (avoidance of the same vowel letter in two
#      successive syllables, GKC §8l)?
#   3. Do suffixes without a vowel letter differ (fem. -H; heavy -KM, -HM)?
#   4. Does the type of prefix matter (article, conjunction, preposition)?
#
# Book's model (manuscript 2026-09-10; text and fitted model differ):
#   text:   nme * doc_group + prs * doc_group + has_hloc * doc_group +
#           has_prefix * doc_group + (1 | scr_book2/lex)
#   fitted: nme2 * law_phase3 + prs * law_phase3 + has_hloc * law_phase3 +
#           prefix_type * law_phase3 + (1 | scr_book2/lex)
#   (stored fits bayes_model_mt_sp_dss_nme_last_n_w2_var.rds, 11,541 forms,
#   and bayes_model_mt_sp_dss_nme_last_n_y_var.rds, 2,223 forms). The stored
#   fits contain all categories, also the rare ones that §8.5.1.2 says were
#   excluded.
#
# Status (2026-11-03): all fits done; final models waw A2, yod A3; see
# REPORT.md and ../TODO.md section 5g.
#
# Started from ../../nouns_adjectives.R (section "EFFECT OF PREFIXES AND
# SUFFIXES") and ../../visualizations_different_suffixes_prefixes.R.
# Changes against the old scripts:
#   - Data from read_nouns() / noun_dataset() (functions_nouns.R): the final
#     waw and yod datasets, MT only, then only the lexemes that vary within
#     the MT (as in the book).
#   - prefix_type: in the old script prepare_prefixes() returned a factor
#     instead of the data; here the categories of Table 8.36 are coded once.
################################################################################


# ==== 0. SETUP ====

library(tidyverse)
library(brms)
library(bayesplot)
library(tidybayes)
library(bayestestR)
library(binom)
library(loo)

ANALYSIS_DIR <- 'C:/Users/geitb/Dropbox/monograph_orthography/nouns_adjectives/analysis_nouns'
DATASET_ID <- 'affix_types_mt'
IMAGE_FOLDER <- file.path(ANALYSIS_DIR, DATASET_ID, 'figures')

source(file.path(ANALYSIS_DIR, 'config.R'))
source(file.path(VERBS_DIR, 'functions.R'))
source(file.path(ANALYSIS_DIR, 'functions_nouns.R'))

TAG <- 'affix'                   # figure and table names
MODEL_PREFIX <- 'na_affix_'      # model and k-fold files in MODEL_FOLDER

# ALLOW_FIT = FALSE: only load stored results; stop instead of fitting.
ALLOW_FIT <- FALSE  # nothing fitted yet; set TRUE only after approval
options(analysis_verbs.allow_fit = ALLOW_FIT)


# ==== 1. DATA IMPORT AND PREPARATION ====

dat_all <- read_nouns()

MT_GROUPS <- c('MT Pentateuch', 'MT Former Prophets', 'MT LBH', 'MT other books')

# Categories (author, 2026-10-19): those of Tables 8.34-8.36, plus the 3 m.
# pl. suffix -M; the fem. pl. before a suffix (-TJ / -WTJ, e.g. -WTJKM)
# counts as fem. pl. -T / -WT with that suffix; categories with fewer than 20
# forms in the waw or yod dataset are dropped (with their forms). Codes are
# the factor levels (coefficient names), the names the labels.
# Nominal endings: -T is split by number (fem. sg. construct vs fem. pl.
# without waw); -M is the masc. pl. without yod.
NME_LEVELS <- c(none = 'none', 'fem. sg. -H' = 'H', 'fem. sg. -T' = 'T_sg', 'masc. pl. -JM' = 'JM',
                'masc. pl. -M' = 'M', 'masc. pl. constr. -J' = 'J', 'fem. pl. -WT' = 'WT',
                'fem. pl. -T' = 'T_pl')
# Pronominal suffixes. TODO(check): -H is labelled 3 f. sg. as in the book;
# the data do not distinguish the rare 3 m. sg. -H (../TODO.md section 5g).
PRS_LEVELS <- c(none = 'none', '1 sg. -J' = 'J', '2 sg. -K' = 'K', '3 m. sg. -W' = 'W', '3 f. sg. -H' = 'H',
                '1 pl. -NW' = 'NW', '2 m. pl. -KM' = 'KM', '3 m. pl. -HM' = 'HM', '3 m. pl. -M' = 'M')
# Prefixes (Table 8.36)
PREFIX_LEVELS <- c(none = 'none', article = 'article', conjunction = 'conjunction',
                   preposition = 'preposition', other = 'other')
MIN_FORMS <- 20

affix_dataset <- function(dat_all, id) {
  d <- noun_dataset(dat_all, id) |>
    filter(corpus == 'MT') |>
    group_by(lex_type) |>
    filter(n_distinct(has_vowel_letter) > 1) |>         # varying within the MT
    ungroup() |>
    mutate(nme_raw = coalesce(nme, ''), prs_raw = coalesce(prs, ''),
           nme2 = case_when(nme_raw == '' ~ 'none',
                            nme_raw %in% c('T', 'TJ') & nu == 'pl' ~ 'T_pl',
                            nme_raw == 'T' & nu == 'sg' ~ 'T_sg',
                            nme_raw == 'WTJ' ~ 'WT',
                            TRUE ~ nme_raw),
           prs2 = if_else(prs_raw == '', 'none', prs_raw),
           prefix_type = case_when(prefix == '' ~ 'none', prefix == 'H' ~ 'article',
                                   prefix == 'W' ~ 'conjunction',
                                   prefix %in% c('B', 'K', 'L', 'M') ~ 'preposition',
                                   TRUE ~ 'other'),
           corpus_group = droplevels(corpus_group))
  # Drop categories with fewer than MIN_FORMS forms (and their forms)
  small <- bind_rows(count(d, variable = 'nme2', category = nme2),
                     count(d, variable = 'prs2', category = prs2)) |>
    filter(n < MIN_FORMS | (variable == 'nme2' & !category %in% NME_LEVELS) |
             (variable == 'prs2' & !category %in% PRS_LEVELS))
  attr_dropped <- small
  d <- d |>
    filter(!nme2 %in% small$category[small$variable == 'nme2'],
           !prs2 %in% small$category[small$variable == 'prs2']) |>
    mutate(nme2 = factor(nme2, levels = intersect(NME_LEVELS, unique(nme2))),
           prs2 = factor(prs2, levels = intersect(PRS_LEVELS, unique(prs2))),
           prefix_type = factor(prefix_type, levels = PREFIX_LEVELS)) |>
    droplevels()
  attr(d, 'dropped') <- attr_dropped
  d
}

dat_w <- affix_dataset(dat_all, 'final_w')
dat_y <- affix_dataset(dat_all, 'final_y')
c(waw = nrow(dat_w), yod = nrow(dat_y))
c(waw = n_distinct(dat_w$lex), yod = n_distinct(dat_y$lex))
stopifnot(all(levels(dat_w$corpus_group) == MT_GROUPS), all(levels(dat_y$corpus_group) == MT_GROUPS))

# ---- 1a. Dropped categories (fewer than 20 forms or outside the list) ----
dropped <- bind_rows(waw = attr(dat_w, 'dropped'), yod = attr(dat_y, 'dropped'), .id = 'letter')
dropped
write_csv(dropped, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_dropped_categories.csv')))
table(dat_w$nme2); table(dat_w$prs2); table(dat_y$nme2); table(dat_y$prs2)


# ==== 2. EXPLORATORY ANALYSIS ====

# ---- 2a. Frequency tables (Tables 8.37-8.43) ----

frequency_table <- function(d, var, levels) {
  d |>
    mutate(value = factor(.data[[var]], levels = levels, labels = names(levels))) |>
    filter(!is.na(value)) |>
    count(corpus_group, value) |>
    pivot_wider(names_from = value, values_from = n, values_fill = 0) |>
    mutate(corpus_group = book_group_labels(corpus_group))
}
prefix_levels <- set_names(PREFIX_LEVELS)
freq_tables <- list(
  `8.37 waw endings`  = frequency_table(dat_w, 'nme2', NME_LEVELS),
  `8.38 waw suffixes` = frequency_table(dat_w, 'prs2', PRS_LEVELS),
  `8.39 waw he locale` = dat_w |> count(corpus_group = book_group_labels(corpus_group), has_hloc) |>
    pivot_wider(names_from = has_hloc, values_from = n, names_prefix = 'hloc_', values_fill = 0),
  `8.40 waw prefixes` = frequency_table(dat_w, 'prefix_type', prefix_levels),
  `8.41 yod endings`  = frequency_table(dat_y, 'nme2', NME_LEVELS),
  `8.42 yod suffixes` = frequency_table(dat_y, 'prs2', PRS_LEVELS),
  `8.43 yod prefixes` = frequency_table(dat_y, 'prefix_type', prefix_levels)
)
freq_tables
iwalk(freq_tables, \(tab, name) write_csv(tab, file.path(IMAGE_FOLDER,
  paste0('table_', TAG, '_', gsub('[ .]', '_', name), '.csv'))))

# ---- 2b. Share of full spellings per affix type and MT group ----

affix_shares <- function(d, var, levels, letter) {
  d |>
    mutate(value = factor(.data[[var]], levels = levels, labels = names(levels))) |>
    filter(!is.na(value)) |>
    shares_by(corpus_group, value) |>
    mutate(letter = letter, variable = var)
}
shares <- bind_rows(
  affix_shares(dat_w, 'nme2', NME_LEVELS, 'waw'), affix_shares(dat_w, 'prs2', PRS_LEVELS, 'waw'),
  affix_shares(dat_w, 'prefix_type', prefix_levels, 'waw'),
  affix_shares(dat_y, 'nme2', NME_LEVELS, 'yod'), affix_shares(dat_y, 'prs2', PRS_LEVELS, 'yod'),
  affix_shares(dat_y, 'prefix_type', prefix_levels, 'yod'))
write_csv(shares, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_shares.csv')))

for (l in c('waw', 'yod')) {
  for (v in c('nme2', 'prs2', 'prefix_type')) {
    tab <- shares |>
      filter(letter == l, variable == v) |>
      mutate(row = fct_rev(value), corpus_group = book_group_labels(corpus_group))
    p <- plot_shares(tab) +
      facet_wrap(~ corpus_group, ncol = 2) +
      coord_cartesian(clip = 'off') +          # n labels beyond the panel
      theme(panel.spacing.x = unit(1.6, 'cm'), plot.margin = margin(5, 30, 5, 5))
    save_book_figure(p, paste0('fig_', TAG, '_', l, '_', v), height = 12)
  }
}

# ---- 2c. Lexemes ----

bind_rows(waw = dat_w, yod = dat_y, .id = 'letter') |>
  count(letter, lex, sort = TRUE) |>
  group_by(letter) |>
  slice_head(n = 10)


# ==== 3. DATA MODELLING ====
#
# Design (author, 2026-10-19; ../TODO.md section 5g), as in the other
# scripts: nested (1 | scr_book2/lex); corpus_group = the four MT groups,
# reference MT Pentateuch; priors normal(0, 2.5), exponential(1) on the SDs;
# grouped 5-fold k-fold; final model with credible effects only; prior
# sensitivity sd 1.5 and 4. One model set per vowel letter:
#   A0  binary model on the same data: corpus_group * has_suffix +
#       corpus_group * has_prefix
#   A1  the book's text model: nme2, prs2, has_hloc and has_prefix, each x
#       corpus_group
#   A2  the book's fitted model: as A1 with prefix_type instead of has_prefix
#   A3  A2 without interactions
# For yod, he locale occurs only in MT other books (22 forms), so has_hloc
# has no interaction there (a main effect only).
# Robustness of A2: waw without >LHJM/ (always with -JM, almost always
# defective); yod without ZQN/ (almost always defective).

LETTERS_DATA <- list(waw = dat_w, yod = dat_y)
DOMINANT <- c(waw = '>LHJM/', yod = 'ZQN/')

affix_specs <- function(letter) {
  hloc <- if (letter == 'yod') 'has_hloc' else 'has_hloc * corpus_group'
  re <- '(1 | scr_book2/lex)'
  f <- function(rhs) as.formula(paste('has_vowel_letter ~', rhs, '+', re))
  list(
    A0 = f('corpus_group * has_suffix + corpus_group * has_prefix'),
    A1 = f(paste('nme2 * corpus_group + prs2 * corpus_group +', hloc, '+ has_prefix * corpus_group')),
    A2 = f(paste('nme2 * corpus_group + prs2 * corpus_group +', hloc, '+ prefix_type * corpus_group')),
    A3 = f('corpus_group + nme2 + prs2 + has_hloc + prefix_type')
  )
}
model_file <- function(letter, id, scale_b = PRIOR_SD) {
  noun_model_file(paste0(MODEL_PREFIX, letter, '_'), id, scale_b)
}

# ---- 3a. Prior predictive check ----

iwalk(LETTERS_DATA, function(d, letter) {
  m <- fit_model(model_file(letter, 'A2_prior_only'), affix_specs(letter)$A2, d,
                 book_priors(PRIOR_SD), sample_prior = 'only')
  shares <- posterior_predict(m, ndraws = 4000) |> rowMeans()
  rm(m); gc()
  p <- tibble(share = shares) |>
    ggplot(aes(x = share)) +
    geom_histogram(binwidth = 0.025, boundary = 0, fill = BOOK_GREY, colour = 'white', linewidth = 0.3) +
    geom_vline(xintercept = mean(is_full(d$has_vowel_letter)), colour = BOOK_BLUE, linewidth = 0.8) +
    scale_x_continuous(labels = scales::percent) +
    labs(x = 'Share of full spellings in a simulated dataset (prior only)',
         y = 'Number of simulations', caption = 'Blue line: observed share.') +
    theme_book()
  save_book_figure(p, paste0('check_', TAG, '_', letter, '_prior_predictive'), height = 8)
})

# ---- 3b. Candidate models ----

iwalk(LETTERS_DATA, function(d, letter) {
  iwalk(affix_specs(letter), \(formula, id) ensure_noun_model(model_file(letter, id), formula, d))
})

# ---- 3c. Grouped k-fold cross-validation ----

kfold_file_stem <- function(letter, id) paste0(MODEL_PREFIX, letter, '_', id, '_k5')
folds <- map(LETTERS_DATA, function(d) {
  set.seed(2026)
  loo::kfold_split_grouped(K = 5, x = as.character(d$scr_book2))
})
kfolds <- imap(LETTERS_DATA, function(d, letter) {
  map(set_names(names(affix_specs(letter))), \(id)
    kfold_lazy(model_file(letter, id), kfold_file_stem(letter, id), folds[[letter]]))
})
kfold_tables <- imap(kfolds, function(k, letter) {
  tab <- kfold_table(k)
  write_csv(tab, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_', letter, '_kfold.csv')))
  tab
})
kfold_tables

# ---- 3d. Robustness ----

iwalk(LETTERS_DATA, function(d, letter) {
  ensure_noun_model(model_file(letter, 'A2_no_dominant'), affix_specs(letter)$A2,
                    filter(d, lex != DOMINANT[[letter]]) |> droplevels())
})

# ---- 3e. Final models ----
# Chosen after the k-fold with the credible-effects rules; see REPORT.md.

# waw: A2 (author, 2026-11-02), although the grouped k-fold prefers A1 (A2
# -36.5, SE 4.7): §8.5 asks whether the type of prefix matters (question 4),
# which A1 cannot answer. The k-fold result is part of that answer (the
# prefix types differ little). Kept after the drop-one (author, 2026-11-03),
# although A2 without nme2 x corpus_group (+39.5, SE 7.9) or prefix_type x
# corpus_group (+17.4, SE 6.2) predicts better; see REPORT.md.
# yod: A3 (author, 2026-11-02), best in the grouped k-fold (A0 -25.8, SE
# 9.5). Corpus group, suffix types and he locale are not credible, but kept
# so that all four questions can be answered (prs2 -HM vs -H, question 3).
# Kept after the drop-one (author, 2026-11-03), although A3 without prs2
# predicts better (+6.8, SE 2.1); see REPORT.md.
FINAL_ID <- c(waw = 'A2', yod = 'A3')
stopifnot('Choose the final models (FINAL_ID) after the k-fold' = !anyNA(FINAL_ID))

# Drop-one comparison (rule 4; author, 2026-10-19): the final model without
# each of its effects (each interaction, and each main effect that is not
# part of an interaction), with grouped k-fold. A reduced model that is
# already in the model set is not fitted again.
drop_one_tables <- imap(LETTERS_DATA, function(d, letter) {
  specs <- affix_specs(letter)
  drop_one <- noun_drop_one(specs, FINAL_ID[[letter]])
  if (length(drop_one) == 0) return(NULL)
  walk(drop_one, \(x) if (!x$id %in% names(specs)) ensure_noun_model(model_file(letter, x$id), x$formula, d))
  kfolds_drop <- map(set_names(map_chr(drop_one, 'id')), \(id)
    kfold_lazy(model_file(letter, id), kfold_file_stem(letter, id), folds[[letter]]))
  tab <- drop_one_kfold_table(c(kfolds[[letter]], kfolds_drop), FINAL_ID[[letter]],
                              set_names(map_chr(drop_one, 'id'), names(drop_one)))
  write_csv(tab, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_', letter, '_kfold_drop_one.csv')))
  tab
})
drop_one_tables

# Prior sensitivity: the final models with sd 1.5 and 4
iwalk(LETTERS_DATA, function(d, letter) {
  walk(c(1.5, 4), \(s) ensure_noun_model(model_file(letter, FINAL_ID[[letter]], s),
                                         affix_specs(letter)[[FINAL_ID[[letter]]]], d, scale_b = s))
})


# ==== 4. DATA VISUALISATION ====

# ---- 4a. Tables of fixed effects ----

iwalk(LETTERS_DATA, function(d, letter) {
  m <- load_model(model_file(letter, FINAL_ID[[letter]]))
  write_csv(rownames_to_column(make_fixed_effects_table(m), 'parameter'),
            file.path(IMAGE_FOLDER, paste0('table_', TAG, '_', letter, '_fixed_effects.csv')))
  rm(m); gc()
})

# ---- 4b. Effects per affix category and MT group (Figs. 8.33-8.36) ----
# Total effect of a category in a group (main effect + interaction), vs no
# ending / no suffix / no prefix in the same group. Cells without forms are
# not shown (their coefficients rest on the prior only).

GROUP_COEF <- CORPUS_GROUP_COEF[MT_GROUPS]
AFFIX_VARS <- list(nme2 = NME_LEVELS, prs2 = PRS_LEVELS, prefix_type = PREFIX_LEVELS,
                   has_hloc = c(none = '0', 'he locale' = '1'))

category_effects <- function(model, data) {
  d <- as_draws_df(model)
  coef_or_0 <- function(name) if (name %in% names(d)) d[[name]] else 0
  imap_dfr(AFFIX_VARS, function(levels, var) {
    if (!var %in% names(data)) return(NULL)
    present <- intersect(levels[-1], as.character(unique(data[[var]])))
    map_dfr(present, function(level) {
      main <- paste0('b_', var, level)
      if (!main %in% names(d)) return(NULL)
      imap_dfr(GROUP_COEF, function(g, group) {
        n <- sum(data[[var]] == level & data$corpus_group == group)
        if (n == 0) return(NULL)
        interaction <- if (is.na(g)) 0 else
          coef_or_0(paste0(main, ':corpus_group', g)) + coef_or_0(paste0('b_corpus_group', g, ':', var, level))
        tibble(variable = var, category = names(levels)[levels == level], level = level,
               group = group, n = n, value = d[[main]] + interaction)
      })
    })
  })
}

effects <- imap(LETTERS_DATA, function(d, letter) {
  m <- load_model(model_file(letter, FINAL_ID[[letter]]))
  out <- category_effects(m, d) |> summarise_effects(variable, category, level, group, n)
  rm(m); gc()
  out |> mutate(letter = letter)
})
effects
iwalk(effects, \(tab, letter) write_csv(tab, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_', letter, '_effects.csv'))))

iwalk(effects, function(tab, letter) {
  for (v in unique(tab$variable)) {
    t <- tab |>
      filter(variable == v) |>
      mutate(category = factor(category, levels = rev(names(AFFIX_VARS[[v]]))),
             group = book_group_labels(factor(group, levels = MT_GROUPS)))
    p <- plot_or(t, category) + facet_wrap(~ group, ncol = 2)
    save_book_figure(p, paste0('fig_', TAG, '_', letter, '_effects_', v), height = 12)
  }
})

# ---- 4c. Contrasts between categories (book §8.5.1 questions) ----
# Differences between two categories in the same group (logit scale; odds
# ratio > 1: the first category is fuller).

CONTRASTS <- list(
  waw = tribble(~variable, ~a, ~b,
                'nme2', 'WT', 'JM', 'nme2', 'WT', 'T_pl', 'nme2', 'JM', 'H',
                'prs2', 'W', 'J', 'prs2', 'W', 'K', 'prs2', 'W', 'H', 'prs2', 'NW', 'W',
                'prs2', 'KM', 'K', 'prs2', 'HM', 'H',
                'prefix_type', 'article', 'preposition', 'prefix_type', 'article', 'conjunction'),
  yod = tribble(~variable, ~a, ~b,
                'nme2', 'JM', 'WT', 'nme2', 'JM', 'M', 'nme2', 'JM', 'H',
                'prs2', 'HM', 'H',          # -KM has fewer than 20 yod forms
                'prefix_type', 'article', 'preposition', 'prefix_type', 'article', 'conjunction'))

contrasts <- imap_dfr(LETTERS_DATA, function(d, letter) {
  m <- load_model(model_file(letter, FINAL_ID[[letter]]))
  draws <- category_effects(m, d)
  rm(m); gc()
  pmap_dfr(CONTRASTS[[letter]], function(variable, a, b) {
    da <- filter(draws, .env$variable == .data$variable, level == a)
    db <- filter(draws, .env$variable == .data$variable, level == b)
    inner_join(mutate(da, draw = row_number(), .by = group), mutate(db, draw = row_number(), .by = group),
               by = c('group', 'draw'), suffix = c('_a', '_b')) |>
      transmute(letter = letter, variable = variable, contrast = paste(a, 'vs', b), group,
                value = value_a - value_b)
  })
}) |>
  summarise_effects(letter, variable, contrast, group)
contrasts
write_csv(contrasts, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_contrasts.csv')))

# ---- 4d. Robustness and prior sensitivity ----

robustness <- imap_dfr(LETTERS_DATA, function(d, letter) {
  variants <- c(setNames(model_file(letter, 'A2'), 'A2'),
                setNames(model_file(letter, 'A2_no_dominant'), paste('A2 without', DOMINANT[[letter]])),
                setNames(model_file(letter, FINAL_ID[[letter]], 1.5), paste0(FINAL_ID[[letter]], ', prior sd 1.5')),
                setNames(model_file(letter, FINAL_ID[[letter]], 4), paste0(FINAL_ID[[letter]], ', prior sd 4')))
  imap_dfr(variants, function(file, variant) {
    data <- if (grepl('without', variant)) filter(d, lex != DOMINANT[[letter]]) |> droplevels() else d
    m <- load_model(file)
    out <- category_effects(m, data) |> summarise_effects(variable, category, group) |>
      mutate(letter = letter, variant = variant)
    rm(m); gc()
    out
  })
})
robustness
write_csv(robustness, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_robustness.csv')))

# ---- 4e. The book's fitted models (old fits, read only) ----

old_fits <- c(waw = 'bayes_model_mt_sp_dss_nme_last_n_w2_var.rds',
              yod = 'bayes_model_mt_sp_dss_nme_last_n_y_var.rds')
old_tables <- imap_dfr(old_fits, function(file, letter) {
  m <- readRDS(file.path('D:/brms_models_spelling/models_rstanarm', file))
  out <- as.data.frame(fixef(m)) |> rownames_to_column('parameter') |>
    mutate(letter = letter, rows = nrow(m$data))
  rm(m); gc()
  out
})
write_csv(old_tables, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_book_models_old_fits.csv')))


# ==== 5. MODEL VERIFICATION ====

iwalk(LETTERS_DATA, function(d, letter) {
  m <- load_model(model_file(letter, FINAL_ID[[letter]]))
  verify_model(m, IMAGE_FOLDER, paste0('check_', TAG, '_', letter))
  d$group_nme <- factor(paste0(d$corpus_group, ': ', d$nme2))
  save_book_figure(plot_ppc(group_ppc(m, d, 'group_nme')),
                   paste0('check_', TAG, '_', letter, '_ppc_endings'), height = 16)
  d$group_prs <- factor(paste0(d$corpus_group, ': ', d$prs2))
  save_book_figure(plot_ppc(group_ppc(m, d, 'group_prs')),
                   paste0('check_', TAG, '_', letter, '_ppc_suffixes'), height = 16)
  rm(m); gc()
})
