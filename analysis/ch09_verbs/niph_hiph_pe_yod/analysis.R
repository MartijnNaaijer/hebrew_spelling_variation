################################################################################
# niph_hiph_pe_yod/analysis.R
#
# Dataset:  niph_hiph_pe_yod.csv - niphal, hiphil and hophal forms of I-waw and
#           original I-yod verbs (incl. HLK[) in the MT and the Dead Sea Scrolls
#           (no SP forms).
# Outcome:  has_vowel_letter: vowel letter in the first syllable (1 = full,
#           e.g. HWLJD, HJVJB; 0 = defective, e.g. HLJD, HVJB).
# Questions:
#   1. Which forms are spelled defectively: verbal tense (especially the
#      wayyiqtol), stem (niphal / hiphil / hophal), original yod vs waw verbs?
#   2. Do the QSP and non-QSP scrolls spell the first syllable more fully than
#      the MT? Do the groups of books in the MT differ?
#
# Status (2026-10-10): models fitted; final model M1 (tense only), chosen by
# the author: only effects with credible support (section 3d).
#
# Started from ../../script_ni_hi_pe_yod_cleaned.R. Not carried over:
#   - prefix as a predictor: the prefix is almost always the conjunction W,
#     which every wayyiqtol (283 of 283) and many weqatal forms have; it is a
#     proxy for verbal tense. Prefixes are shown descriptively (2f).
#   - the 25 old candidate models and their Bayes factors.
#
# CHANGES 2026-10-17 (harmonisation of the verb forms, ../TODO.md section 13):
#   - Effect tables and figures with the shared helpers (summarise_effects(),
#     coef_draws(), plot_or(), plot_effects_not_in_final_model()): median, 66%
#     and 95% quantile intervals and pd in every effect table (also the prior
#     sensitivity table); one table format for all verb forms.
#   - Effects not in the final model: the corpus groups of M4b and the halves
#     of 1QIsaa are shown as contrasts with the MT Pentateuch (computed from
#     the draws; the models keep MT other books as reference until the refit);
#     the groups of books of M4b are added.
#   - The robustness fits of M4b (without JSP[ and JBC[; 1QIsaa split) and the
#     variable corpus_isa_split are defined in the script (they were loaded
#     but not fitted here).
#   - Section 4: subsections in order (4e effects not in the final model, 4f
#     random intercepts).
#
# CHANGES 2026-10-17 (refit, ../TODO.md section 13 items 6-10; approved by the
# author 2026-10-17):
#   - MT Pentateuch is the reference level of corpus_group (and of
#     corpus_isa_split), as in every verb form. All models are refitted with
#     the new file prefix 'pey2_' (models, k-folds, prior sensitivity,
#     robustness); the old pey_* fits stay on disk, unused.
#   - Sampler warmup 1000, iter 3000 (default of fit_model() since
#     2026-10-17).
#   - Drop-one k-fold table for the final model M1 (without tense = M0).
#   - Check models with the shared basic predictors: M1s = M1 + has_suffix,
#     M1p = M1 + has_prefix (the prefix may be a proxy for the tense: W +
#     wayyiqtol; rule 3(ii)).
#   - The result comments in section 3d are updated to the refit (pey2_*,
#     run of 2026-10-17/18).
#
# CHANGES 2026-10-19 (book figures for §9.8, BOOK_CHANGES_9.8.md):
#   - Charis and Hebrew in SBL Hebrew (labels of fig_pey_stems_yod).
#   - fig_pey_effects and table_pey_effects: tense contrasts with the
#     imperfect (as in the book and the triliteral hiphil; author,
#     2026-10-19), computed from the draws of M1; new table
#     table_pey_vs_imperfect.csv for Table 9.69. The model keeps the perfect
#     as reference.
#   - New figures fig_pey_jcb_books, fig_pey_jsp_books, fig_pey_jbc_books
#     (Figs. 9.47, 9.48, 9.50) and fig_pey_suffix_groups, fig_pey_prefix_groups
#     (Figs. 9.52, 9.53).
################################################################################


# ==== 0. SETUP ====

library(tidyverse)
library(brms)
library(bayesplot)
library(tidybayes)
library(bayestestR)
library(binom)
library(loo)

source('analysis/paths.R')
ANALYSIS_DIR <- CH09_DIR
VERB_FORM <- 'niph_hiph_pe_yod'
IMAGE_FOLDER <- file.path(ANALYSIS_DIR, VERB_FORM, 'figures')

source(file.path(SHARED_DIR, 'config.R'))      # incl. YOD_VERBS
source(file.path(SHARED_DIR, 'functions.R'))   # incl. shares_by(), plot_shares()

DATASET <- 'niph_hiph_pe_yod.csv'

# ALLOW_FIT = FALSE: only load stored results; stop instead of fitting.
ALLOW_FIT <- FALSE  # all models fitted (runs of 2026-10-17/18, TODO section 13 items 6-10); set TRUE only after approval
options(analysis_verbs.allow_fit = ALLOW_FIT)

# II-tsade verbs: in the hiphil the first radical assimilates to the tsade
# (e.g. HYJG), so there is no vowel in the first syllable to spell.
II_TSADE_VERBS <- c('JY<[', 'JYG[', 'JYQ[', 'JYR[', 'JYT[')

