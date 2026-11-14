################################################################################
# hiphil_triliteral/analysis.R
#
# Dataset:  hiphil_triliteral_with_hireq.csv - triliteral Hiphil forms in the
#           MT and the Dead Sea Scrolls (no SP). Only the forms with a hireq
#           are analysed (3437); the 602 forms without one (mostly wayyiqtol,
#           imperative and imperfect with sere) are only tabulated.
# Outcome:  has_vowel_letter (1 = hireq written with yod, e.g. HQVJR; 0 =
#           defective, HQVR).
# Questions:
#   1. Do the QSP and non-QSP scrolls spell the Hiphil more fully than the MT?
#   2. Within the MT: do the groups of books differ (Pentateuch, Former
#      Prophets, LBH, other books)?
#   3. How do the verbal tense and a suffix affect the spelling, and do the
#      groups of books differ in this (in particular the wayyiqtol)?
#
# Status (2026-10-18): rebuilt on the design of the other verb forms
# (../CLAUDE.md); model set approved by the author (2026-10-15). Final model
# M7 = corpus_group * vt + corpus_group * has_suffix (author, 2026-10-18).
# Stored: full fits of M0-M7, n9v2, the prior-only fit, all k-folds (run of
# 2026-10-17/18) and the robustness fits M7_no_1QIsaa and M7_no_NGD. The
# drop-one models M7_no_vt and M7_no_suffix (with k-folds) and the prior
# sensitivity fits of M7 (sd 1.5, 4) are stored too (approved and fitted
# 2026-10-18). Results: REPORT.md.
#
# Started from ../../script_trilit_hif_cleaned.R (its CHANGES list documents the
# bug fixes w.r.t. the original script). Changes w.r.t. that script:
#   - Design as the other verb forms: corpus_group (MT split by group of books;
#     non-QSP and QSP one group each) instead of law_phase2/law_phase3, with
#     MT Pentateuch as the reference level (author, 2026-10-15); priors
#     normal(0, 2.5) with exponential(1) on the SDs; grouped 5-fold k-fold;
#     no Bayes factors (author, 2026-10-14).
#   - The 30 old candidate models (fitted on older data: 9v2 on 3431 rows) are
#     replaced by the model set in section 3; the old final model 9v2
#     (vt + has_suffix) is refitted for comparison.
#   - corpus_group x vt instead of a separate wayyiqtol term (author,
#     2026-10-15): the MT wayyiqtol is 35% full in the Pentateuch, 40% in the
#     Former Prophets, 63% in the other books and 90% in LBH.
#   - has_suffix as in the book (pronominal suffix, nominal ending or
#     paragogic nun); suffix types only descriptive.
#   - Prefix not modelled: outside the wayyiqtol (which always has W) the
#     prefix makes no difference (rule 3(ii) in ../CLAUDE.md); descriptive
#     figure only.
#   - First letter not modelled (proxy for tense and person); verb classes not
#     modelled (no ע-ע or ל-ה verbs; I-nun 90% vs 88%; I-yod is one lexeme).
#   - Postponed: the Isaiah manuscripts model (old 3b/4d) and the verb
#     frequency model (old 3c).
#   - Book figures (fig_hif_*) replace the explore_* plots.
#   - Data of 2026-10-19 (preprocessing commit 1297334): 1QIsaa Isa 38:16
#     TXLJMNJ has lexeme XLM=[ instead of XLM[. The stored fits use the
#     earlier data; not refitted, because this form is the only one of either
#     lexeme in 1QIsaa, so its book x lexeme group only changes its label.
#     Sections 0-2 rerun: the form now matches its MT parallel (QSP both full
#     282 -> 283) and XLM=[ has 2 forms in the lexeme table.
#
# CHANGES 2026-10-19 (book §9.7, BOOK_CHANGES_9.7.md; no fitting):
#   - Exclusion of 4Q82 Amos 8:5 (NCBJM, a different reading) by passage
#     instead of tf_id: the old tf_id 2044395 now belongs to 4Q82 Amos 4:7
#     >MVJR (full), which was excluded by mistake, while Amos 8:5 stayed in.
#     The data now have Amos 4:7 and not Amos 8:5 (still 3437 forms). The
#     stored fits (hif_*.rds, all k-folds) were made with the old filter and
#     are kept (author, 2026-10-19): two of 3437 forms, one QSP scroll.
#   - Parallel passages paired by mt_match (parallel_forms_matched() in
#     ../functions.R) instead of by position: the positional pairing
#     misaligned 4Q76 and 4Q81 at Jon 1:7 and Mur88 at Mic 2:6. Non-QSP now
#     19 MT fuller / 18 scroll fuller (as the book), QSP 13 / 13.
#   - Suffix types: paragogic nun before the pronominal suffix (the 12 scroll
#     forms with paragogic nun have has_prs = 1). Descriptive only.
#   - Book figures: fig_hif_groups_all (document groups), fig_hif_suffix_tenses
#     and fig_hif_prefix_tenses (MT / non-QSP / QSP); 'MT Other' and
#     'Wayyiqṭol' in the figure labels; Charis.
#
# CHANGES 2026-11-10 (author: chapter 9 figures like chapter 8):
#   - The book figures by document group use corpus_group, with the non-QSP
#     scrolls as one group (column fig_group, labelled 'MT Other'), instead
#     of law_phase3 (non-QSP split by group of books), as the models and the
#     figures of chapter 8. The filters and captions for Non-QSP LBH are gone.
#
# CHANGES 2026-11-12: new descriptive subsection 2g2 (wayyiqtol by person,
#   ending and suffix; table_hif_wayq_form_groups.csv), for the Suchard
#   additions to section 9.7 (../BOOK_CHANGES_suchard.md). No model changed.
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
VERB_FORM <- 'hiphil_triliteral'
IMAGE_FOLDER <- file.path(ANALYSIS_DIR, VERB_FORM, 'figures')

