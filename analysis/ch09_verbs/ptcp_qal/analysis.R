################################################################################
# ptcp_qal/analysis.R
#
# Dataset:  ptcp_qal.csv - qal passive participle in the MT and the Dead Sea
#           Scrolls. The Samaritan Pentateuch forms in the dataset (317) are
#           left out (author, 2026-10-09).
# Outcome:  has_vowel_letter (1 = full spelling, e.g. KTWB; 0 = defective, KTB).
# Questions:
#   1. Do the QSP and non-QSP scrolls spell the participle more fully than the
#      MT?
#   2. Within the MT: do the groups of books differ (Pentateuch, Former
#      Prophets, LBH, other books)?
#   3. How does the ending affect the spelling (none, fem. sg. -H/-T, masc. pl.
#      -JM/-J, fem. pl. -WT, pronominal suffix), and do the scrolls differ from
#      the MT in this?
#   4. Do ayin-ayin (ע-ע) and III-he (ל-ה) verbs behave differently?
#
# Status (2026-10-17): rebuilt on the design of infc_qal_triliteral and
# infc_qal_lamed_he; all models fitted 2026-10-10 on the old data, refit on
# the data of 2026-10-16 approved 2026-10-17 (see REPORT.md). Final model
# M7 (2026-10-11): only credible effects (../CLAUDE.md); the non-QSP long
# ending (not credible) and the prefix (rests on PQD[) are reported in
# fig_ptcp_effects_not_in_final_model.
#
# Started from ../../script_ptcp_cleaned.R. Changes w.r.t. that script:
#   - has_suffix (pronominal suffix OR nominal ending, 610 forms of which 70
#     with a pronominal suffix) replaced by a 5-level factor `ending` (author,
#     2026-10-09): the endings behave very differently (MT: none 94% full,
#     fem. sg. 89%, masc. pl. 66%, fem. pl. -WT 14%, pronominal suffix 13%).
#   - Corpus differences in the effect of the ending: the QSP scrolls keep the
#     long endings full (masc. pl. 25/27, -WT 6/7). Modelled with two dummies
#     (non-QSP / QSP x long ending) instead of law_phase3 interactions.
#   - corpus_group (MT split by group of books, scrolls one group per corpus)
#     instead of law_phase3; explicit priors with sensitivity; grouped k-fold
#     instead of LOO (451 of 620 book x lexeme groups contain one form).
#   - PQD[ (88 forms, 25% full; 66 of the 246 defective forms, mostly
#     construct plurals in Numbers) stays an ordinary lexeme (author,
#     2026-10-09); robustness fit without PQD[.
#   - I-yod not modelled (22 forms); prefix only as an additive check (M6).
#   - The 19 old candidate models and their recorded Bayes factors (fitted on
#     old formulas, m3/m5/m9 with law_phase2) are replaced by the model set in
#     section 3; the old final model m19 is kept for comparison.
#   - Postponed (author, 2026-10-09; ../TODO.md): the Isaiah manuscripts model,
#     the MT Pentateuch books model and the crossed vs nested appendix.
#   - Book figures (fig_ptcp_*) replace the explore_* plots.
#   - New data (2026-10-16, preprocessing): `ending` from the column nme_type.
#     8 MT fem. pl. written -T were counted as fem. sg.; 4 scroll plural
#     constructs (1QIsaa Isa 28:1, 35:10, 51:11; 4Q108 Song 3:8) had no ending
#     (now masc. pl.; the three 1QIsaa forms get a QSP long ending). The
#     model files get the prefix 'ptcp_d2_', so that the fits on the old data
#     (ptcp_*.rds) are not loaded by mistake; the models must be refitted.
#
# CHANGES 2026-10-17 (harmonisation of the verb forms, ../TODO.md section 13):
#   - Bayes factors removed (code of the old section 3d and REPORT.md).
#   - Effect summaries with the shared helpers of ../functions.R
#     (summarise_effects, coef_draws, plot_or): median with 66% and 95%
#     quantile intervals (author, 2026-10-17) instead of HDI, plus pd. The
#     effect tables are now in wide format (.lower/lower66/upper66/.upper).
#   - Corpus groups shown as contrasts vs MT Pentateuch, computed from the
#     draws, so the tables do not depend on the reference level of the model
#     (MT other books now; MT Pentateuch planned for the refit, TODO section
#     13 item 6).
#   - Prior sensitivity of the final model M7 (sd 1.5 and 4) in section 3d,
#     shown in the robustness figure; fitted in the approved refit.
#   - Robustness figure faceted per effect (as ptca); all robustness fits
#     shown for every key effect.
#   - Label of the fem. pl. ending '-WT/-T' everywhere (from ENDING_LABELS).
#
# CHANGES 2026-10-17 (refit, approved by the author; ../TODO.md section 13
# items 6-10):
#   - All models refitted on the data of 2026-10-16 (prefix 'ptcp_d2_').
#   - Reference level of corpus_group: MT Pentateuch (was MT other books).
#   - Sampler: warmup 1000, iter 3000 (default of fit_model() from 2026-10-17;
#     the old fits used 2000/6000).
#   - Prior sensitivity of the final model M7 (sd 1.5 and 4) fitted.
#   - The result comments in section 3e and 4b are updated to the refit
#     (ptcp_d2_*, run of 2026-10-17/18).
#
# CHANGES 2026-10-19 (book §9.3, BOOK_CHANGES_9.3.md; no fitting):
#   - Book labels: endings in Hebrew (ENDING_LABELS_BOOK), ע״ע / ל״ה in SBL
#     Hebrew, 'MT Other' in fig_ptcp_endings, fig_ptcp_effects and
#     fig_ptcp_predicted; the CSV tables get plain labels (md_to_csv).
#     table_ptcp_effects.csv keeps the model labels.
#   - fig_ptcp_effects: fewer x breaks (1/4096 ... 256; the labels overlapped).
#   - New figures for the book: fig_ptcp_groups_all (Fig. 9.12),
#     fig_ptcp_prefix_groups, _ayay_groups, _iiih_groups (Figs. 9.15-9.17),
#     fig_ptcp_random_docs (two panels), _random_genesis and _random_ktb_brk
#     (Figs. 9.20-9.22, from M7), each with a CSV table.
#
# CHANGES 2026-11-04 (refit on the data of 2026-11-03, approved by the author;
# ../TODO.md section 24):
#   - DSS segmentation fixes in hebrew_spelling_variation (6cbee1a..37b4f01):
#     49 scroll forms get the fem. sg. ending H (e.g. NVWJH, Isa 5:25; was
#     none); 4 forms drop out and 2 come in through the reconstruction filter
#     (1,198 forms). has_vowel_letter is unchanged.
#   - Model files get the prefix 'ptcp_d3_'; the ptcp_d2_* fits stay for
#     comparison. The result comments in 3e and 4b describe the ptcp_d3_
#     refit (updated 2026-11-04 after the author confirmed FINAL_ID M7).
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
VERB_FORM <- 'ptcp_qal'
IMAGE_FOLDER <- file.path(ANALYSIS_DIR, VERB_FORM, 'figures')