VT_LABELS <- c(perf = 'Perfect', impf = 'Imperfect', wayq = 'Wayyiqtol',
               impv = 'Imperative', infc = 'Infinitive construct',
               infa = 'Infinitive absolute', participle = 'Participle')
VS_LABELS <- c(hif = 'Hiphil', nif = 'Niphal', hof = 'Hophal')


# ==== 1. DATA IMPORT AND PREPARATION ====

dat <- import_bib_data(DATA_FOLDER, DATASET) |>
  remove_ketiv_qere() |>
  add_col_has_suffix() |>
  split_isaiah_scroll() |>
  make_book2_column() |>
  make_scr_book2_column() |>
  make_law_phase_column(LAW_BOOKS, EBH_BOOKS, LBH_BOOKS) |>
  make_law_phase2_column(LAW_BOOKS, EBH_BOOKS, LBH_BOOKS, QSP_SCROLLS, law_phase2_levels) |>
  make_law_phase3_column(QSP_SCROLLS, law_phase3_levels) |>
  make_factor_columns(factor_columns) |>
  droplevels()

# ---- 1a. Documented exclusions ----

exclusions <- tribble(
  ~tf_id,   ~reason,
  1946114,  'HLK[ imperative in 4Q13 (Exodus): difficult reading of the first syllable (the form is analysed in the triliteral hiphil dataset, where the final syllable matters)'
)
dat <- dat |> filter(!tf_id %in% exclusions$tf_id)

# II-tsade verbs kept apart (descriptive only, 2e)
dat_ii_tsade <- dat |> filter(lex %in% II_TSADE_VERBS) |> droplevels()
dat <- dat |> filter(!lex %in% II_TSADE_VERBS) |> droplevels()

# ---- 1b. Predictors ----

# Verbal tense (all participles together); Perfect is the reference level.
dat$vt <- if_else(dat$vt %in% c('ptcp', 'ptca'), 'participle', dat$vt)
dat$vt <- factor(dat$vt, levels = names(VT_LABELS))

# Stem; Hiphil is the reference level.
dat$vs <- factor(dat$vs, levels = names(VS_LABELS))

# Original yod verbs (YOD_VERBS in config.R) vs original waw verbs (incl. HLK[).
# NOTE JBC[ (author, 2026-10-09): stays in the data. Its hiphil perfect is
# mostly written HBJC (9 of 32 full, HWBJC); these forms could also be
# analysed as hiphil of BWC[ ('be ashamed'). JBC[ alone makes the original
# yod verbs look less full in the perfect; see the robustness fit without
# JSP[ and JBC[ (section 3e).
dat$yod_verb <- factor(as.numeric(dat$lex %in% YOD_VERBS))

# Corpus and corpus group (as for the infinitive construct): the MT split by
# group of books, the scrolls one group per corpus; reference MT Pentateuch
# (every verb form; author, 2026-10-15; refit 2026-10-17).
dat$corpus <- factor(case_when(dat$scroll == 'MT' ~ 'MT',
                               dat$scroll %in% QSP_SCROLLS ~ 'QSP',
                               TRUE ~ 'Non-QSP'),
                     levels = c('MT', 'Non-QSP', 'QSP'))
dat$book_group <- factor(case_when(dat$book %in% LAW_BOOKS ~ 'Pentateuch',
                                   dat$book %in% EBH_BOOKS ~ 'Former Prophets',
                                   dat$book %in% LBH_BOOKS ~ 'LBH',
                                   TRUE ~ 'Other'),
                         levels = c('Pentateuch', 'Former Prophets', 'LBH', 'Other'))
dat$corpus_group <- factor(case_when(dat$corpus == 'MT' & dat$book_group == 'Other' ~ 'MT other books',
                                     dat$corpus == 'MT' ~ paste('MT', dat$book_group),
                                     TRUE ~ as.character(dat$corpus)),
                           levels = c('MT Pentateuch', 'MT Former Prophets', 'MT LBH',
                                      'MT other books', 'Non-QSP', 'QSP'))
stopifnot(levels(dat$corpus_group)[1] == 'MT Pentateuch')

# Robustness (section 3e): the two halves of 1QIsaa separate from the other
# QSP scrolls.
dat$corpus_isa_split <- factor(case_when(dat$scroll == '1QisaaI' ~ '1QIsaa I',
                                         dat$scroll == '1QisaaII' ~ '1QIsaa II',
                                         TRUE ~ as.character(dat$corpus_group)),
                               levels = c(levels(dat$corpus_group), '1QIsaa I', '1QIsaa II'))

# Prefix type (descriptive)
dat$prefix_type <- factor(case_when(dat$prefix == '' ~ 'No prefix',
                                    dat$prefix == 'W' ~ 'W (conjunction)',
                                    TRUE ~ 'Other prefix'),
                          levels = c('No prefix', 'W (conjunction)', 'Other prefix'))

# Passage (book, chapter, verse, lexeme), to find parallel forms.
dat$passage <- paste(dat$book, dat$chapter, dat$verse, dat$lex)

dim(dat)
table(dat$corpus, dat$has_vowel_letter)
table(dat$vs, dat$vt)
table(dat$yod_verb, dat$vs)