source(file.path(SHARED_DIR, 'config.R'))
source(file.path(SHARED_DIR, 'functions.R'))

DATASET <- 'hiphil_triliteral_with_hireq.csv'

# ALLOW_FIT = FALSE: only load stored results; stop instead of fitting.
ALLOW_FIT <- FALSE  # all fits of the model set, drop-one and prior sensitivity stored (2026-10-18); set TRUE only after approval
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
  droplevels()

# Difficult case with a completely different reading in the scroll (4Q82,
# Amos 8:5 NCBJM for MT NCBJRH); removed as in the original script. Selected by
# passage, not by tf_id: the tf_ids change when the data are regenerated
# (2026-10-19; the stored fits still have the old selection, see CHANGES).
excluded <- with(dat, scroll == '4Q82' & book == 'Amos' & chapter == 8 & verse == 5 & lex == 'CBR=[')
stopifnot(sum(excluded) == 1)
dat <- dat |> filter(!excluded)

# Forms without hireq are not analysed (only tabulated in section 2)
dat_non_hireq <- dat |> filter(has_hireq == 0)
dat <- dat |> filter(has_hireq == 1)

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

# Corpus group (6 levels). Reference level: MT Pentateuch (author, 2026-10-15).
CORPUS_GROUPS <- c('MT Pentateuch', 'MT Former Prophets', 'MT LBH', 'MT other books',
                   'Non-QSP', 'QSP')
dat$corpus_group <- factor(case_when(dat$corpus == 'MT' & dat$book_group == 'Other' ~ 'MT other books',
                                     dat$corpus == 'MT' ~ paste('MT', dat$book_group),
                                     TRUE ~ as.character(dat$corpus)),
                           levels = CORPUS_GROUPS)
# Labels as in the book ('MT Other'); for figures only, the factor levels of
# the fitted models stay.
book_group <- function(x) fct_recode(factor(x), 'MT Other' = 'MT other books')

# Verbal tense. Reference level: imperfect.
VT_LABELS <- c(impf = 'Imperfect', wayq = 'Wayyiqṭol', perf = 'Perfect',
               impv = 'Imperative', infc = 'Infinitive construct', ptca = 'Participle')
dat$vt <- factor(dat$vt, levels = names(VT_LABELS))
vt_label <- function(vt) factor(VT_LABELS[as.character(vt)], levels = VT_LABELS)

# Paragogic nun (2/3 pl impf/wayq ending in nun) is counted as a suffix, as in
# the book.
dat$has_par_nun <- as.numeric(dat$ps %in% c('p2', 'p3') & dat$nu == 'pl' &
                                dat$vt %in% c('impf', 'wayq') &
                                str_sub(dat$g_cons, -1) == 'N')
dat$has_suffix <- factor(as.numeric(as.character(dat$has_suffix) == '1' | dat$has_par_nun == 1))

# Suffix type (descriptive only)
# Paragogic nun first: in the scroll data it has has_prs = 1 (12 forms).
dat$suffix_type <- factor(case_when(dat$has_par_nun == 1 ~ 'Paragogic nun',
                                    dat$has_prs == 1 ~ 'Pronominal suffix',
                                    dat$nme == 'JM' ~ 'Masc. pl. -JM',
                                    dat$has_nme == 1 ~ 'Other nominal ending',
                                    TRUE ~ 'No suffix'),
                          levels = c('No suffix', 'Pronominal suffix', 'Masc. pl. -JM',
                                     'Paragogic nun', 'Other nominal ending'))
stopifnot(all((dat$suffix_type == 'No suffix') == (dat$has_suffix == '0')))

# First letter of the form (descriptive only)
dat$first_letter <- substr(dat$g_cons, 1, 1)

dat_no_1qisaa <- dat |> filter(!scroll %in% c('1QisaaI', '1QisaaII')) |> droplevels()
dat_no_ngd    <- dat |> filter(lex != 'NGD[') |> droplevels()   # largest lexeme, 280 forms

dim(dat)                                       # 3437 forms, 399 defective
table(dat$corpus_group, dat$has_vowel_letter)
table(dat$corpus_group, dat$vt)
table(dat$suffix_type, dat$corpus)


# ==== 2. EXPLORATORY ANALYSIS ====

# Document groups of the book figures: corpus_group, the non-QSP scrolls as
# one group (author, 2026-11-10), labelled as in the book.
dat$fig_group <- fct_recode(dat$corpus_group, 'MT Other' = 'MT other books')

suffix_label <- function(has_suffix) factor(if_else(has_suffix == 1, 'With suffix', 'Without suffix'),
                                            levels = c('Without suffix', 'With suffix'))