source(file.path(SHARED_DIR, 'config.R'))
source(file.path(SHARED_DIR, 'functions.R'))

DATASET <- 'ptcp_qal.csv'

# ALLOW_FIT = FALSE: only load stored results; stop instead of fitting.
ALLOW_FIT <- FALSE  # all models fitted (runs of 2026-10-17/18, TODO section 13 items 6-10); set TRUE only after approval
options(analysis_verbs.allow_fit = ALLOW_FIT)
RUN_KFOLD <- TRUE


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
  filter(scroll != 'SP') |>                 # SP not part of this analysis
  droplevels()

# ---- 1a. Predictors ----

dat$corpus <- factor(case_when(dat$scroll == 'MT' ~ 'MT',
                               dat$scroll %in% QSP_SCROLLS ~ 'QSP',
                               TRUE ~ 'Non-QSP'),
                     levels = c('MT', 'Non-QSP', 'QSP'))

dat$book_group <- factor(case_when(dat$book %in% LAW_BOOKS ~ 'Pentateuch',
                                   dat$book %in% EBH_BOOKS ~ 'Former Prophets',
                                   dat$book %in% LBH_BOOKS ~ 'LBH',
                                   TRUE ~ 'Other'),
                         levels = c('Pentateuch', 'Former Prophets', 'LBH', 'Other'))

# Corpus group (6 levels), as in the other verb forms. Reference level: MT
# Pentateuch (../CLAUDE.md; switched in the refit of 2026-10-17).
dat$corpus_group <- factor(case_when(dat$corpus == 'MT' & dat$book_group == 'Other' ~ 'MT other books',
                                     dat$corpus == 'MT' ~ paste('MT', dat$book_group),
                                     TRUE ~ as.character(dat$corpus)),
                           levels = c('MT Pentateuch', 'MT Former Prophets', 'MT LBH',
                                      'MT other books', 'Non-QSP', 'QSP'))

# Ending (author, 2026-10-09). A pronominal suffix takes precedence over the
# nominal ending it is attached to (e.g. PQDJHM). There are no he-locale forms.
# The nominal ending comes from the column nme_type of the dataset
# (preprocessing of 2026-10-16): the written ending nme cannot distinguish a
# fem. pl. without waw (-T, e.g. VL>T Gen 30:35; 8 MT forms) from a fem. sg.
dat$ending <- factor(if_else(dat$has_prs == 1, 'pron_suffix', dat$nme_type),
                     levels = c('none', 'fem_sg', 'masc_pl', 'fem_pl', 'pron_suffix'))
stopifnot(!anyNA(dat$ending), all(dat$has_hloc == 0))
ENDING_LABELS <- c(none = 'No ending', fem_sg = 'Fem. sg. -H/-T',
                   masc_pl = 'Masc. pl. -JM/-J', fem_pl = 'Fem. pl. -WT/-T',
                   pron_suffix = 'Pronominal suffix')
ending_label <- function(ending) factor(ENDING_LABELS[as.character(ending)],
                                        levels = ENDING_LABELS)
# The same for the book figures: endings in Hebrew (heb_md(), SBL Hebrew);
# the plots then need markdown_y() or markdown_legend().
ENDING_LABELS_BOOK <- c(none = 'No ending',
                        fem_sg = paste0('Fem. sg. -', heb_md('ה'), ' / -', heb_md('ת')),
                        masc_pl = paste0('Masc. pl. -', heb_md('ים'), ' / -', heb_md('י')),
                        fem_pl = paste0('Fem. pl. -', heb_md('ות'), ' / -', heb_md('ת')),
                        pron_suffix = 'Pronominal suffix')
ending_label_book <- function(ending) factor(ENDING_LABELS_BOOK[as.character(ending)],
                                             levels = ENDING_LABELS_BOOK)

# Long ending: masc. pl., fem. pl. or pronominal suffix (the endings after
# which the MT is often defective; fem. sg. behaves like no ending). The two
# dummies give the extra effect of a long ending in the non-QSP and QSP
# scrolls, relative to the MT.
dat$long_ending <- factor(as.numeric(dat$ending %in% c('masc_pl', 'fem_pl', 'pron_suffix')))
dat$nonqsp_long <- factor(as.numeric(dat$corpus == 'Non-QSP' & dat$long_ending == 1))
dat$qsp_long    <- factor(as.numeric(dat$corpus == 'QSP' & dat$long_ending == 1))

# Verb classes (I-yod: only 22 forms, not modelled)
dat$ay_ay <- factor(as.numeric(substr(dat$lex, 2, 2) == substr(dat$lex, 3, 3)))
dat$iii_h <- factor(as.numeric(substr(dat$lex, 3, 3) == 'H'))
dat$i_yod <- factor(as.numeric((substr(dat$lex, 1, 1) == 'J' & !(dat$lex %in% YOD_VERBS)) |
                                 dat$lex == 'HLK['))

# PQD[: 88 forms, mostly construct plurals in Numbers (PQDJ, PQDJHM)
dat$pqd <- factor(as.numeric(dat$lex == 'PQD['))