# ==== 2. EXPLORATORY ANALYSIS ====

# ---- 2a. Verbal tense per corpus ----

tenses <- shares_by(dat, corpus, vt) |>
  mutate(row = factor(VT_LABELS[as.character(vt)], levels = rev(VT_LABELS)))
tenses

p <- plot_shares(tenses, colour_var = 'corpus', dodge_width = 0.7)
p
save_book_figure(p, 'fig_pey_tenses', height = 13)

# ---- 2b. Wayyiqtol: JSP[ (wayyosef) and the other verbs ----

wayq_jsp <- bind_rows(
  shares_by(filter(dat, vt == 'wayq' & lex == 'JSP[')) |> mutate(row = 'Wayyiqtol of JSP['),
  shares_by(filter(dat, vt == 'wayq' & lex != 'JSP[')) |> mutate(row = 'Wayyiqtol of other verbs'),
  shares_by(filter(dat, vt != 'wayq' & lex == 'JSP[')) |> mutate(row = 'JSP[, other tenses'),
  shares_by(filter(dat, vt != 'wayq' & lex != 'JSP[')) |> mutate(row = 'Other verbs, other tenses')
) |>
  mutate(row = factor(row, levels = rev(row)))
wayq_jsp

p <- plot_shares(wayq_jsp)
p
save_book_figure(p, 'fig_pey_wayyiqtol_jsp', height = 6)

# ---- 2c. Stems and original yod verbs ----
# Original yod verbs occur only in the hiphil.

stems_yod <- bind_rows(
  shares_by(dat, vs) |>
    mutate(row = VS_LABELS[as.character(vs)]),
  shares_by(filter(dat, vs == 'hif'), yod_verb) |>
    mutate(row = if_else(yod_verb == 1, paste('Hiphil: verbs with historical', heb_md('י')),
                         paste('Hiphil: verbs with historical', heb_md('ו')))),
  shares_by(filter(dat, vs == 'hif' & yod_verb == 1 & lex != 'JBC['), yod_verb) |>
    mutate(row = paste('Hiphil: verbs with historical', heb_md('י'), 'without', heb_md('יבש')))
) |>
  mutate(row = factor(row, levels = rev(row)))
stems_yod

p <- plot_shares(stems_yod) + markdown_y()
p
save_book_figure(p, 'fig_pey_stems_yod', height = 7)

# Original yod verbs per tense: the low perfect is JBC[ (HBJC vs HWBJC)
shares_by(filter(dat, yod_verb == 1), vt, lex) |> print(n = 40)

# ---- 2c2. Three lexemes per MT book (for the book, Figs. 9.47, 9.48, 9.50) ----
# JCB[ (yashav), JSP[ (yasaf) and JBC[ (yavesh) in the MT, books in canonical
# order (the order of the MT rows in the data); Qoheleth for Ecclesiastes.

mt_book_order <- unique(dat$book2[dat$corpus == 'MT'])
lexeme_books <- function(lexeme, name) {
  tab <- dat |>
    filter(lex == lexeme, corpus == 'MT') |>
    mutate(book2 = factor(book2, levels = mt_book_order)) |>
    shares_by(book2) |>
    mutate(row = fct_rev(fct_recode(droplevels(book2), Qoheleth = 'Ecclesiastes')))
  p <- plot_shares(tab)
  save_book_figure(p, name, height = 2 + 0.45 * nrow(tab))
  tab
}
lexeme_books('JCB[', 'fig_pey_jcb_books')
lexeme_books('JSP[', 'fig_pey_jsp_books')
lexeme_books('JBC[', 'fig_pey_jbc_books')

# ---- 2d. Lexemes (20 forms or more) ----

lexemes <- shares_by(dat, lex) |>
  filter(n >= 20) |>
  arrange(mean) |>
  mutate(row = factor(lex, levels = lex))
p <- plot_shares(lexemes)
p
save_book_figure(p, 'fig_pey_lexemes', height = 12)
write_csv(select(shares_by(dat, lex, yod_verb), -any_of('row')),
          file.path(IMAGE_FOLDER, 'table_pey_lexemes.csv'))

# ---- 2e. Groups of books, with and without the wayyiqtol ----
# The MT Former Prophets are less full because of their many wayyiqtol forms.

groups_wayq <- dat |>
  mutate(tense = factor(if_else(vt == 'wayq', 'Wayyiqtol', 'Other tenses'),
                        levels = c('Other tenses', 'Wayyiqtol'))) |>
  shares_by(law_phase3, tense) |>
  mutate(row = fct_rev(law_phase3))
groups_wayq

p <- plot_shares(groups_wayq, colour_var = 'tense', dodge_width = 0.6,
                 colours = c(BOOK_BLUE, BOOK_ORANGE))
p
save_book_figure(p, 'fig_pey_groups', height = 12)

# II-tsade verbs (excluded; the yod assimilates to the tsade)
shares_by(dat_ii_tsade, lex)

# ---- 2f. Prefixes and suffixes (descriptive) ----