prefix_label <- function(has_prefix) factor(if_else(has_prefix == 1, 'With prefix', 'Without prefix'),
                                            levels = c('Without prefix', 'With prefix'))

# ---- 2a. Groups of books ----
# Within the MT the groups differ more (Former Prophets 78%, LBH 94%) than the
# scrolls from the MT (non-QSP 88%, QSP 93%).

groups <- shares_by(dat, corpus_group) |>
  mutate(row = fct_rev(book_group(corpus_group)))
groups
write_csv(select(groups, -row), file.path(IMAGE_FOLDER, 'table_hif_groups.csv'))

p <- plot_shares(groups)
p
save_book_figure(p, 'fig_hif_groups', height = 7)

# Document groups of the book figure (Fig. 9.43): the non-QSP scrolls as one
# group, as in chapter 8 (author, 2026-11-10)
groups_all <- shares_by(dat, fig_group) |>
  mutate(row = fct_rev(fig_group))
groups_all
write_csv(select(groups_all, -row), file.path(IMAGE_FOLDER, 'table_hif_groups_all.csv'))
p <- plot_shares(groups_all)
p
save_book_figure(p, 'fig_hif_groups_all', height = 7)

# ---- 2b. Verbal tense per group of books ----
# The wayyiqtol is the least full tense, but very unequally: MT Pentateuch 35%,
# Former Prophets 40%, other books 63%, LBH 90%. In the other tenses the
# groups are 78-100% full. Hence corpus_group x vt (author, 2026-10-15).

tenses <- shares_by(dat, corpus_group, vt) |>
  mutate(row = fct_rev(vt_label(vt)))
tenses
write_csv(select(tenses, -row), file.path(IMAGE_FOLDER, 'table_hif_tenses.csv'))

p <- plot_shares(tenses) + facet_wrap(~ book_group(corpus_group), ncol = 2) +
  theme(panel.spacing.y = unit(0.5, 'cm'))
p
save_book_figure(p, 'fig_hif_tenses', height = 18)

# ---- 2c. Suffix per group of books ----
# The suffix lowers fullness strongly in the MT (Pentateuch 92% -> 69%, Former
# Prophets 82% -> 59%) and only a little in the scrolls (non-QSP 89% -> 85%,
# QSP 94% -> 89%).

suffix_groups <- shares_by(dat, corpus_group, has_suffix) |>
  mutate(row = fct_rev(book_group(corpus_group)), suffix = suffix_label(has_suffix))
suffix_groups
write_csv(select(suffix_groups, -row), file.path(IMAGE_FOLDER, 'table_hif_suffix.csv'))

p <- plot_shares(suffix_groups, colour_var = 'suffix', dodge_width = 0.6,
                 colours = c(BOOK_BLUE, BOOK_ORANGE))
p
save_book_figure(p, 'fig_hif_suffix', height = 9)

# ---- 2d. Suffix per tense, MT, non-QSP and QSP (book Fig. 9.45) ----
# MT: the suffix lowers fullness in every tense except the wayyiqtol (58% vs
# 55%); participle 97% vs 67%.

suffix_tenses <- shares_by(dat, corpus, vt, has_suffix) |>
  mutate(row = fct_rev(vt_label(vt)), suffix = suffix_label(has_suffix))
suffix_tenses
write_csv(select(suffix_tenses, -row), file.path(IMAGE_FOLDER, 'table_hif_suffix_tenses.csv'))

p <- plot_shares(suffix_tenses, colour_var = 'suffix', dodge_width = 0.6,
                 colours = c(BOOK_BLUE, BOOK_ORANGE)) +
  facet_wrap(~ corpus, ncol = 1) +
  theme(panel.spacing.y = unit(0.5, 'cm'))
p
save_book_figure(p, 'fig_hif_suffix_tenses', height = 18)

# ---- 2e. Suffix types (descriptive) ----
# Pronominal suffix 80% full (701 forms), masc. pl. -JM 57% (70, participles),
# paragogic nun 59% (22); the other nominal endings (mostly construct -J) are
# nearly always full.

suffix_types <- shares_by(dat, corpus, suffix_type) |>
  mutate(row = fct_rev(suffix_type))
suffix_types
write_csv(select(suffix_types, -row), file.path(IMAGE_FOLDER, 'table_hif_suffix_types.csv'))

p <- plot_shares(suffix_types) + facet_wrap(~ corpus, ncol = 1) +
  theme(panel.spacing.y = unit(0.5, 'cm'))
p
save_book_figure(p, 'fig_hif_explore_suffix_types', height = 14)

# ---- 2f. Prefix outside the wayyiqtol (descriptive; not modelled) ----
# Every wayyiqtol has the prefix W, so the prefix effect in the raw data is a
# wayyiqtol effect (rule 3(ii)). Outside the wayyiqtol: no difference in the MT
# and non-QSP (89-97% without, 89-93% with a prefix); only QSP is lower with a
# prefix (85/99, 86%, vs 202/210, 96%). Decided (author, 2026-10-15):
# descriptive remark, no model term. The gap comes mainly from W + imperfect
# (QSP 18/25 vs 101/106 without prefix; 11 of the 14 defective forms from
# 1QIsaa); the MT shows the same (W + imperfect 58/74, 78%, vs 90%),
# probably short (jussive/volitive) forms as in the wayyiqtol.