# Passage (book, chapter, verse, lexeme), to find parallel forms.
dat$passage <- paste(dat$book, dat$chapter, dat$verse, dat$lex)

dat_no_pqd <- dat |> filter(pqd == 0) |> droplevels()

dim(dat)                                       # 1200 forms, 246 defective
table(dat$corpus_group, dat$has_vowel_letter)
table(dat$ending, dat$has_vowel_letter, dat$corpus)
table(dat$ending, dat$pqd)
table(dat$prefix, dat$corpus)


# ==== 2. EXPLORATORY ANALYSIS ====

long_label <- function(long_ending) factor(if_else(long_ending == 1, 'Plural ending or suffix',
                                                   'No ending or fem. sg.'),
                                           levels = c('No ending or fem. sg.',
                                                      'Plural ending or suffix'))

# ---- 2a. Groups of books, with and without a long ending ----
# Without a long ending all groups are 89-97% full; the differences between
# the groups come from the forms with a long ending.

groups_long <- shares_by(dat, law_phase3, long_ending) |>
  filter(law_phase3 != 'Non-QSP LBH') |>          # 2 forms
  mutate(row = fct_rev(droplevels(law_phase3)), ending = long_label(long_ending))
groups_long
write_csv(select(groups_long, -row), file.path(IMAGE_FOLDER, 'table_ptcp_groups.csv'))

p <- plot_shares(groups_long, colour_var = 'ending', dodge_width = 0.6,
                 colours = c(BOOK_BLUE, BOOK_ORANGE)) +
  labs(caption = 'Non-QSP LBH (2 forms) not shown.')
p
save_book_figure(p, 'fig_ptcp_groups', height = 12)

# All forms per document group (for the book, Fig. 9.12)
groups_all <- shares_by(dat, law_phase3) |>
  mutate(row = fct_rev(law_phase3))
groups_all
p <- plot_shares(groups_all)
p
save_book_figure(p, 'fig_ptcp_groups_all', height = 8)

# Prefix, ע״ע and ל״ה verbs per document group (for the book, Figs. 9.15-9.17)
group_split <- function(var, labels, name) {
  tab <- shares_by(dat, law_phase3, value = .data[[var]]) |>
    filter(law_phase3 != 'Non-QSP LBH') |>        # 2 forms
    mutate(row = fct_rev(droplevels(law_phase3)),
           split = factor(labels[as.character(value)], levels = labels))
  write_csv(md_to_csv(select(tab, -row)), file.path(IMAGE_FOLDER, paste0('table_', name, '.csv')))
  p <- plot_shares(tab, colour_var = 'split', dodge_width = 0.6,
                   colours = c(BOOK_BLUE, BOOK_ORANGE)) +
    labs(caption = 'Non-QSP LBH (2 forms) not shown.') +
    markdown_legend()
  save_book_figure(p, name, height = 12)
  tab
}
group_split('has_prefix', c('0' = 'Without prefix', '1' = 'With prefix'), 'fig_ptcp_prefix_groups')
group_split('ay_ay', c('0' = 'Other verbs', '1' = paste(heb_md('ע״ע'), 'verbs')),
            'fig_ptcp_ayay_groups')
group_split('iii_h', c('0' = 'Other verbs', '1' = paste(heb_md('ל״ה'), 'verbs')),
            'fig_ptcp_iiih_groups')

# ---- 2b. Endings per corpus ----
# MT: fem. pl. 25% full (written -WT 5/36, written -T 6/8: one vowel letter,
# in the stem or in the ending; data of 2026-10-16) and pronominal suffix 13% full (the latter mostly
# PQD[); QSP keeps the long endings full.

endings <- shares_by(dat, corpus, ending) |>
  mutate(row = fct_rev(ending_label_book(ending)))
endings
write_csv(md_to_csv(select(endings, -row)), file.path(IMAGE_FOLDER, 'table_ptcp_endings.csv'))

p <- plot_shares(endings) + facet_wrap(~ corpus, ncol = 1) +
  theme(panel.spacing.y = unit(0.6, 'cm')) +
  markdown_y()
p
save_book_figure(p, 'fig_ptcp_endings', height = 14)

# ---- 2c. PQD[ vs other verbs ----

pqd_label <- function(pqd) factor(if_else(pqd == 1, 'PQD[', 'Other verbs'),
                                  levels = c('Other verbs', 'PQD['))
pqd_shares <- shares_by(dat, corpus, pqd) |>
  mutate(row = fct_rev(corpus), lexeme = pqd_label(pqd))
pqd_shares

p <- plot_shares(pqd_shares, colour_var = 'lexeme', dodge_width = 0.6,
                 colours = c(BOOK_BLUE, BOOK_ORANGE))
p
save_book_figure(p, 'fig_ptcp_explore_pqd', height = 7)

# ---- 2d. Verb classes ----
# ע-ע (96% full) is dominated by >RR[ and BLL[ (always full), ל-ה (96%) by
# NVH[.

classes <- bind_rows(
  shares_by(dat) |> mutate(row = 'All verbs'),
  shares_by(filter(dat, ay_ay == 1)) |> mutate(row = 'Ayin-ayin verbs'),
  shares_by(filter(dat, ay_ay == 1 & !lex %in% c('>RR[', 'BLL['))) |>
    mutate(row = 'Ayin-ayin verbs without >RR[ and BLL['),
  shares_by(filter(dat, iii_h == 1)) |> mutate(row = 'III-he verbs'),
  shares_by(filter(dat, iii_h == 1 & lex != 'NVH[')) |> mutate(row = 'III-he verbs without NVH['),
  shares_by(filter(dat, i_yod == 1)) |> mutate(row = 'I-yod verbs (not modelled)')
) |>
  mutate(row = factor(row, levels = rev(row)))
classes

p <- plot_shares(classes)
p
save_book_figure(p, 'fig_ptcp_explore_verb_classes', height = 7)

# ---- 2e. Parallel passages: the same form in the MT and in a scroll ----
# Unlike the infinitives, the MT is fuller than the scroll more often (18)
# than the scroll than the MT (11).