table(dat$prefix_type, dat$vt)
affixes <- bind_rows(
  shares_by(dat, prefix_type) |> mutate(row = as.character(prefix_type)),
  shares_by(dat, has_suffix) |>
    mutate(row = if_else(has_suffix == 1, 'With suffix', 'Without suffix'))
) |>
  mutate(row = factor(row, levels = rev(row)))
affixes
write_csv(select(affixes, row, full, n, mean, lower, upper),
          file.path(IMAGE_FOLDER, 'table_pey_affixes.csv'))

# Suffix and prefix per document group (for the book, Figs. 9.52 and 9.53)
affix_groups <- function(var, labels, name) {
  tab <- dat |>
    mutate(affix = factor(if_else(.data[[var]] == 1, labels[2], labels[1]), levels = labels)) |>
    shares_by(law_phase3, affix) |>
    mutate(row = fct_rev(law_phase3))
  p <- plot_shares(tab, colour_var = 'affix', dodge_width = 0.6,
                   colours = c(BOOK_BLUE, BOOK_ORANGE))
  save_book_figure(p, name, height = 12)
  tab
}
affix_groups('has_suffix', c('Without suffix', 'With suffix'), 'fig_pey_suffix_groups')
affix_groups('has_prefix', c('Without prefix', 'With prefix'), 'fig_pey_prefix_groups')

# ---- 2g. Parallel passages: the same form in the MT and in a scroll ----

# Pairs the n-th scroll form with the n-th MT form of the same lexeme in the
# same verse (parallel_forms() in functions.R).
parallel_table <- parallel_forms(dat, occ = raw_occurrences('niph_hiph_pe_yod')) |>  # raw-text pairing, 2026-11-05
  select(passage, scroll, corpus, lex, vt, g_cons, mt_g_cons, has_vowel_letter, mt_full, pattern)
parallel_table |> count(corpus, pattern)
write_csv(parallel_table, file.path(IMAGE_FOLDER, 'table_pey_parallel_passages.csv'))

p <- parallel_table |>
  mutate(corpus = droplevels(corpus)) |>
  count(corpus, pattern) |>
  complete(corpus, pattern, fill = list(n = 0)) |>
  mutate(pattern = factor(pattern, levels = c('MT fuller', 'both defective',
                                              'both full', 'scroll fuller'))) |>
  ggplot(aes(y = pattern, x = n)) +
  geom_col(fill = BOOK_BLUE, width = 0.6) +
  geom_text(aes(label = n), hjust = -0.3, size = 3, colour = BOOK_INK_2) +
  facet_wrap(~ corpus) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.25))) +
  coord_cartesian(clip = 'off') +
  labs(x = 'Number of parallel forms', y = NULL) +
  theme_book() +
  theme(panel.grid.major.y = element_blank(),
        panel.spacing.x = unit(1.2, 'cm'))
p
save_book_figure(p, 'fig_pey_parallel_passages', height = 6)

# The parallel forms where the MT is fuller than the non-QSP scroll
parallel_table |> filter(pattern == 'MT fuller') |> print(n = 40)


# ==== 3. DATA MODELLING ====
#
# Decisions (author, 2026-10-09; ../TODO.md section 9):
#   - Random part nested: (1 | scr_book2/lex).
#   - Priors normal(0, 2.5) on intercept and coefficients, exponential(1) on
#     the SDs. Prior sensitivity: the final model is refitted with sd 1.5 and 4
#     and the estimates are compared (no Bayes factors: bridge sampling is not
#     reliable for models with many random intercepts).
#   - Model choice by grouped 5-fold cross-validation.
#   - Prefix: proxy for tense (the conjunction W); only tested in the check
#     model M1p (2026-10-17), with the suffix in M1s.
#   - JBC[ stays in the data (see the note in section 1b).

PRIOR_SD <- 2.5
priors <- book_priors(PRIOR_SD)

# ---- 3a. Prior predictive check ----

model_prior_only <- fit_model('pey2_M5_prior_only.rds',
                              has_vowel_letter ~ vt + vs + yod_verb + corpus_group +
                                vt:yod_verb + (1 | scr_book2/lex),
                              dat, priors, sample_prior = 'only')

prior_shares <- posterior_predict(model_prior_only, ndraws = 4000) |> rowMeans()
p <- tibble(share = prior_shares) |>
  ggplot(aes(x = share)) +
  geom_histogram(binwidth = 0.025, boundary = 0, fill = BOOK_GREY, colour = 'white',
                 linewidth = 0.3) +
  geom_vline(xintercept = mean(as.numeric(as.character(dat$has_vowel_letter))),
             colour = BOOK_BLUE, linewidth = 0.8) +
  scale_x_continuous(labels = scales::percent) +
  labs(x = 'Share of full spellings in a simulated dataset (prior only)',
       y = 'Number of simulations', caption = 'Blue line: observed share.') +
  theme_book()
p
save_book_figure(p, 'check_pey_prior_predictive', height = 8)
rm(model_prior_only); gc()

# ---- 3b. Candidate models ----
# Fitted once and stored; loaded one at a time (memory-saving helpers).