prefix_groups <- shares_by(filter(dat, vt != 'wayq'), corpus_group, has_prefix) |>
  mutate(row = fct_rev(corpus_group), prefix = prefix_label(has_prefix))
prefix_groups
write_csv(select(prefix_groups, -row), file.path(IMAGE_FOLDER, 'table_hif_prefix.csv'))

p <- plot_shares(prefix_groups, colour_var = 'prefix', dodge_width = 0.6,
                 colours = c(BOOK_BLUE, BOOK_ORANGE)) +
  labs(caption = 'Without the wayyiqtol (all wayyiqtol forms have the prefix W).')
p
save_book_figure(p, 'fig_hif_explore_prefix', height = 9)

# Prefix per tense, MT, non-QSP and QSP (book Fig. 9.47). Every wayyiqtol has
# the prefix W. MT imperfect 90% without vs 78% with a prefix, QSP 95% vs 72%.
prefix_tenses <- shares_by(dat, corpus, vt, has_prefix) |>
  mutate(row = fct_rev(vt_label(vt)), prefix = prefix_label(has_prefix))
prefix_tenses
write_csv(select(prefix_tenses, -row), file.path(IMAGE_FOLDER, 'table_hif_prefix_tenses.csv'))

p <- plot_shares(prefix_tenses, colour_var = 'prefix', dodge_width = 0.6,
                 colours = c(BOOK_BLUE, BOOK_ORANGE)) +
  facet_wrap(~ corpus, ncol = 1) +
  theme(panel.spacing.y = unit(0.5, 'cm'))
p
save_book_figure(p, 'fig_hif_prefix_tenses', height = 18)

# ---- 2g. First letter in the imperfect (descriptive; not modelled) ----
# MT imperfect: J- (3rd person) 85% full, T- 91%; the difference is only in
# the forms without a suffix (88% vs 96%).

FIRST_LETTER_LABELS <- c('>' = 'Aleph (1st sg.)', 'J' = 'Yod (3rd person)',
                         'T' = 'Taw (2nd person, 3rd fem.)', 'N' = 'Nun (1st pl.)')
first_letters <- dat |>
  filter(corpus == 'MT', vt %in% c('impf', 'wayq'), first_letter %in% names(FIRST_LETTER_LABELS)) |>
  shares_by(vt, first_letter) |>
  filter(n >= 10) |>
  mutate(row = factor(FIRST_LETTER_LABELS[first_letter], levels = rev(FIRST_LETTER_LABELS)),
         vt = vt_label(vt))
first_letters
write_csv(select(first_letters, -row), file.path(IMAGE_FOLDER, 'table_hif_first_letter.csv'))

p <- plot_shares(first_letters) + facet_wrap(~ vt, ncol = 1) +
  labs(caption = 'MT only; letters with fewer than 10 forms not shown.')
p
save_book_figure(p, 'fig_hif_explore_first_letter', height = 9)

# ---- 2g2. Wayyiqtol by person, ending and suffix (descriptive; 2026-11-12) ----
# Check of the paradigm explanation of the defective wayyiqtol (Suchard 2020,
# 91-94, 248; BOOK_CHANGES_suchard.md). MT only. The wayyiqtol forms with
# hireq are those with a vocalic ending, a pronominal suffix or the 1st person;
# the bare 3rd/2nd person forms have sere (dat_non_hireq) and are never written
# with yod. Result (2026-11-12): wayyiqtol 55-60% full in each group, imperfect
# 80-97%.

wayq_check <- dat |>
  filter(corpus == 'MT', vt %in% c('impf', 'wayq')) |>
  mutate(ending = (nu == 'pl' & ps %in% c('p2', 'p3') & gn != 'f') |
                  (nu == 'sg' & gn == 'f' & ps == 'p2'),
         form_group = case_when(has_prs == 1 ~ 'pronominal suffix',
                                ending ~ 'vocalic ending, no suffix',
                                ps == 'p1' ~ '1st person, no ending or suffix',
                                TRUE ~ '2nd/3rd person without ending')) |>
  shares_by(vt, form_group)
wayq_check
write_csv(wayq_check, file.path(IMAGE_FOLDER, 'table_hif_wayq_form_groups.csv'))
dat_non_hireq |> filter(scroll == 'MT') |> count(vt, has_vowel_letter)   # sere wayyiqtol: 0 of 328 with yod

# ---- 2h. Parallel passages: the same form in the MT and in a scroll ----
# Paired by mt_match (the MT form matched in the preprocessing). The scrolls
# are not fuller than the MT: non-QSP 19 MT fuller vs 18 scroll fuller (262
# both full, 20 both defective), QSP 13 vs 13 (284 both full, 8 both
# defective); data of 2026-10-19.

parallel_table <- parallel_forms_matched(dat, bind_rows(dat, dat_non_hireq)) |>
  select(passage, scroll, corpus, lex, g_cons, mt_g_cons, vt, has_suffix,
         has_vowel_letter, mt_full, pattern)