# parallel_forms() (functions.R) pairs the n-th form of a lexeme in a verse in
# the scroll with the n-th form in the MT. (The first version paired every
# scroll form with the first MT form of the lexeme in the verse; fixed
# 2026-10-10.)
parallel_table <- parallel_forms(dat, occ = raw_occurrences('ptc_qal')) |>  # raw-text pairing, 2026-11-05
  select(passage, scroll, corpus, lex, g_cons, mt_g_cons, ending, has_vowel_letter,
         mt_full, pattern)
parallel_table |> count(corpus, pattern)
write_csv(parallel_table, file.path(IMAGE_FOLDER, 'table_ptcp_parallel_passages.csv'))

p <- parallel_table |>
  mutate(corpus = droplevels(corpus)) |>
  count(corpus, pattern) |>
  mutate(pattern = factor(pattern, levels = c('MT fuller', 'both defective',
                                              'both full', 'scroll fuller'))) |>
  complete(corpus, pattern, fill = list(n = 0)) |>
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
save_book_figure(p, 'fig_ptcp_parallel_passages', height = 6)

# ---- 2f. Prefix (descriptive; additive check model M6 in section 3) ----
# In the MT forms with a prefix are less often full, almost only in the masc.
# pl. (43% vs 75%); not only because of PQD[ (without PQD[: 49% vs 73%).

prefix_label <- function(has_prefix) factor(if_else(has_prefix == 1, 'With prefix', 'Without prefix'),
                                            levels = c('Without prefix', 'With prefix'))
prefix_endings <- bind_rows(
  shares_by(filter(dat, corpus == 'MT'), ending, has_prefix) |> mutate(data = 'All verbs'),
  shares_by(filter(dat_no_pqd, corpus == 'MT'), ending, has_prefix) |> mutate(data = 'Without PQD[')
) |>
  mutate(row = fct_rev(ending_label(ending)), prefix = prefix_label(has_prefix))
prefix_endings
write_csv(select(prefix_endings, -row), file.path(IMAGE_FOLDER, 'table_ptcp_prefix.csv'))

p <- plot_shares(prefix_endings, colour_var = 'prefix', dodge_width = 0.6,
                 colours = c(BOOK_BLUE, BOOK_ORANGE)) +
  facet_wrap(~ data) +
  labs(caption = 'MT only.')
p
save_book_figure(p, 'fig_ptcp_explore_prefix', height = 9)

# ---- 2g. Lexemes ----

lexemes <- dat |>
  group_by(lex) |>
  summarise(n = n(), n_mt = sum(corpus == 'MT'),
            share_full = mean(as.numeric(as.character(has_vowel_letter)))) |>
  arrange(-n)
head(lexemes, 15)
write_csv(lexemes, file.path(IMAGE_FOLDER, 'table_ptcp_lexemes.csv'))


# ==== 3. DATA MODELLING ====
#
# Decisions (author, 2026-10-09; ../TODO.md section 9):
#   - Random part nested: (1 | scr_book2/lex).
#   - Same design as the infinitive construct analyses: corpus_group, priors
#     normal(0, 2.5) with exponential(1) on the SDs, sensitivity sd 1.5 and 4.
#   - Ending as a 5-level factor; corpus differences for the long endings as
#     two dummies (nonqsp_long, qsp_long).
#   - Verb classes ע-ע and ל-ה (as in the old final model m19); prefix only as
#     an additive check (M6).
#   - Models: M0 null; M1 corpus; M2 corpus_group; M3 M2 + ending; M4 M3 +
#     corpus x long ending; M5 M4 + ע-ע + ל-ה (expected final); M5a M3 + ע-ע +
#     ל-ה (M5 without the corpus x ending dummies); M6 M5 + prefix; m19 (old
#     final model) for comparison; M7 M5 without nonqsp_long (final model,
#     2026-10-11, credible-effects rules in ../CLAUDE.md) and M7 without each
#     of its effects (drop-one k-fold, rule 4). S1 and S1x (2026-10-14): the
#     book's has_suffix (any ending or suffix) instead of ending + qsp_long,
#     additive (S1) and with a corpus group x suffix interaction (S1x).
#   - Model choice by grouped k-fold only; Bayes factors dropped (author,
#     2026-10-14; bridge sampling unreliable, see REPORT.md).

PRIOR_SD <- 2.5
priors <- book_priors(PRIOR_SD)

# ---- 3a. Prior predictive check ----