model_specs <- list(
  M0  = has_vowel_letter ~ 1 + (1 | scr_book2/lex),
  M1  = has_vowel_letter ~ vt + (1 | scr_book2/lex),
  M2  = has_vowel_letter ~ vt + vs + (1 | scr_book2/lex),
  M3  = has_vowel_letter ~ vt + vs + yod_verb + (1 | scr_book2/lex),
  M4a = has_vowel_letter ~ vt + vs + yod_verb + corpus + (1 | scr_book2/lex),
  M4b = has_vowel_letter ~ vt + vs + yod_verb + corpus_group + (1 | scr_book2/lex),
  M5  = has_vowel_letter ~ vt + vs + yod_verb + corpus_group + vt:yod_verb +
          (1 | scr_book2/lex),
  n10 = has_vowel_letter ~ vt * yod_verb + (1 | scr_book2/lex),
  # Check models with the shared basic predictors (2026-10-17)
  M1s = has_vowel_letter ~ vt + has_suffix + (1 | scr_book2/lex),
  M1p = has_vowel_letter ~ vt + has_prefix + (1 | scr_book2/lex)
)
model_file <- function(id, scale_b = PRIOR_SD) {
  if (scale_b == PRIOR_SD) paste0('pey2_', id, '.rds')
  else paste0('pey2_', id, '_prior', scale_b, '.rds')
}
ensure_model <- function(id, scale_b = PRIOR_SD, formula = model_specs[[id]], data = dat) {
  if (!file.exists(file.path(MODEL_FOLDER, model_file(id, scale_b)))) {
    fit_model(model_file(id, scale_b), formula, data,
              book_priors(scale_b, has_fixed = id != 'M0'))
    gc()
  }
  invisible(model_file(id, scale_b))
}

walk(names(model_specs), ensure_model)

for (id in names(model_specs)) {
  cat('\n====', id, '====\n')
  m <- load_model(model_file(id))
  print(fixef(m))
  rm(m); gc()
}

# ---- 3c. Grouped 5-fold cross-validation ----

set.seed(2026)
folds <- loo::kfold_split_grouped(K = 5, x = as.character(dat$scr_book2))

kfolds <- map(set_names(names(model_specs)),
              \(id) kfold_lazy(model_file(id), paste0('pey2_', id, '_k5'), folds))
kfold_comparison <- loo_compare(kfolds)
print(kfold_comparison)
kfold_table <- as.data.frame(kfold_comparison) |>
  rownames_to_column('model') |>
  select(model, elpd_diff, se_diff, elpd_kfold, se_elpd_kfold)
write_csv(kfold_table, file.path(IMAGE_FOLDER, 'table_pey_kfold.csv'))

# Final model M1 against the model without its effect (rule 4): M1 has only
# the tense, so the model without it is M0.
drop_one <- drop_one_kfold_table(kfolds, 'M1', c('verbal tense' = 'M0'))
drop_one
write_csv(drop_one, file.path(IMAGE_FOLDER, 'table_pey_kfold_drop_one.csv'))

# ---- 3d. Final model: M1 (tense only) ----
# Results of the refit (pey2_*, reference MT Pentateuch, run of 2026-10-17/18;
# 5-fold grouped k-fold, elpd difference to the best model, SE): n10 0;
# M5 -0.2 (5.6); M4a -8.9 (4.9); M4b -11.8 (6.3); M3 -13.8 (3.4);
# M1p -15.3 (5.5); M2 -16.3 (4.9); M1 -16.6 (5.2); M1s -26.2 (6.7);
# M0 -80.1 (11.1).
# Direct comparisons: M1 vs M2 (+ stem) -0.3 (1.6); M3 vs M4a (+ corpus)
# -4.9 (3.7); M4a vs M4b (corpus group) +2.9 (3.6); M1 vs M0 +63.5 (10.3);
# M1 vs M1p (+ prefix) -1.3 (1.7); M1 vs M1s (+ suffix) +9.6 (3.3).
# Check models (refit): prefix (M1p) -0.38 (-0.85 to 0.10), pd 0.94, not
# credible. Suffix or ending (M1s) -0.73 (-1.19 to -0.28), pd 1.00: credible,
# but M1s predicts clearly worse than M1 in the k-fold (-9.6, SE 3.3).
# Suffix (author, 2026-10-18): not in the final model. Credible, but a
# clear k-fold loss; descriptively suffixed forms are as full as the others
# (87% vs 86%; within lexemes about -3 points, mostly JDH[, JRH[, JKX[, JR>[).
# Author's decision (2026-10-10): the final model contains only effects with
# credible support. Only tense has a credible effect:
#   - stem: no gain in prediction; niphal 0.46 (-0.35 to 1.31), hophal 0.42
#     (-0.85 to 1.88) in M4a (refit); the higher share of the niphal comes
#     from its tenses (only perfect and participle).
#   - original yod verb: the effect and the tense x yod interaction rest on
#     JBC[ (M4b without JSP[ and JBC[: -0.56, -1.44 to 0.41, refit). In the
#     nested random part JBC[ gets its own intercept in every book (author's
#     suggestion). The gain of n10/M5 in k-fold comes from predicting JBC[ in
#     left-out books, not from a general rule for yod verbs.
#   - corpus: non-QSP 0.10 (-0.71 to 0.96), QSP 0.91 (-0.23 to 2.12), pd 0.94
#     (M4a, refit); no clear gain in prediction.
# These effects are reported in section 4f with the estimates of the
# comparison models.
# Where does the k-fold gain of n10 (tense x yod verb) over M1 come from?
# Pointwise elpd differences summed per lexeme (refit): 16.5 of 16.6 come from
# JBC[ alone (other yod verbs -0.5, waw verbs +0.6) (rule 3(i): a lexeme
# effect, not a rule for the yod verbs).
gain_by_lexeme <- tibble(lex = dat$lex, yod_verb = dat$yod_verb,
                         gain = kfolds[['n10']]$pointwise[, 'elpd_kfold'] -
                           kfolds[['M1']]$pointwise[, 'elpd_kfold']) |>
  group_by(lex, yod_verb) |>
  summarise(n = n(), gain = sum(gain), .groups = 'drop') |>
  arrange(-abs(gain))