parallel_table |> count(corpus, pattern)
write_csv(parallel_table, file.path(IMAGE_FOLDER, 'table_hif_parallel_passages.csv'))

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
save_book_figure(p, 'fig_hif_parallel_passages', height = 6)

# ---- 2i. Verb classes (not modelled) ----
# No ע-ע or ל-ה verbs; I-nun 90% full vs 88%; I-yod is one lexeme (38 forms).

dat |>
  mutate(class = case_when(substr(lex, 1, 1) == 'N' ~ 'I-nun',
                           (substr(lex, 1, 1) == 'J' & !lex %in% YOD_VERBS) | lex == 'HLK[' ~ 'I-yod',
                           TRUE ~ 'Other')) |>
  shares_by(class)

# ---- 2j. Lexemes ----
# No single lexeme dominates: NGD[ 280 forms, NYL[ 196, QRB[ 162 (all 90-95%
# full).

lexemes <- dat |>
  group_by(lex) |>
  summarise(n = n(), n_mt = sum(corpus == 'MT'),
            share_full = mean(as.numeric(as.character(has_vowel_letter)))) |>
  arrange(-n)
head(lexemes, 15)
write_csv(lexemes, file.path(IMAGE_FOLDER, 'table_hif_lexemes.csv'))

# ---- 2k. Forms without hireq (not analysed) ----

table(dat_non_hireq$vt, dat_non_hireq$has_vowel_letter)


# ==== 3. DATA MODELLING ====
#
# Decisions (author, 2026-10-15; ../TODO.md):
#   - Random part nested: (1 | scr_book2/lex).
#   - corpus_group with MT Pentateuch as reference; vt with imperfect as
#     reference; has_suffix as in the book.
#   - Priors normal(0, 2.5), exponential(1) on the SDs; prior sensitivity by
#     refitting the final model with sd 1.5 and 4.
#   - Model choice by grouped 5-fold k-fold and the credible-effects rules
#     (../CLAUDE.md); no Bayes factors.
#   - Models: M0 null; M1 corpus; M2 corpus_group; M3 M2 + vt; M4 M3 +
#     has_suffix; M5 M4 + corpus_group x has_suffix; M6 M4 + corpus_group x vt;
#     M7 M4 + both interactions; n9v2 (old final model) for comparison.
#   - corpus_group x vt has three cells that are 100% full (MT LBH infc 75/75
#     and perf 115/115, QSP wayq 9/9); their interaction terms rest partly on
#     the prior.

PRIOR_SD <- 2.5
priors <- book_priors(PRIOR_SD)

# ---- 3a. Prior predictive check ----