model_prior_only <- fit_model('ptcp_d3_M5_prior_only.rds',
                              has_vowel_letter ~ corpus_group + ending + nonqsp_long +
                                qsp_long + ay_ay + iii_h + (1 | scr_book2/lex),
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
save_book_figure(p, 'check_ptcp_prior_predictive', height = 8)
rm(model_prior_only); gc()

# ---- 3b. Candidate models ----

model_specs <- list(
  M0  = has_vowel_letter ~ 1 + (1 | scr_book2/lex),
  M1  = has_vowel_letter ~ corpus + (1 | scr_book2/lex),
  M2  = has_vowel_letter ~ corpus_group + (1 | scr_book2/lex),
  M3  = has_vowel_letter ~ corpus_group + ending + (1 | scr_book2/lex),
  M4  = has_vowel_letter ~ corpus_group + ending + nonqsp_long + qsp_long +
          (1 | scr_book2/lex),
  M5  = has_vowel_letter ~ corpus_group + ending + nonqsp_long + qsp_long +
          ay_ay + iii_h + (1 | scr_book2/lex),
  M5a = has_vowel_letter ~ corpus_group + ending + ay_ay + iii_h + (1 | scr_book2/lex),
  M6  = has_vowel_letter ~ corpus_group + ending + nonqsp_long + qsp_long +
          ay_ay + iii_h + has_prefix + (1 | scr_book2/lex),
  m19 = has_vowel_letter ~ has_suffix + ay_ay + iii_h + (1 | scr_book2/lex),
  # Final model (2026-10-11): M5 without nonqsp_long (not credible, rule 1);
  # the prefix of M6 is left out because it disappears without PQD[ (rule 3(i)).
  M7  = has_vowel_letter ~ corpus_group + ending + qsp_long + ay_ay + iii_h +
          (1 | scr_book2/lex),
  # The book's two-value has_suffix instead of ending + qsp_long (author,
  # 2026-10-14): additive, and with a corpus group x suffix interaction (MT
  # Pentateuch 95% -> 48% full with a suffix, QSP 93% -> 92%).
  S1  = has_vowel_letter ~ corpus_group + has_suffix + ay_ay + iii_h +
          (1 | scr_book2/lex),
  S1x = has_vowel_letter ~ corpus_group * has_suffix + ay_ay + iii_h +
          (1 | scr_book2/lex)
)
# Drop-one comparison for the final model M7 (rule 4, 2026-10-11)
M7_TERMS <- c('corpus_group', 'ending', 'qsp_long', 'ay_ay', 'iii_h')
model_specs <- c(model_specs, drop_one_formulas(model_specs$M7, M7_TERMS, 'M7'))
model_file <- function(id, scale_b = PRIOR_SD) {
  if (scale_b == PRIOR_SD) paste0('ptcp_d3_', id, '.rds')
  else paste0('ptcp_d3_', id, '_prior', scale_b, '.rds')
}

ensure_model <- function(id, scale_b = PRIOR_SD) {
  if (!file.exists(file.path(MODEL_FOLDER, model_file(id, scale_b)))) {
    fit_model(model_file(id, scale_b), model_specs[[id]], dat,
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

# ---- 3c. Grouped k-fold cross-validation ----
# 5 folds; every scroll-book is left out as a whole.

set.seed(2026)
folds <- loo::kfold_split_grouped(K = 5, x = as.character(dat$scr_book2))

if (RUN_KFOLD) {
  kfolds <- map(set_names(names(model_specs)),
                \(id) kfold_lazy(model_file(id), paste0('ptcp_d3_', id, '_k5'), folds))
  kfold_comparison <- loo_compare(kfolds)
  print(kfold_comparison)
  kfold_table <- as.data.frame(kfold_comparison) |>
    rownames_to_column('model') |>
    select(model, elpd_diff, se_diff, elpd_kfold, se_elpd_kfold)
  write_csv(kfold_table, file.path(IMAGE_FOLDER, 'table_ptcp_kfold.csv'))

  # Final model M7 against the model without each of its effects (rule 4).
  drop_one <- drop_one_kfold_table(
    kfolds, 'M7',
    set_names(paste0('M7_no_', M7_TERMS),
              c('corpus group', 'ending', 'long ending in QSP', 'ע-ע verbs', 'ל-ה verbs')))
  print(drop_one)
  write_csv(drop_one, file.path(IMAGE_FOLDER, 'table_ptcp_kfold_drop_one.csv'))
}

# ---- 3d. Robustness and prior sensitivity ----
# Fitted and stored here; their coefficients are read in section 4d.

FINAL_ID <- 'M7'

# Prior sensitivity: the final model with prior sd 1.5 and 4
walk(c(1.5, 4), \(scale_b) ensure_model(FINAL_ID, scale_b))

robustness_specs <- list(
  no_pqd    = list(file = 'ptcp_d3_M5_no_PQD.rds', formula = model_specs$M5,
                   data = dat_no_pqd),
  no_1qisaa = list(file = 'ptcp_d3_M5_no_1QIsaa.rds', formula = model_specs$M5,
                   data = filter(dat, !scroll %in% c('1QisaaI', '1QisaaII')) |> droplevels()),
  # Credible-effects rule 3(i) (2026-10-11): does the prefix effect of M6
  # survive without PQD[?
  m6_no_pqd = list(file = 'ptcp_d3_M6_no_PQD.rds', formula = model_specs$M6,
                   data = dat_no_pqd)
)
walk(robustness_specs, function(r) {
  if (!file.exists(file.path(MODEL_FOLDER, r$file))) {
    fit_model(r$file, r$formula, r$data, priors)
    gc()
  }
})

# ---- 3e. Final model ----
# M7, not S1x (the book's has_suffix with corpus_group x suffix): chosen by
# the author after the refit (2026-10-18; ../TODO.md sections 9 and 13 item
# 9). Drop-one and prior sensitivity are fitted for M7.
# Evidence from the refit on the data of 2026-11-03 (ptcp_d3_*, 2026-11-04;
# M7 confirmed by the author the same day): M7 is the best model in the
# grouped k-fold (M5 -0.8, SE 0.6; M6 -1.7, SE 2.6). S1x vs M7 -50.7 (SE
# 8.4), S1 vs M7 -51.8 (8.3), S1x vs S1 +1.1 (3.2). In S1x (reference MT
# Pentateuch) only QSP x suffix is credible (+3.01, 95% 0.31 to 5.74, pd
# 0.985). M7 (2026-10-11, credible-effects rules in ../CLAUDE.md): M5
# without nonqsp_long (-0.40, pd 0.64, rule 1). The prefix of M6 (-1.00, pd
# 0.997) is not included: without PQD[ it halves and is no longer credible
# (-0.51, -1.31 to 0.28, pd 0.90; rule 3(i)). Drop-one k-fold: ending -113.3
# (11.7), ע-ע -16.1 (3.2), QSP long ending -10.6 (2.6), corpus group -4.4
# (4.3), ל-ה -2.1 (1.8); corpus group and ל-ה bring no clear gain (rule 4).
# Corpus group: only MT LBH vs MT Pentateuch is credible (2.52, 0.43 to
# 4.52, pd 0.991). ל-ה is credible only just (1.54, 0.03 to 3.24, pd 0.977;
# ptcp_d2_: 1.80, pd 0.991).
final_model <- load_model(model_file(FINAL_ID))
summary(final_model)


# ==== 4. DATA VISUALISATION ====

# ---- 4a. Table of fixed effects ----

fixed_table <- make_fixed_effects_table(final_model)
fixed_table
write_csv(rownames_to_column(fixed_table, 'parameter'),
          file.path(IMAGE_FOLDER, 'table_ptcp_fixed_effects.csv'))

# ---- 4b. Effects (odds ratios) ----
# Corpus groups as contrasts vs MT Pentateuch, computed from the draws. MT
# Pentateuch is the reference level, so these are the coefficients themselves;
# effect_draws() also works for a model with another reference level.
# Endings vs no ending.

CORPUS_GROUP_COEF <- c('MT Former Prophets' = 'MTFormerProphets', 'MT LBH' = 'MTLBH',
                       'MT other books' = 'MTotherbooks', 'Non-QSP scrolls' = 'NonMQSP',
                       'QSP scrolls' = 'QSP')
EFFECT_LABELS <- c(b_endingfem_sg      = paste(ENDING_LABELS[['fem_sg']], '(vs no ending)'),
                   b_endingmasc_pl     = paste(ENDING_LABELS[['masc_pl']], '(vs no ending)'),
                   b_endingfem_pl      = paste(ENDING_LABELS[['fem_pl']], '(vs no ending)'),
                   b_endingpron_suffix = paste(ENDING_LABELS[['pron_suffix']], '(vs no ending)'),
                   b_nonqsp_long1      = 'Long ending in non-QSP (extra)',
                   b_qsp_long1         = 'Long ending in QSP (extra)',
                   b_ay_ay1            = 'Ayin-ayin verbs (vs other verbs)',
                   b_iii_h1            = 'III-he verbs (vs other verbs)',
                   b_has_prefix1       = 'Prefix (vs none)')

# Draws (long format: label, parameter, value) of the corpus-group contrasts vs
# MT Pentateuch and of the other coefficients of a model (M5, M6, M7 and
# their robustness and prior fits).
effect_draws <- function(model) {
  d <- as_draws_df(model)
  coef_or_0 <- function(g) {
    name <- paste0('b_corpus_group', g)
    if (name %in% names(d)) d[[name]] else 0
  }
  pentateuch <- coef_or_0('MTPentateuch')
  present <- names(EFFECT_LABELS)[names(EFFECT_LABELS) %in% names(d)]
  bind_rows(
    imap_dfr(CORPUS_GROUP_COEF, \(g, group)
      tibble(label = paste(group, 'vs MT Pentateuch'),
             parameter = paste0('corpus_group', g, ' - MTPentateuch'),
             value = coef_or_0(g) - pentateuch)),
    coef_draws(model, set_names(present, EFFECT_LABELS[present]))
  )
}

effects <- effect_draws(final_model) |>
  mutate(label = factor(label, levels = rev(unique(label)))) |>
  summarise_effects(label, parameter)
effects
write_csv(effects, file.path(IMAGE_FOLDER, 'table_ptcp_effects.csv'))  # labels as in the model

# Wide axis: the fem. pl. ending is about 1/910 (ptcp_d3_; 1/950 in ptcp_d2_, 1/1800 in the old fits).
or_breaks <- c(1/4096, 1/1024, 1/256, 1/64, 1/16, 1/4, 1, 4, 16, 64, 256, 1024)
or_labels <- c('1/4096', '1/1024', '1/256', '1/64', '1/16', '1/4', '1', '4', '16', '64',
               '256', '1024')
# The book figure: labels as in the book (Hebrew, 'MT Other') and fewer breaks
# (the labels 1/4096, 1/1024, 1/256 overlapped).
BOOK_EFFECT_LABELS <- c(
  'MT other books vs MT Pentateuch' = 'MT Other vs MT Pentateuch',
  set_names(paste(ENDING_LABELS_BOOK[c('fem_sg', 'masc_pl', 'fem_pl', 'pron_suffix')],
                  '(vs no ending)'),
            EFFECT_LABELS[c('b_endingfem_sg', 'b_endingmasc_pl', 'b_endingfem_pl',
                            'b_endingpron_suffix')]),
  'Ayin-ayin verbs (vs other verbs)' = paste(heb_md('ע״ע'), 'verbs (vs other verbs)'),
  'III-he verbs (vs other verbs)' = paste(heb_md('ל״ה'), 'verbs (vs other verbs)'))
book_effect_label <- function(x) {
  x <- as.character(x)
  if_else(x %in% names(BOOK_EFFECT_LABELS), unname(BOOK_EFFECT_LABELS[x]), x)
}
or_breaks_book <- c(1/4096, 1/256, 1/16, 1, 16, 256)
or_labels_book <- c('1/4096', '1/256', '1/16', '1', '16', '256')
or_caption <- paste0('Groups vs MT Pentateuch; endings vs no ending.\n',
                     '"Extra": additional effect of a long ending in the QSP scrolls vs the MT.\n',
                     OR_CAPTION)
effects_book <- effects |>
  mutate(label = factor(book_effect_label(label), levels = book_effect_label(levels(label))))
p <- plot_or(effects_book, label, breaks = or_breaks_book, labels = or_labels_book,
             caption = or_caption) +
  markdown_y()
p
save_book_figure(p, 'fig_ptcp_effects', height = 11)

# ---- 4b2. Effects not in the final model ----
# No credible effect (rules 1 and 3(i)); estimates from the comparison models.

not_in_final <- effects_not_in_final_model(tribble(
  ~label,                                       ~file,                 ~parameter,
  'Long ending in non-QSP (extra; M5)',         model_file('M5'),      'b_nonqsp_long1',
  'Prefix (vs none; M6)',                       model_file('M6'),      'b_has_prefix1',
  'Prefix (vs none; M6 without PQD[)',          'ptcp_d3_M6_no_PQD.rds',  'b_has_prefix1'
))
not_in_final
write_csv(not_in_final, file.path(IMAGE_FOLDER, 'table_ptcp_effects_not_in_final_model.csv'))
p <- plot_effects_not_in_final_model(
  not_in_final, or_breaks, or_labels,
  caption = paste0('Not in the final model M7. "Extra": vs the long ending in the MT.\n',
                   OR_CAPTION))
p
save_book_figure(p, 'fig_ptcp_effects_not_in_final_model', height = 5)

# ---- 4c. Predicted probability of full spelling ----
# Population level (re_formula = NA): a typical scroll-book and lexeme, not a
# ע-ע or ל-ה verb. All five endings in the table; the figure shows no ending
# and the masc. pl. (the most frequent long ending).

newdata <- expand_grid(corpus_group = factor(levels(dat$corpus_group),
                                             levels = levels(dat$corpus_group)),
                       ending = factor(levels(dat$ending), levels = levels(dat$ending))) |>
  mutate(corpus = case_when(corpus_group == 'Non-QSP' ~ 'Non-QSP',
                            corpus_group == 'QSP' ~ 'QSP', TRUE ~ 'MT'),
         long = ending %in% c('masc_pl', 'fem_pl', 'pron_suffix'),
         nonqsp_long = factor(as.numeric(corpus == 'Non-QSP' & long), levels = c('0', '1')),
         qsp_long = factor(as.numeric(corpus == 'QSP' & long), levels = c('0', '1')),
         ay_ay = factor('0', levels = levels(dat$ay_ay)),
         iii_h = factor('0', levels = levels(dat$iii_h)),
         condition = recode(as.character(corpus_group), 'MT other books' = 'MT Other',
                            'Non-QSP' = 'Non-QSP scrolls', 'QSP' = 'QSP scrolls'),
         ending_lab = ending_label_book(ending))

condition_order <- c('MT Pentateuch', 'MT Former Prophets', 'MT LBH', 'MT Other',
                     'Non-QSP scrolls', 'QSP scrolls')
predicted <- newdata |>
  add_epred_draws(final_model, re_formula = NA) |>
  group_by(condition, ending_lab) |>
  median_qi(.epred, .width = c(0.66, 0.95)) |>
  mutate(condition = factor(condition, levels = rev(condition_order)))
predicted
write_csv(md_to_csv(predicted), file.path(IMAGE_FOLDER, 'table_ptcp_predicted.csv'))

p <- predicted |>
  filter(ending_lab %in% ENDING_LABELS_BOOK[c('none', 'masc_pl')]) |>
  ggplot(aes(y = condition, x = .epred, xmin = .lower, xmax = .upper, colour = ending_lab)) +
  geom_pointinterval(point_size = 2.5, interval_size_range = c(0.8, 2),
                     position = position_dodge(width = 0.6)) +
  scale_colour_manual(values = c(BOOK_BLUE, BOOK_ORANGE),
                      guide = guide_legend(reverse = TRUE)) +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25),
                     labels = scales::percent) +
  labs(x = 'Predicted probability of full spelling', y = NULL,
       caption = paste0('Point: median; thick and thin line: 66% and 95% interval.<br>',
                        'Typical document and lexeme; not a ', heb_md('ע״ע'), ' or ',
                        heb_md('ל״ה'), ' verb.')) +
  theme_book() +
  markdown_legend() +
  markdown_caption()
p
save_book_figure(p, 'fig_ptcp_predicted', height = 9)

# ---- 4d. Robustness and prior sensitivity ----
# The key effects in M7, in M7 with priors sd 1.5 and 4, in M5 (= M7 +
# nonqsp_long, which is ~0) without PQD[ and without 1QIsaa, and in M6 (with
# prefix) with and without PQD[.

robust_specs <- c('M7 (final)'          = model_file(FINAL_ID),
                  'M7, prior sd 1.5'    = model_file(FINAL_ID, 1.5),
                  'M7, prior sd 4'      = model_file(FINAL_ID, 4),
                  'M5 without PQD['     = 'ptcp_d3_M5_no_PQD.rds',
                  'M5 without 1QIsaa'   = 'ptcp_d3_M5_no_1QIsaa.rds',
                  'M6 (with prefix)'    = model_file('M6'),
                  'M6 without PQD['     = 'ptcp_d3_M6_no_PQD.rds')
key_effects <- c('QSP scrolls vs MT Pentateuch', 'Long ending in QSP (extra)',
                 'Non-QSP scrolls vs MT Pentateuch', 'MT other books vs MT Pentateuch',
                 EFFECT_LABELS[['b_endingmasc_pl']], 'Prefix (vs none)')

robustness <- imap_dfr(robust_specs, function(file, variant) {
  m <- if (file == model_file(FINAL_ID)) final_model else load_model(file)
  out <- effect_draws(m) |>
    filter(label %in% key_effects) |>
    summarise_effects(label) |>
    mutate(variant = variant)
  if (file != model_file(FINAL_ID)) { rm(m); gc() }
  out
}) |>
  mutate(label = factor(label, levels = key_effects),
         variant = factor(variant, levels = rev(names(robust_specs))))
robustness
write_csv(robustness, file.path(IMAGE_FOLDER, 'table_ptcp_robustness.csv'))

p <- plot_or(robustness, variant, breaks = or_breaks, labels = or_labels,
             caption = paste0('Groups vs MT Pentateuch. M5 = M7 + long ending in non-QSP (~0).\n',
                              OR_CAPTION)) +
  facet_wrap(~ label, ncol = 2, labeller = label_wrap_gen(40))
p
save_book_figure(p, 'fig_ptcp_robustness', height = 18)

# ---- 4e. Random intercepts of the books (check) ----

p <- plot_random_intercepts(final_model, 'scr_book2', text_size = 5) + theme_book()
save_book_figure(p, 'check_ptcp_random_books', height = 22)

# ---- 4f. Random intercepts for the book (Figs. 9.20-9.22) ----
# Documents (scr_book2), the lexemes of MT Genesis, and כתב / ברך per
# document (scr_book2:lex); median with 66% and 95% interval. With
# corpus_group in the model, the document intercepts are deviations from the
# document's own group; the lexeme intercepts are deviations within the
# document.

doc_label <- function(x) {
  x |>
    str_replace('^1QisaaI_Isaiah$', '1QIsa<sup>a</sup> Part I') |>
    str_replace('^1QisaaII_Isaiah$', '1QIsa<sup>a</sup> Part II') |>
    str_replace_all('_', ' ') |>
    str_replace('Song of songs', 'Song of Songs') |>
    str_replace('Ecclesiastes', 'Qoheleth')
}
ranef_table <- function(term) {
  ranef(final_model, robust = TRUE, probs = c(0.025, 0.17, 0.83, 0.975))[[term]][, , 'Intercept'] |>
    as.data.frame() |>
    rownames_to_column('id')
}
plot_ranef <- function(tab, x_label) {
  ggplot(tab, aes(y = label, x = Estimate)) +
    geom_vline(xintercept = 0, colour = BOOK_GREY) +
    geom_linerange(aes(xmin = Q2.5, xmax = Q97.5), linewidth = 0.6, colour = BOOK_BLUE) +
    geom_linerange(aes(xmin = Q17, xmax = Q83), linewidth = 1.6, colour = BOOK_BLUE) +
    geom_point(size = 2, colour = BOOK_BLUE) +
    labs(x = x_label, y = NULL, caption = OR_CAPTION) +
    theme_book() +
    markdown_y()
}

# Two panels (MT books, scrolls), so that the 100 documents fit on a page;
# the QSP scrolls in orange.
doc_corpus <- distinct(dat, id = as.character(scr_book2), corpus)
doc_ranef <- ranef_table('scr_book2') |>
  left_join(doc_corpus, by = 'id') |>
  mutate(panel = factor(if_else(corpus == 'MT', 'MT books', 'Scrolls'),
                        levels = c('MT books', 'Scrolls')),
         qsp = factor(if_else(corpus == 'QSP', 'QSP scrolls', 'MT and non-QSP scrolls'),
                      levels = c('MT and non-QSP scrolls', 'QSP scrolls')),
         label = fct_reorder(doc_label(id), Estimate))
stopifnot(!anyNA(doc_ranef$corpus))
write_csv(md_to_csv(doc_ranef), file.path(IMAGE_FOLDER, 'table_fig_ptcp_random_docs.csv'))
p <- ggplot(doc_ranef, aes(y = label, x = Estimate, colour = qsp)) +
  geom_vline(xintercept = 0, colour = BOOK_GREY) +
  geom_linerange(aes(xmin = Q2.5, xmax = Q97.5), linewidth = 0.4) +
  geom_linerange(aes(xmin = Q17, xmax = Q83), linewidth = 1.1) +
  geom_point(size = 1.2) +
  scale_colour_manual(values = c(BOOK_BLUE, BOOK_ORANGE)) +
  facet_wrap(~ panel, ncol = 2, scales = 'free_y') +
  labs(x = 'Document-level random intercept (logit scale)', y = NULL, caption = OR_CAPTION) +
  theme_book(base_size = 9) +
  theme(axis.text.y.left = ggtext::element_markdown(colour = BOOK_INK_2, size = 6),
        panel.spacing.x = unit(0.6, 'cm'))
save_book_figure(p, 'fig_ptcp_random_docs', height = 19)

lex_ranef <- ranef_table('scr_book2:lex') |>
  mutate(doc = sub('_[^_]+$', '', id), lex = sub('^.*_', '', id))
genesis_ranef <- lex_ranef |>
  filter(doc == 'MT_Genesis') |>
  mutate(label = fct_reorder(heb_md(etcbc_to_hebrew(lex)), Estimate))
write_csv(md_to_csv(genesis_ranef), file.path(IMAGE_FOLDER, 'table_fig_ptcp_random_genesis.csv'))
p <- plot_ranef(genesis_ranef, 'Lexeme-level random intercept in MT Genesis (logit scale)') +
  theme(axis.text.y.left = ggtext::element_markdown(colour = BOOK_INK_2, size = 12))
save_book_figure(p, 'fig_ptcp_random_genesis', height = 9)

# One panel per lexeme; the y levels carry the lexeme so that the documents
# are ordered within each panel (the prefix is dropped from the labels).
ktb_brk_ranef <- lex_ranef |>
  filter(lex %in% c('KTB[', 'BRK[')) |>
  mutate(lexeme = factor(heb_md(etcbc_to_hebrew(lex)),
                         levels = heb_md(etcbc_to_hebrew(c('KTB[', 'BRK[')))),
         label = fct_reorder(paste0(lex, '|', doc_label(doc)), Estimate))
write_csv(md_to_csv(select(ktb_brk_ranef, -label)),
          file.path(IMAGE_FOLDER, 'table_fig_ptcp_random_ktb_brk.csv'))
p <- plot_ranef(ktb_brk_ranef, 'Lexeme-level random intercept in the document (logit scale)') +
  scale_y_discrete(labels = \(x) sub('^[^|]*[|]', '', x)) +
  facet_wrap(~ lexeme, ncol = 2, scales = 'free_y') +
  theme(strip.text.x.top = ggtext::element_markdown(colour = BOOK_INK, size = 14, hjust = 0),
        panel.spacing.x = unit(0.8, 'cm'))
save_book_figure(p, 'fig_ptcp_random_ktb_brk', height = 12)


# ==== 5. MODEL VERIFICATION ====

# Convergence, trace and density plots, posterior predictive checks, LOO (for
# completeness; unreliable with the nested structure) and Bayes R2. The
# in-sample classification it prints is optimistic.
verification <- verify_model(final_model, IMAGE_FOLDER, 'check_ptcp')

# Observed vs predicted share of full spellings per group of books, per corpus
# and ending, for PQD[ (no fixed effect) and for the most frequent lexemes.
ppc_groups <- group_ppc(final_model, dat, 'law_phase3')
ppc_groups
save_book_figure(plot_ppc(ppc_groups), 'check_ptcp_ppc_groups', height = 8)

dat$corpus_ending <- factor(paste(dat$corpus, ENDING_LABELS[as.character(dat$ending)], sep = ': '),
                            levels = paste(rep(levels(dat$corpus), each = 5),
                                           ENDING_LABELS, sep = ': '))
ppc_ending <- group_ppc(final_model, dat, 'corpus_ending')
ppc_ending
save_book_figure(plot_ppc(ppc_ending), 'check_ptcp_ppc_endings', height = 12)

main_lexemes <- c('BRK[', 'KTB[', 'PQD[', '>RR[', 'NVH[', 'BLL[')
dat$lex_main <- factor(if_else(dat$lex %in% main_lexemes, as.character(dat$lex), 'other lexemes'),
                       levels = c(main_lexemes, 'other lexemes'))
ppc_lex <- group_ppc(final_model, dat, 'lex_main')
ppc_lex
save_book_figure(plot_ppc(ppc_lex), 'check_ptcp_ppc_lexemes', height = 7)