gain_by_lexeme
write_csv(gain_by_lexeme, file.path(IMAGE_FOLDER, 'table_pey_kfold_gain_n10_by_lexeme.csv'))

FINAL_ID <- 'M1'
final_formula <- model_specs[[FINAL_ID]]
final_model <- load_model(model_file(FINAL_ID))
summary(final_model)

# ---- 3e. Prior sensitivity and robustness ----

# Prior sensitivity: the final model with sd 1.5 and 4
walk(c(1.5, 4), \(scale_b) ensure_model(FINAL_ID, scale_b))

# Robustness: the final model without JSP[ and JBC[; the comparison model M4b
# (used in section 4f) without JSP[ and JBC[ and with the halves of 1QIsaa
# separate.
dat_no_jsp_jbc <- filter(dat, !lex %in% c('JSP[', 'JBC[')) |> droplevels()
robustness_specs <- list(
  no_jsp_jbc     = list(file = paste0('pey2_', FINAL_ID, '_no_JSP_JBC.rds'),
                        formula = final_formula, data = dat_no_jsp_jbc),
  m4b_no_jsp_jbc = list(file = 'pey2_M4b_no_JSP_JBC.rds',
                        formula = model_specs$M4b, data = dat_no_jsp_jbc),
  m4b_isa_split  = list(file = 'pey2_M4b_1QIsaa_split.rds',
                        formula = update(model_specs$M4b, . ~ . - corpus_group + corpus_isa_split),
                        data = dat)
)
walk(robustness_specs, function(r) {
  if (!file.exists(file.path(MODEL_FOLDER, r$file))) {
    fit_model(r$file, r$formula, r$data, priors)
    gc()
  }
})


# ==== 4. DATA VISUALISATION ====

# ---- 4a. Table of fixed effects ----

fixed_table <- make_fixed_effects_table(final_model)
fixed_table
write_csv(rownames_to_column(fixed_table, 'parameter'),
          file.path(IMAGE_FOLDER, 'table_pey_fixed_effects.csv'))

# ---- 4b. Effects (odds ratios) ----
# Reference: perfect. Median, 66% and 95% quantile intervals and pd
# (summarise_effects() in functions.R).

effect_labels <- c(
  b_vtimpf                       = 'Imperfect vs perfect',
  b_vtwayq                       = 'Wayyiqtol vs perfect',
  b_vtimpv                       = 'Imperative vs perfect',
  b_vtinfc                       = 'Infinitive construct vs perfect',
  b_vtinfa                       = 'Infinitive absolute vs perfect',
  b_vtparticiple                 = 'Participle vs perfect',
  b_vsnif                        = 'Niphal vs hiphil',
  b_vshof                        = 'Hophal vs hiphil',
  b_yod_verb1                    = 'Original yod verb vs waw verb',
  b_corpusNonMQSP                = 'Non-QSP scrolls vs MT',
  b_corpusQSP                    = 'QSP scrolls vs MT',
  b_has_suffix1                  = 'Suffix or ending (vs none)',
  b_has_prefix1                  = 'Prefix (vs none)')
# coef_draws() takes c(label = parameter)
label_coefs <- function(parameters) {
  parameters <- intersect(names(effect_labels), parameters)
  set_names(parameters, effect_labels[parameters])
}

# For the book the tense effects are contrasts with the imperfect, as in the
# book and in the triliteral hiphil (author, 2026-10-19): b_vt[x] - b_vtimpf
# from the draws of M1 (the model itself keeps the perfect as reference).
vs_imperfect <- function(model) {
  d <- as_draws_df(model)
  coef_or_0 <- function(name) if (name %in% names(d)) d[[name]] else 0
  imap_dfr(VT_LABELS[names(VT_LABELS) != 'impf'], \(label, vt)
    tibble(label = paste(label, 'vs imperfect'), parameter = paste0('b_vt', vt),
           value = coef_or_0(paste0('b_vt', vt)) - d$b_vtimpf))
}
effects <- vs_imperfect(final_model) |>
  mutate(label = factor(label, levels = rev(unique(label)))) |>
  summarise_effects(label, parameter)
effects
write_csv(effects, file.path(IMAGE_FOLDER, 'table_pey_effects.csv'))