model_prior_only <- fit_model('hif_M7_prior_only.rds',
                              has_vowel_letter ~ corpus_group * vt + corpus_group * has_suffix +
                                (1 | scr_book2/lex),
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
save_book_figure(p, 'check_hif_prior_predictive', height = 8)
rm(model_prior_only); gc()

# ---- 3b. Candidate models ----

model_specs <- list(
  M0   = has_vowel_letter ~ 1 + (1 | scr_book2/lex),
  M1   = has_vowel_letter ~ corpus + (1 | scr_book2/lex),
  M2   = has_vowel_letter ~ corpus_group + (1 | scr_book2/lex),
  M3   = has_vowel_letter ~ corpus_group + vt + (1 | scr_book2/lex),
  M4   = has_vowel_letter ~ corpus_group + vt + has_suffix + (1 | scr_book2/lex),
  M5   = has_vowel_letter ~ corpus_group * has_suffix + vt + (1 | scr_book2/lex),
  M6   = has_vowel_letter ~ corpus_group * vt + has_suffix + (1 | scr_book2/lex),
  M7   = has_vowel_letter ~ corpus_group * vt + corpus_group * has_suffix +
           (1 | scr_book2/lex),
  n9v2 = has_vowel_letter ~ vt + has_suffix + (1 | scr_book2/lex),
  # Drop-one models for the final model M7 (rule 4). Dropping a main effect
  # drops its interaction too. The others are already in the set: without
  # corpus_group x has_suffix = M6, without corpus_group x vt = M5, without
  # corpus_group (and both interactions) = n9v2.
  M7_no_vt     = has_vowel_letter ~ corpus_group * has_suffix + (1 | scr_book2/lex),
  M7_no_suffix = has_vowel_letter ~ corpus_group * vt + (1 | scr_book2/lex)
)

model_file <- function(id, scale_b = PRIOR_SD) {
  if (scale_b == PRIOR_SD) paste0('hif_', id, '.rds')
  else paste0('hif_', id, '_prior', scale_b, '.rds')
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
# Result (2026-10-18; elpd diff vs M4, SE): M4 0; M5 -1.5 (5.0); M7 -1.7
# (7.9); M6 -2.8 (6.6); n9v2 -13.7 (9.7); M3 -41.6 (9.1); M2 -178.0 (17.3);
# M0 -193.9 (21.9); M1 -200.6 (21.5). The interactions bring no gain.

set.seed(2026)
folds <- loo::kfold_split_grouped(K = 5, x = as.character(dat$scr_book2))

if (RUN_KFOLD) {
  kfolds <- map(set_names(names(model_specs)),
                \(id) kfold_lazy(model_file(id), paste0('hif_', id, '_k5'), folds))
  kfold_comparison <- loo_compare(kfolds)
  print(kfold_comparison)
  kfold_table <- as.data.frame(kfold_comparison) |>
    rownames_to_column('model') |>
    select(model, elpd_diff, se_diff, elpd_kfold, se_elpd_kfold)
  write_csv(kfold_table, file.path(IMAGE_FOLDER, 'table_hif_kfold.csv'))

  # Drop-one comparison for the final model M7 (elpd_diff = reduced - M7).
  # Known before the new fits: M6 -1.1 (SE 4.8), M5 +0.2 (6.2), n9v2 -12.0 (13.0).
  drop_one <- drop_one_kfold_table(
    kfolds, 'M7',
    c('corpus group x suffix' = 'M6', 'corpus group x tense' = 'M5',
      'corpus group (with its interactions)' = 'n9v2',
      'tense (with corpus group x tense)' = 'M7_no_vt',
      'suffix (with corpus group x suffix)' = 'M7_no_suffix'))
  print(drop_one)
  write_csv(drop_one, file.path(IMAGE_FOLDER, 'table_hif_kfold_drop_one.csv'))
}

# ---- 3d. Robustness ----
# The fullest model M7 without 1QIsaa (252 of the 318 QSP forms) and without
# NGD[ (the largest lexeme), so that every effect can be checked (rule 3(i)).

robustness_specs <- list(
  no_1qisaa = list(file = 'hif_M7_no_1QIsaa.rds', formula = model_specs$M7,
                   data = dat_no_1qisaa),
  no_ngd    = list(file = 'hif_M7_no_NGD.rds', formula = model_specs$M7,
                   data = dat_no_ngd)
)
walk(robustness_specs, function(r) {
  if (!file.exists(file.path(MODEL_FOLDER, r$file))) {
    fit_model(r$file, r$formula, r$data, priors)
    gc()
  }
})

# ---- 3e. Final model ----
# M7 (author, 2026-10-18): corpus_group * vt + corpus_group * has_suffix.
# Credible and robust without 1QIsaa and NGD[: MT other books x suffix and
# non-QSP x suffix (+1.1, +1.75), QSP x wayyiqtol (+3.7; 9 forms, all full,
# 6 lexemes); the tense and suffix effects. No k-fold gain over M4 (-1.7,
# SE 7.9): see REPORT.md (rule 4).

FINAL_ID <- 'M7'

# Prior sensitivity: the final model with sd 1.5 and 4 (2 new fits)
walk(c(1.5, 4), \(scale_b) ensure_model(FINAL_ID, scale_b))

final_model <- load_model(model_file(FINAL_ID))
summary(final_model)

# ==== 4. DATA VISUALISATION ====

# ---- 4a. Table of fixed effects ----

fixed_table <- make_fixed_effects_table(final_model)
fixed_table
write_csv(rownames_to_column(fixed_table, 'parameter'),
          file.path(IMAGE_FOLDER, 'table_hif_fixed_effects.csv'))

# ---- 4b. Effects per corpus group (odds ratios) ----
# Total effect in every corpus group (main effect + interaction where the
# model has one): the corpus group vs the MT Pentateuch (imperfect without
# suffix; and with suffix), the suffix within each group, and each tense vs
# the imperfect within each group (one value for all groups when the model
# has no corpus_group x vt).

CORPUS_COEF <- c('MT Pentateuch' = NA, 'MT Former Prophets' = 'MTFormerProphets',
                 'MT LBH' = 'MTLBH', 'MT other books' = 'MTotherbooks',
                 'Non-QSP' = 'NonMQSP', 'QSP' = 'QSP')
VT_COEF <- c(wayq = 'Wayyiqṭol', perf = 'Perfect', impv = 'Imperative',
             infc = 'Infinitive construct', ptca = 'Participle')
EFFECT_LABELS <- c(corpus        = 'Corpus group (vs MT Pentateuch), no suffix',
                   corpus_suffix = 'Corpus group (vs MT Pentateuch), with suffix',
                   corpus_wayq   = 'Corpus group (vs MT Pentateuch), wayyiqtol',
                   has_suffix1   = 'Suffix (vs none)',
                   setNames(paste0(VT_COEF, ' (vs imperfect)'), paste0('vt', names(VT_COEF))))
EFFECT_LABELS <- sub('wayyiqtol', 'wayyiqṭol', EFFECT_LABELS)

total_effects <- function(model) {
  d <- as_draws_df(model)
  coef_or_0 <- function(name) if (name %in% names(d)) d[[name]] else 0
  has_vt_x <- any(grepl('^b_corpus_group.*:vt', names(d)))
  out <- imap_dfr(CORPUS_COEF, function(g, group) {
    int <- function(eff) if (is.na(g)) 0 else coef_or_0(paste0('b_corpus_group', g, ':', eff))
    bind_rows(
      if (!is.na(g)) bind_rows(
        tibble(effect = 'corpus', value = d[[paste0('b_corpus_group', g)]]),
        tibble(effect = 'corpus_suffix',
               value = d[[paste0('b_corpus_group', g)]] + int('has_suffix1')),
        tibble(effect = 'corpus_wayq',
               value = d[[paste0('b_corpus_group', g)]] + int('vtwayq'))),
      tibble(effect = 'has_suffix1', value = d$b_has_suffix1 + int('has_suffix1')),
      if (has_vt_x) map_dfr(names(VT_COEF), \(v)
        tibble(effect = paste0('vt', v), value = d[[paste0('b_vt', v)]] + int(paste0('vt', v))))
    ) |> mutate(group = group)
  })
  if (!has_vt_x)
    out <- bind_rows(out, map_dfr(names(VT_COEF), \(v)
      tibble(effect = paste0('vt', v), group = 'All groups', value = d[[paste0('b_vt', v)]])))
  out
}

group_order <- c(names(CORPUS_COEF), 'All groups')
effects <- total_effects(final_model) |>
  summarise_effects(effect, group) |>
  mutate(effect_label = factor(EFFECT_LABELS[effect], levels = EFFECT_LABELS),
         group = factor(group, levels = rev(group_order))) |>
  arrange(effect_label, desc(group))
effects
write_csv(effects, file.path(IMAGE_FOLDER, 'table_hif_effects.csv'))

p <- plot_or(mutate(effects, group = fct_recode(group, 'MT Other' = 'MT other books')), group) +
  facet_grid(effect_label ~ ., scales = 'free_y', space = 'free_y', switch = 'y',
             labeller = label_wrap_gen(28)) +
  theme(strip.placement = 'outside',
        strip.text.y.left = element_text(angle = 0, hjust = 1, size = 9),
        axis.text.y.left = element_text(size = 7.5),
        panel.spacing.y = unit(0.35, 'cm'),
        plot.caption.position = 'plot')
p
save_book_figure(p, 'fig_hif_effects', height = 19)

# ---- 4b2. Effects not in the final model ----
# With M7 every modelled effect is in the final model. Not modelled (only
# descriptive, section 2): prefix (rule 3(ii), proxy for the wayyiqtol),
# first letter, verb classes, suffix types. The levels without a credible
# effect are shown in fig_hif_effects with their intervals (rule 2), so no
# separate figure is needed. Only if the author chooses M5 instead of M7:
# corpus_group x vt from M6 as "not in the final model" (QSP x wayyiqtol and
# non-QSP x wayyiqtol are credible there; give the reason in REPORT.md).

if (FINAL_ID == 'M5') {
  vt_x_rows <- expand_grid(g = unname(CORPUS_COEF[-1]), v = names(VT_COEF)) |>
    mutate(label = paste0(VT_COEF[v], ' x ', names(CORPUS_COEF)[match(g, CORPUS_COEF)], ' (extra; M6)'),
           file = model_file('M6'),
           parameter = paste0('b_corpus_group', g, ':vt', v)) |>
    select(label, file, parameter)
  not_in_final <- effects_not_in_final_model(vt_x_rows)
  not_in_final
  write_csv(not_in_final, file.path(IMAGE_FOLDER, 'table_hif_effects_not_in_final_model.csv'))
  p <- plot_effects_not_in_final_model(
    not_in_final, OR_BREAKS, OR_LABELS,
    caption = paste0('Not in the final model. "Extra": the tense effect in the group minus
',
                     'the one in the MT Pentateuch (corpus group x tense, M6).
', OR_CAPTION))
  p
  save_book_figure(p, 'fig_hif_effects_not_in_final_model', height = 16)
}

# ---- 4c. Predicted probability of full spelling ----
# Population level (re_formula = NA): typical scroll-book and lexeme.

newdata <- expand_grid(corpus_group = factor(CORPUS_GROUPS, levels = CORPUS_GROUPS),
                       vt = factor(names(VT_LABELS), levels = levels(dat$vt)),
                       has_suffix = factor(c('0', '1'), levels = levels(dat$has_suffix)))

predicted <- newdata |>
  add_epred_draws(final_model, re_formula = NA) |>
  group_by(corpus_group, vt, has_suffix) |>
  median_qi(.epred, .width = c(0.66, 0.95)) |>
  mutate(suffix = suffix_label(has_suffix),
         tense = vt_label(vt),
         corpus_group = factor(corpus_group, levels = rev(CORPUS_GROUPS)))
predicted
write_csv(predicted, file.path(IMAGE_FOLDER, 'table_hif_predicted.csv'))

p <- predicted |>
  mutate(corpus_group = fct_recode(corpus_group, 'MT Other' = 'MT other books')) |>
  ggplot(aes(y = corpus_group, x = .epred, xmin = .lower, xmax = .upper, colour = suffix)) +
  geom_pointinterval(point_size = 2, interval_size_range = c(0.6, 1.6),
                     position = position_dodge(width = 0.6)) +
  facet_wrap(~ tense, ncol = 2) +
  scale_colour_manual(values = c(BOOK_BLUE, BOOK_ORANGE),
                      guide = guide_legend(reverse = TRUE)) +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25),
                     labels = scales::percent) +
  labs(x = 'Predicted probability of full spelling', y = NULL, colour = NULL,
       caption = paste0(OR_CAPTION, '\nTypical document and lexeme.')) +
  theme_book() +
  theme(panel.spacing.y = unit(0.5, 'cm'), panel.spacing.x = unit(0.8, 'cm'))
p
save_book_figure(p, 'fig_hif_predicted', height = 18)

# ---- 4d. Robustness and prior sensitivity ----
# Key effects in the final model M7, in its robustness fits (without
# 1QIsaa, without NGD[; stored), in M5 and with prior sd 1.5 and 4.

robust_specs <- c(setNames(model_file(FINAL_ID), paste0(FINAL_ID, ' (final)')),
                  'M5'                = model_file('M5'),
                  'M7 without 1QIsaa' = 'hif_M7_no_1QIsaa.rds',
                  'M7 without NGD['   = 'hif_M7_no_NGD.rds',
                  setNames(model_file(FINAL_ID, 1.5), paste0(FINAL_ID, ', prior sd 1.5')),
                  setNames(model_file(FINAL_ID, 4),   paste0(FINAL_ID, ', prior sd 4')))
key_effects <- tribble(
  ~effect,         ~group,
  'corpus',        'MT LBH',
  'corpus',        'MT other books',
  'corpus',        'Non-QSP',
  'corpus',        'QSP',
  'corpus_suffix', 'MT other books',
  'corpus_suffix', 'Non-QSP',
  'corpus_suffix', 'QSP',
  'corpus_wayq',   'MT LBH',
  'corpus_wayq',   'QSP',
  'vtwayq',        'MT Pentateuch',
  'vtwayq',        'QSP',
  'has_suffix1',   'MT Pentateuch',
  'has_suffix1',   'MT other books',
  'has_suffix1',   'Non-QSP',
  'has_suffix1',   'QSP'
)
robustness <- imap_dfr(robust_specs, function(file, variant) {
  m <- if (file == model_file(FINAL_ID)) final_model else load_model(file)
  out <- total_effects(m) |>
    semi_join(key_effects, by = c('effect', 'group')) |>
    summarise_effects(effect, group) |>
    mutate(variant = variant)
  if (file != model_file(FINAL_ID)) { rm(m); gc() }
  out
}) |>
  mutate(effect_label = factor(paste0(EFFECT_LABELS[effect], ': ', group),
                               levels = paste0(EFFECT_LABELS[key_effects$effect], ': ',
                                               key_effects$group)),
         variant = factor(variant, levels = rev(names(robust_specs))))
robustness
write_csv(robustness, file.path(IMAGE_FOLDER, 'table_hif_robustness.csv'))

p <- plot_or(robustness, variant) +
  facet_wrap(~ effect_label, ncol = 2, labeller = label_wrap_gen(40)) +
  labs(caption = paste0('M7 and its robustness fits: imperfect (corpus group effects).\n',
                        OR_CAPTION))
p
save_book_figure(p, 'fig_hif_robustness', height = 20)

# ---- 4e. The book's model 9v2 (comparison with Table 9.57) ----

n9v2_model <- load_model(model_file('n9v2'))
n9v2_table <- make_fixed_effects_table(n9v2_model)
write_csv(rownames_to_column(n9v2_table, 'parameter'),
          file.path(IMAGE_FOLDER, 'table_hif_n9v2_fixed_effects.csv'))
rm(n9v2_model); gc()

# ---- 4f. Random intercepts of the books (check) ----

p <- plot_random_intercepts(final_model, 'scr_book2', text_size = 5) + theme_book()
save_book_figure(p, 'check_hif_random_books', height = 22)


# ==== 5. MODEL VERIFICATION ====

# Convergence, trace and density plots, posterior predictive checks, LOO (for
# completeness; unreliable with the nested structure) and Bayes R2. The
# in-sample classification is optimistic.
verification <- verify_model(final_model, IMAGE_FOLDER, 'check_hif')

# Observed vs predicted share of full spellings per corpus group x suffix,
# per corpus group x tense (does the model reproduce the wayyiqtol gradient
# MT Pentateuch 35% -> LBH 90% and the 100% cells?),
# and for the largest lexemes.
dat$group_suffix <- factor(paste0(dat$corpus_group, if_else(dat$has_suffix == '1', ': suffix', ': no suffix')),
                           levels = paste0(rep(CORPUS_GROUPS, each = 2), c(': no suffix', ': suffix')))
ppc_groups <- group_ppc(final_model, dat, 'group_suffix')
ppc_groups
save_book_figure(plot_ppc(ppc_groups), 'check_hif_ppc_groups', height = 10)

dat$group_vt <- factor(paste0(dat$corpus_group, ': ', vt_label(dat$vt)),
                       levels = paste0(rep(CORPUS_GROUPS, each = length(VT_LABELS)), ': ',
                                       VT_LABELS))
ppc_vt <- group_ppc(final_model, dat, 'group_vt')
ppc_vt
save_book_figure(plot_ppc(ppc_vt), 'check_hif_ppc_tenses', height = 22)

main_lexemes <- c('NGD[', 'NYL[', 'QRB[', 'XZQ[', 'CXT[', 'CLK[', 'NBV[')
dat$lex_main <- factor(if_else(dat$lex %in% main_lexemes, as.character(dat$lex), 'other lexemes'),
                       levels = c(main_lexemes, 'other lexemes'))
ppc_lex <- group_ppc(final_model, dat, 'lex_main')
ppc_lex
save_book_figure(plot_ppc(ppc_lex), 'check_hif_ppc_lexemes', height = 7)