# Table for the book (Table 9.69): posterior mean, error and 95% interval of
# the intercept of the imperfect and the contrasts with the imperfect.
d_m1 <- as_draws_df(final_model)
book_table <- bind_rows(
  tibble(label = 'Intercept (imperfect)', value = d_m1$b_Intercept + d_m1$b_vtimpf),
  vs_imperfect(final_model) |> select(label, value)) |>
  group_by(label = factor(label, levels = unique(label))) |>
  summarise(estimate = mean(value), est_error = sd(value),
            lower = quantile(value, 0.025), upper = quantile(value, 0.975),
            pd = max(mean(value > 0), mean(value < 0)))
book_table
write_csv(book_table, file.path(IMAGE_FOLDER, 'table_pey_vs_imperfect.csv'))

p <- plot_or(effects, label)
p
save_book_figure(p, 'fig_pey_effects', height = 7)

# ---- 4c. Predicted probability of full spelling per tense ----
# Population level (re_formula = NA): a typical scroll-book and lexeme.

newdata <- tibble(vt = factor(names(VT_LABELS), levels = levels(dat$vt)),
                  condition = factor(VT_LABELS, levels = rev(VT_LABELS)))

predicted <- newdata |>
  add_epred_draws(final_model, re_formula = NA) |>
  group_by(condition) |>
  median_qi(.epred, .width = c(0.66, 0.95))
predicted
write_csv(predicted, file.path(IMAGE_FOLDER, 'table_pey_predicted.csv'))

p <- predicted |>
  ggplot(aes(y = condition, x = .epred, xmin = .lower, xmax = .upper)) +
  geom_pointinterval(colour = BOOK_BLUE, point_size = 2.5,
                     interval_size_range = c(0.8, 2)) +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25),
                     labels = scales::percent) +
  labs(x = 'Predicted probability of full spelling', y = NULL,
       caption = paste(OR_CAPTION, 'Typical book and lexeme.', sep = '\n')) +
  theme_book()
p
save_book_figure(p, 'fig_pey_predicted', height = 7)

# ---- 4d. Prior sensitivity and robustness of the tense effects ----

key_parameters <- intersect(c('b_vtimpf', 'b_vtwayq', 'b_vtimpv', 'b_vtinfc',
                              'b_vtparticiple'),
                            variables(final_model))

# Draws (long format) of a stored model, loaded and released one at a time.
draws_from <- function(file, variant, parameters = key_parameters) {
  m <- load_model(file)
  out <- coef_draws(m, set_names(parameters)) |>
    select(-label) |>
    mutate(variant = variant)
  rm(m); gc()
  out
}

variant_levels <- c('prior sd 1.5', 'prior sd 2.5 (final model)', 'prior sd 4',
                    'without JSP[ and JBC[')
sensitivity <- bind_rows(
  draws_from(model_file(FINAL_ID, 1.5), 'prior sd 1.5'),
  draws_from(model_file(FINAL_ID), 'prior sd 2.5 (final model)'),
  draws_from(model_file(FINAL_ID, 4), 'prior sd 4'),
  draws_from(robustness_specs$no_jsp_jbc$file, 'without JSP[ and JBC[')
) |>
  mutate(label = factor(effect_labels[parameter], levels = effect_labels),
         variant = factor(variant, levels = rev(variant_levels))) |>
  summarise_effects(label, variant) |>
  mutate(label = droplevels(label))
sensitivity
write_csv(sensitivity, file.path(IMAGE_FOLDER, 'table_pey_sensitivity_robustness.csv'))

p <- plot_or(sensitivity, variant) +
  facet_grid(rows = vars(label), scales = 'free_y', space = 'free_y') +
  theme(strip.text.y = element_text(angle = 0, hjust = 0, size = 8))
p
save_book_figure(p, 'fig_pey_robustness', width = 18, height = 16)

# ---- 4e. Effects not in the final model (no credible effect) ----
# Estimates from the comparison models: stem, original yod verb and corpus
# from M4a (tense + stem + yod verb + corpus, reference MT); the groups of
# books from M4b (tense + stem + yod verb + corpus group); the yod verb without
# JSP[ and JBC[ and the halves of 1QIsaa from the robustness fits of M4b;
# the suffix and the prefix from the check models M1s and M1p.
# The corpus groups are contrasts with the MT Pentateuch. Since the refit
# (pey2_*) the MT Pentateuch is the reference level, so the contrasts are the
# coefficients themselves; the function also works for fits with another
# reference level (b_group - b_MTPentateuch, a missing coefficient = 0).

# Draws of contrasts with the MT Pentateuch. `groups`: c(label = coefficient
# suffix of the level).
pentateuch_contrasts <- function(file, model, prefix, groups) {
  m <- load_model(file)
  d <- as_draws_df(m)
  rm(m); gc()
  coef_or_0 <- function(name) if (name %in% names(d)) d[[name]] else 0
  ref_name <- paste0(prefix, 'MTPentateuch')
  ref <- coef_or_0(ref_name)
  imap_dfr(groups, function(coef, label) {
    name <- paste0(prefix, coef)
    tibble(label = label, model = model,
           parameter = if (ref_name %in% names(d)) paste(name, '-', ref_name) else name,
           value = coef_or_0(name) - ref)
  })
}

# Suffix (M1s) and prefix (M1p) are shown here as effects not in the final
# model: the prefix is not credible (and a proxy for the wayyiqtol, rule
# 3(ii)); the suffix is credible but makes the k-fold clearly worse, so the
# author kept M1 (2026-10-18).

m4a <- load_model(model_file('M4a'))
other_draws <- bind_rows(
  coef_draws(m4a, label_coefs(c('b_vsnif', 'b_vshof', 'b_yod_verb1',
                                'b_corpusNonMQSP', 'b_corpusQSP'))) |>
    mutate(model = 'M4a'),
  draws_from(robustness_specs$m4b_no_jsp_jbc$file, NA, parameters = 'b_yod_verb1') |>
    transmute(label = 'Original yod verb vs waw verb, without JSP[ and JBC[',
              model = 'M4b without JSP[ and JBC[', parameter, value),
  pentateuch_contrasts(model_file('M4b'), 'M4b', 'b_corpus_group',
                       c('MT Former Prophets vs MT Pentateuch' = 'MTFormerProphets',
                         'MT LBH vs MT Pentateuch'             = 'MTLBH',
                         'MT other books vs MT Pentateuch'     = 'MTotherbooks',
                         'Non-QSP scrolls vs MT Pentateuch'    = 'NonMQSP',
                         'QSP scrolls vs MT Pentateuch'        = 'QSP')),
  pentateuch_contrasts(robustness_specs$m4b_isa_split$file, 'M4b, 1QIsaa split',
                       'b_corpus_isa_split',
                       c('1QIsaa I vs MT Pentateuch'           = '1QIsaaI',
                         '1QIsaa II vs MT Pentateuch'          = '1QIsaaII',
                         'Other QSP scrolls vs MT Pentateuch'  = 'QSP')),
  draws_from(model_file('M1s'), NA, parameters = 'b_has_suffix1') |>
    transmute(label = effect_labels[['b_has_suffix1']], model = 'M1s', parameter, value),
  draws_from(model_file('M1p'), NA, parameters = 'b_has_prefix1') |>
    transmute(label = effect_labels[['b_has_prefix1']], model = 'M1p', parameter, value)
)
rm(m4a); gc()

other_label_order <- c('Niphal vs hiphil', 'Hophal vs hiphil',
                       'Original yod verb vs waw verb',
                       'Original yod verb vs waw verb, without JSP[ and JBC[',
                       'Non-QSP scrolls vs MT', 'QSP scrolls vs MT',
                       'MT Former Prophets vs MT Pentateuch', 'MT LBH vs MT Pentateuch',
                       'MT other books vs MT Pentateuch', 'Non-QSP scrolls vs MT Pentateuch',
                       'QSP scrolls vs MT Pentateuch',
                       '1QIsaa I vs MT Pentateuch', '1QIsaa II vs MT Pentateuch',
                       'Other QSP scrolls vs MT Pentateuch',
                       'Suffix or ending (vs none)', 'Prefix (vs none)')
other_effects <- other_draws |>
  mutate(label = factor(label, levels = rev(other_label_order))) |>
  summarise_effects(label, model, parameter)
other_effects
write_csv(other_effects, file.path(IMAGE_FOLDER, 'table_pey_effects_not_in_final_model.csv'))

p <- plot_effects_not_in_final_model(
  other_effects,
  caption = paste('From the comparison models M4a (vs MT), M4b (vs MT Pentateuch),',
                  'M1s (suffix) and M1p (prefix).',
                  OR_CAPTION, sep = '\n'))
p
save_book_figure(p, 'fig_pey_effects_not_in_final_model', width = 18, height = 12)

# ---- 4f. Random intercepts of the books (check) ----

p <- plot_random_intercepts(final_model, 'scr_book2', text_size = 5) + theme_book()
save_book_figure(p, 'check_pey_random_books', height = 24)


# ==== 5. MODEL VERIFICATION ====

# Convergence, trace and density plots, posterior predictive checks, LOO (for
# completeness; unreliable with the nested structure) and Bayes R2. The
# in-sample classification it prints is optimistic.
verification <- verify_model(final_model, IMAGE_FOLDER, 'check_pey')

# Observed vs predicted share of full spellings per group of books, per tense
# and for the lexemes JSP[ and JBC[ vs the rest.
dat$vt_label <- factor(VT_LABELS[as.character(dat$vt)], levels = VT_LABELS)
dat$lexeme_check <- factor(case_when(dat$lex == 'JSP[' ~ 'JSP[',
                                     dat$lex == 'JBC[' ~ 'JBC[',
                                     TRUE ~ 'Other lexemes'),
                           levels = c('JSP[', 'JBC[', 'Other lexemes'))

ppc_groups <- group_ppc(final_model, dat, 'law_phase3')
ppc_groups
save_book_figure(plot_ppc(ppc_groups), 'check_pey_ppc_groups', height = 8)

ppc_tenses <- group_ppc(final_model, dat, 'vt_label')
ppc_tenses
save_book_figure(plot_ppc(ppc_tenses), 'check_pey_ppc_tenses', height = 8)

ppc_lexemes <- group_ppc(final_model, dat, 'lexeme_check')
ppc_lexemes
save_book_figure(plot_ppc(ppc_lexemes), 'check_pey_ppc_lexemes', height = 5)
