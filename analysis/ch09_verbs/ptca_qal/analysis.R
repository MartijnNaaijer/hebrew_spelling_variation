################################################################################
# ptca_qal/analysis.R
#
# Dataset:  ptca_qal.csv - qal active participles in the MT and the Dead Sea
#           Scrolls (no SP). Verbs whose participle has no o-vowel in the MT
#           (ML>[, JR>[, >SP[) are excluded: 5716 forms, 410 lexemes.
# Outcome:  has_vowel_letter (1 = o written with waw, e.g. QWVL; 0 =
#           defective, QVL).
# Questions (book section 9.2):
#   1. Do the QSP and non-QSP scrolls spell the participle more fully than the
#      MT?
#   2. Within the MT: do the groups of books differ (Pentateuch, Former
#      Prophets, LBH, other books)?
#   3. How do a suffix (or nominal ending) and a prefix affect the spelling,
#      and do the groups of books differ in this?
#   4. Are I-yod and ayin-ayin verbs fuller, and I-nun verbs more defective,
#      than other verbs (Barr 1989)?
#
# Final model: M7 = corpus_group x (has_suffix + has_prefix + i_yod) + ay_ay
#           + (1 | scr_book2/lex) (author, 2026-10-17). Results: REPORT.md.
#
# Status (2026-10-17): rebuilt on the design of the other verb forms
# (../CLAUDE.md); model set approved by the author (2026-10-16); all models,
# k-folds, drop-one and prior fits stored (runs of 2026-10-16/17); sections
# 4 and 5 written 2026-10-17.
#
# Started from ../../script_ptca_cleaned.R (its CHANGES list documents the bug
# fixes w.r.t. the original script). Changes w.r.t. that script:
#   - Design as the other verb forms: corpus_group (MT split by group of books;
#     non-QSP and QSP one group each, author 2026-10-16) instead of law_phase3,
#     with MT Pentateuch as the reference level; priors normal(0, 2.5) with
#     exponential(1) on the SDs; grouped 5-fold k-fold; no Bayes factors.
#   - The old candidate models (ptca_1..5, crossed, n..n7) are replaced by the
#     model set in section 3. The book's final model ptca_n3 (law_phase3 x
#     suffix, prefix, ayin-ayin and I-yod) is refitted as n3 for comparison;
#     the old 9.6 GB fit in models_rstanarm is not used.
#   - I-nun is tested by k-fold (M3n) instead of a Bayes factor.
#   - has_suffix as in the book (pronominal suffix, nominal ending or he
#     locale); the finer `ending` (none / fem. sg. / masc. pl. / fem. pl. /
#     pronominal suffix) is tested as an alternative (M3e).
#   - New data (preprocessing 2026-10-16): III-he fem. sg. (73 MT forms) and
#     Qoh 10:5 have no ending any more, 5 scroll plural constructs have one;
#     `ending` uses the new column nme_type (see section 1a and REPORT.md).
#   - Prefix types (article, conjunction W, preposition) are descriptive only.
#   - Robustness fits: without JCB[ (588 forms, half of the I-yod forms),
#     without HLK[ (with the article always defective in the MT Pentateuch),
#     without 1QIsaa, and with the two halves of 1QIsaa as separate groups.
#   - Book figures (fig_ptca_*) replace the explore_* plots; the SBL Amsterdam
#     plots, lexeme-frequency plot and console tables are dropped.
#   - Postponed (author, 2026-10-16): the Isaiah manuscripts model (old
#     3b/4b/5b; book section 11, Table 11.20).
#   - Section 6 (teaching demo for the chapter on hierarchical models) is kept
#     unchanged in content (unsaved console plots dropped), but only runs
#     with RUN_APPENDIX = TRUE.
#
# CHANGES 2026-10-17 (harmonisation, ../TODO.md section 13):
#   - Effect intervals: quantile intervals (66% and 95%) instead of HDI, with
#     the shared summarise_effects() and plot_or() from ../functions.R (as in
#     the other verb forms; author, 2026-10-17). Medians and pd unchanged;
#     the interval bounds change slightly.
#
# CHANGES 2026-10-19 (book section 9.2, BOOK_CHANGES_9.2.md):
#   - Check model M7_iii_h (M7 + iii_h; fitted 2026-10-19 with the author's
#     approval) and its k-fold: iii_h beta 0.50 [0.11, 0.87], pd 0.994, but
#     -1.6 elpd (SE 3.0) against M7. M7 stays the final model.
#   - Book figures: section 2a2 (fig_ptca_groups_all and the five
#     *_groups splits by law_phase3), one figure per effect
#     (fig_ptca_effect_suffix, _prefix, _iyod), fig_ptca_effect_ayay (M7
#     effect plus the M6 group differences); fig_ptca_predicted with
#     'MT Other' and Hebrew labels.
#
# CHANGES 2026-11-03 (BOOK_CHANGES_9.9.md, decision E1 (a)):
#   - Robustness fit of M7_iii_h without ZNH[ (section 3d; 5674 forms): iii_h
#     0.25 [-0.13, 0.64], pd 0.902, so it is no longer credible. The ל״ה effect is a lexeme
#     effect of זנה (rule 3(i)); M7 stays the final model.
################################################################################


# ==== 0. SETUP ====

library(tidyverse)
library(brms)
library(bayesplot)
library(tidybayes)
library(bayestestR)
library(binom)
library(loo)
library(ggpubr)   # ggarrange() (section 6)

ANALYSIS_DIR <- 'C:/Users/geitb/Dropbox/monograph_orthography/verbs/analysis_verbs'
VERB_FORM <- 'ptca_qal'
IMAGE_FOLDER <- file.path(ANALYSIS_DIR, VERB_FORM, 'figures')

source(file.path(ANALYSIS_DIR, 'config.R'))
source(file.path(ANALYSIS_DIR, 'functions.R'))

DATASET <- 'ptca_qal.csv'

# Verbs whose participles have no o-sound in MT
NOT_USEFUL_VERBS <- c('ML>[', 'JR>[', '>SP[')

# ALLOW_FIT = FALSE: only load stored results; stop instead of fitting.
ALLOW_FIT <- FALSE  # all models fitted (runs of 2026-10-16 and 2026-10-17)
options(analysis_verbs.allow_fit = ALLOW_FIT)
RUN_KFOLD <- TRUE
RUN_APPENDIX <- FALSE  # section 6 (teaching demo; fits 3 small models)


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

dat <- dat |>
  filter(!lex %in% NOT_USEFUL_VERBS, scroll != 'SP') |>
  arrange(tf_id) |>
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

# Corpus group (6 levels). Reference level: MT Pentateuch (author, 2026-10-15).
# Non-QSP is one group (author, 2026-10-16): the book's split of the non-QSP
# scrolls has a group of 7 forms (LBH) and one of 36 (Former Prophets).
CORPUS_GROUPS <- c('MT Pentateuch', 'MT Former Prophets', 'MT LBH', 'MT other books',
                   'Non-QSP', 'QSP')
dat$corpus_group <- factor(case_when(dat$corpus == 'MT' & dat$book_group == 'Other' ~ 'MT other books',
                                     dat$corpus == 'MT' ~ paste('MT', dat$book_group),
                                     TRUE ~ as.character(dat$corpus)),
                           levels = CORPUS_GROUPS)

# law_phase3 (the book's 'doc_group': non-QSP split into 4 groups), only for
# the comparison model n3. Reference level MT Pentateuch, as in the book.
dat$law_phase3 <- droplevels(dat$law_phase3)
stopifnot(levels(dat$law_phase3)[1] == 'MT Pentateuch')

# has_suffix as in the book: pronominal suffix, nominal ending or he locale
# (add_col_has_suffix()). There are no he-locale forms.
stopifnot(all(dat$has_hloc == 0))

# Ending (as in ptcp_qal). A pronominal suffix takes precedence over the
# nominal ending it is attached to (e.g. R<JK). The nominal ending comes from
# the column nme_type of the dataset (preprocessing of 2026-10-16): the written
# ending nme cannot distinguish a fem. pl. without waw (-T, e.g. C>BT Gen
# 24:11; 28 MT forms) from a fem. sg. In the same preprocessing (author,
# 2026-10-16; REPORT.md, "Suffix or ending"): a fem. sg. whose written ending
# is only the last root letter has no ending (73 MT III-he forms like ZWNH, as
# the masculine; JY> in Qoh 10:5), and 5 scroll plural constructs (JWCBJ etc.)
# have an ending. has_suffix (via has_nme) follows these corrections.
dat$ending <- factor(if_else(dat$has_prs == 1, 'pron_suffix', dat$nme_type),
                     levels = c('none', 'fem_sg', 'masc_pl', 'fem_pl', 'pron_suffix'))
stopifnot(!anyNA(dat$ending))
# Plurals without written ending or suffix: nme_type masc_pl, has_suffix 0
# (1QIsaa Isa 14:19 JWRDW, 8Q3 Deut 11:7 RW>NN).
dat |> filter(ending != 'none', has_suffix == '0') |>
  select(scroll, book, chapter, verse, lex, g_cons, nu, gn, nme, ending)
ENDING_LABELS <- c(none = 'No ending', fem_sg = 'Fem. sg. -H/-T',
                   masc_pl = 'Masc. pl. -JM/-J', fem_pl = 'Fem. pl. -WT/-T',
                   pron_suffix = 'Pronominal suffix')
ending_label <- function(ending) factor(ENDING_LABELS[as.character(ending)],
                                        levels = ENDING_LABELS)

# Prefix type (descriptive only). Article: H alone or after W/M; preposition:
# B, K, L, M (also after W); relative C and the rare combinations as 'Other'.
dat$prefix_type <- factor(case_when(dat$has_prefix == 0 ~ 'none',
                                    dat$prefix %in% c('H', 'WH', 'MH', 'HK', 'HL') ~ 'article',
                                    dat$prefix == 'W' ~ 'conjunction',
                                    dat$prefix %in% c('B', 'K', 'L', 'M', 'WB', 'WK', 'WL', 'WM', 'KR') ~ 'preposition',
                                    TRUE ~ 'other'),
                          levels = c('none', 'article', 'conjunction', 'preposition', 'other'))
PREFIX_LABELS <- c(none = 'No prefix', article = 'Article (H-)', conjunction = 'Conjunction W-',
                   preposition = 'Preposition (B-, K-, L-, M-)', other = 'Other (C-)')
prefix_type_label <- function(prefix_type) factor(PREFIX_LABELS[as.character(prefix_type)],
                                                  levels = PREFIX_LABELS)

# Verb classes. I-yod: original I-waw verbs and HLK[ (YOD_VERBS, the original
# I-yod verbs, are not counted).
dat$ay_ay <- factor(as.numeric(substr(dat$lex, 2, 2) == substr(dat$lex, 3, 3)))
dat$i_yod <- factor(as.numeric((substr(dat$lex, 1, 1) == 'J' & !(dat$lex %in% YOD_VERBS)) |
                                 dat$lex == 'HLK['))
dat$i_nun <- factor(as.numeric(substr(dat$lex, 1, 1) == 'N'))
dat$iii_h <- factor(as.numeric(substr(dat$lex, 3, 3) == 'H'))   # check model M7_iii_h only

# Robustness: the two halves of 1QIsaa separate from the other QSP scrolls.
dat$corpus_group_isa <- factor(case_when(dat$scroll == '1QisaaI' ~ '1QIsaa I',
                                         dat$scroll == '1QisaaII' ~ '1QIsaa II',
                                         TRUE ~ as.character(dat$corpus_group)),
                               levels = c(CORPUS_GROUPS, '1QIsaa I', '1QIsaa II'))

dat_no_1qisaa <- dat |> filter(!scroll %in% c('1QisaaI', '1QisaaII')) |> droplevels()
dat_no_jcb    <- dat |> filter(lex != 'JCB[') |> droplevels()   # largest lexeme, 588 forms
dat_no_hlk    <- dat |> filter(lex != 'HLK[') |> droplevels()

dim(dat)                                       # 5716 forms
length(unique(dat$lex))                        # 410 lexemes
table(dat$corpus_group, dat$has_vowel_letter)
table(dat$corpus_group, dat$has_suffix)
table(dat$corpus_group, dat$has_prefix)
table(dat$corpus_group, dat$i_yod)
table(dat$corpus_group, dat$ay_ay)
table(dat$corpus_group, dat$i_nun)
table(dat$ending, dat$corpus)
table(dat$prefix_type, dat$corpus)


# ==== 2. EXPLORATORY ANALYSIS ====

suffix_label <- function(has_suffix) factor(if_else(has_suffix == 1, 'With suffix or ending',
                                                    'Without suffix or ending'),
                                            levels = c('Without suffix or ending',
                                                       'With suffix or ending'))
prefix_label <- function(has_prefix) factor(if_else(has_prefix == 1, 'With prefix', 'Without prefix'),
                                            levels = c('Without prefix', 'With prefix'))

# ---- 2a. Groups of books ----
# MT Pentateuch 7% full, Former Prophets 12%, LBH 26%, other books 25%;
# non-QSP 32%, QSP 86% (book Figure 9.1).

groups <- shares_by(dat, corpus_group) |>
  mutate(row = fct_rev(corpus_group))
groups
write_csv(select(groups, -row), file.path(IMAGE_FOLDER, 'table_ptca_groups.csv'))

p <- plot_shares(groups)
p
save_book_figure(p, 'fig_ptca_groups', height = 7)

# The book's groups (Figure 9.1), with the non-QSP scrolls split
groups_phase3 <- shares_by(dat, law_phase3)
groups_phase3
write_csv(groups_phase3, file.path(IMAGE_FOLDER, 'table_ptca_groups_law_phase3.csv'))

# ---- 2a2. Book figures by document group (Figs. 9.1-9.6) ----
# The book's document groups (law_phase3, the non-QSP scrolls split by group
# of books), as in the other sections of the book; descriptive only (the
# models use corpus_group). Non-QSP LBH has 7 forms.

groups_all <- groups_phase3 |> mutate(row = fct_rev(law_phase3))
p <- plot_shares(groups_all)
p
save_book_figure(p, 'fig_ptca_groups_all', height = 8)

group_split <- function(var, labels, name) {
  tab <- shares_by(dat, law_phase3, value = .data[[var]]) |>
    mutate(row = fct_rev(law_phase3),
           split = factor(labels[as.character(value)], levels = labels))
  write_csv(md_to_csv(select(tab, -row)), file.path(IMAGE_FOLDER, paste0('table_', name, '.csv')))
  p <- plot_shares(tab, colour_var = 'split', dodge_width = 0.6,
                   colours = c(BOOK_BLUE, BOOK_ORANGE)) +
    markdown_legend()
  save_book_figure(p, name, height = 13)
  tab
}
group_split('has_suffix', c('0' = 'Without suffix or ending', '1' = 'With suffix or ending'),
            'fig_ptca_suffix_groups')
group_split('has_prefix', c('0' = 'Without prefix', '1' = 'With prefix'), 'fig_ptca_prefix_groups')
group_split('i_yod', c('0' = 'Other verbs', '1' = paste(heb_md('פ״ו'), 'verbs')), 'fig_ptca_iyod_groups')
group_split('ay_ay', c('0' = 'Other verbs', '1' = paste(heb_md('ע״ע'), 'verbs')), 'fig_ptca_ayay_groups')
group_split('iii_h', c('0' = 'Other verbs', '1' = paste(heb_md('ל״ה'), 'verbs')), 'fig_ptca_iiih_groups')

# ---- 2b. Suffix or ending per group of books ----
# A suffix or ending roughly halves fullness in every MT group (Pentateuch 10%
# -> 2%, LBH 42% -> 18%) and in the non-QSP scrolls (40% -> 20%); none in QSP
# (86% vs 86%).

suffix_groups <- shares_by(dat, corpus_group, has_suffix) |>
  mutate(row = fct_rev(corpus_group), suffix = suffix_label(has_suffix))
suffix_groups
write_csv(select(suffix_groups, -row), file.path(IMAGE_FOLDER, 'table_ptca_suffix.csv'))

p <- plot_shares(suffix_groups, colour_var = 'suffix', dodge_width = 0.6,
                 colours = c(BOOK_BLUE, BOOK_ORANGE))
p
save_book_figure(p, 'fig_ptca_suffix', height = 9)

# ---- 2c. Endings per corpus ----
# MT: no ending 26%, fem. sg. 25%, masc. pl. 12%, fem. pl. 6%, pronominal
# suffix 11%; the fem. sg. behaves like no ending (cf. ptcp_qal).

endings <- shares_by(dat, corpus, ending) |>
  mutate(row = fct_rev(ending_label(ending)))
endings
write_csv(select(endings, -row), file.path(IMAGE_FOLDER, 'table_ptca_endings.csv'))

p <- plot_shares(endings) + facet_wrap(~ corpus, ncol = 1) +
  theme(panel.spacing.y = unit(0.6, 'cm'))
p
save_book_figure(p, 'fig_ptca_endings', height = 14)

# ---- 2d. Prefix per group of books ----
# Lower with a prefix only in MT Pentateuch (8% -> 4%), MT other books (27% ->
# 21%) and non-QSP (34% -> 28%); no difference elsewhere.

prefix_groups <- shares_by(dat, corpus_group, has_prefix) |>
  mutate(row = fct_rev(corpus_group), prefix = prefix_label(has_prefix))
prefix_groups
write_csv(select(prefix_groups, -row), file.path(IMAGE_FOLDER, 'table_ptca_prefix.csv'))

p <- plot_shares(prefix_groups, colour_var = 'prefix', dodge_width = 0.6,
                 colours = c(BOOK_BLUE, BOOK_ORANGE))
p
save_book_figure(p, 'fig_ptca_prefix', height = 9)

# ---- 2e. Prefix types (descriptive) ----
# Barr (1989, 65-66): HLK[ with the article is always defective in the
# Pentateuch. MT Pentateuch: article 3% (6/207) vs no prefix 8%; HLK[ with
# the article 0/16 vs 10/17 without a prefix. Outside the MT Pentateuch the
# article makes no difference (31% vs 33%).

prefix_types <- shares_by(mutate(dat, data = if_else(corpus_group == 'MT Pentateuch',
                                                     'MT Pentateuch', 'Other groups')),
                          data, prefix_type) |>
  mutate(row = fct_rev(prefix_type_label(prefix_type)))
prefix_types
write_csv(select(prefix_types, -row), file.path(IMAGE_FOLDER, 'table_ptca_prefix_types.csv'))

p <- plot_shares(prefix_types) + facet_wrap(~ data, ncol = 1) +
  theme(panel.spacing.y = unit(0.6, 'cm'))
p
save_book_figure(p, 'fig_ptca_explore_prefix_types', height = 11)

hlk_prefix <- shares_by(filter(dat, lex == 'HLK['), corpus_group, prefix_type)
hlk_prefix
write_csv(hlk_prefix, file.path(IMAGE_FOLDER, 'table_ptca_hlk_prefix.csv'))

# ---- 2f. Verb classes per corpus ----
# I-yod fuller in MT (37% vs 15%) and non-QSP (49% vs 27%), not in QSP; also
# without JCB[ and HLK[ (MT 44%). Ayin-ayin fuller in MT (41% vs 19%; only 7
# non-QSP forms). I-nun more defective in MT (10% vs 21%), little difference
# in the scrolls.

class_label <- c(i_yod = 'I-yod verbs', ay_ay = 'Ayin-ayin verbs', i_nun = 'I-nun verbs',
                 iii_h = 'III-he verbs (not modelled)')
classes <- map_dfr(names(class_label), function(v) {
  shares_by(dat, corpus, .data[[v]]) |>
    rename(member = all_of(v)) |>
    mutate(class = class_label[[v]],
           verbs = factor(if_else(member == 1, 'Verbs of the class', 'Other verbs'),
                          levels = c('Other verbs', 'Verbs of the class')))
}) |>
  bind_rows(shares_by(filter(dat, i_yod == 1, !lex %in% c('JCB[', 'HLK[')), corpus) |>
              mutate(class = 'I-yod verbs', verbs = 'I-yod without JCB[ and HLK[')) |>
  mutate(class = factor(class, levels = class_label),
         verbs = factor(verbs, levels = c('Other verbs', 'Verbs of the class',
                                          'I-yod without JCB[ and HLK[')),
         row = fct_rev(corpus))
classes
write_csv(select(classes, -row, -member), file.path(IMAGE_FOLDER, 'table_ptca_verb_classes.csv'))

p <- plot_shares(classes, colour_var = 'verbs', dodge_width = 0.8) +
  facet_wrap(~ class, ncol = 1) +
  theme(panel.spacing.y = unit(0.6, 'cm'))
p
save_book_figure(p, 'fig_ptca_verb_classes', height = 20)

# Verb classes per corpus group (the cells of the interaction models)
classes_groups <- map_dfr(c('i_yod', 'ay_ay', 'i_nun'), function(v) {
  shares_by(dat, corpus_group, .data[[v]]) |> rename(member = all_of(v)) |>
    mutate(class = class_label[[v]])
})
classes_groups
write_csv(classes_groups, file.path(IMAGE_FOLDER, 'table_ptca_verb_classes_groups.csv'))

# ---- 2g. Lexemes ----

lexemes <- dat |>
  group_by(lex) |>
  summarise(n = n(), n_mt = sum(corpus == 'MT'),
            share_full = mean(as.numeric(as.character(has_vowel_letter))),
            i_yod = first(i_yod), ay_ay = first(ay_ay), i_nun = first(i_nun)) |>
  arrange(-n)
head(lexemes, 15)
write_csv(lexemes, file.path(IMAGE_FOLDER, 'table_ptca_lexemes.csv'))

# ---- 2h. Parallel passages: the same form in the MT and in a scroll ----
# Non-QSP: 101 scroll fuller vs 22 MT fuller (330 both defective, 55 both
# full); QSP: 375 vs 4 (80, 123). Per scroll as in book Tables 9.2-9.15,
# except 4Q51 (9 instead of 8 scroll fuller) and 1QIsaa I/II and the QSP and
# non-QSP totals (1-2 forms differ; pairing by parallel_forms()).

parallel_table <- parallel_forms(dat, occ = raw_occurrences('ptc_qal')) |>  # raw-text pairing, 2026-11-05
  select(passage, scroll, corpus, corpus_group_isa, lex, g_cons, mt_g_cons, has_suffix,
         has_prefix, has_vowel_letter, mt_full, pattern)
parallel_table |> count(corpus, pattern)
write_csv(parallel_table, file.path(IMAGE_FOLDER, 'table_ptca_parallel_passages.csv'))

# Per scroll (book Tables 9.2-9.15) and per half of 1QIsaa (Tables 9.12-9.13)
parallel_by_scroll <- parallel_table |>
  count(corpus, scroll, pattern) |>
  pivot_wider(names_from = pattern, values_from = n, values_fill = 0) |>
  mutate(n = rowSums(across(where(is.numeric)))) |>
  arrange(corpus, -n)
parallel_by_scroll |> print(n = 30)
write_csv(parallel_by_scroll, file.path(IMAGE_FOLDER, 'table_ptca_parallel_by_scroll.csv'))

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
save_book_figure(p, 'fig_ptca_parallel_passages', height = 6)


# ==== 3. DATA MODELLING ====
#
# Decisions (author, 2026-10-16; ../TODO.md):
#   - Random part nested: (1 | scr_book2/lex).
#   - corpus_group with MT Pentateuch as reference (non-QSP one group);
#     has_suffix as in the book.
#   - Priors normal(0, 2.5), exponential(1) on the SDs; prior sensitivity by
#     refitting the final model with sd 1.5 and 4.
#   - Model choice by grouped 5-fold k-fold and the credible-effects rules
#     (../CLAUDE.md); no Bayes factors.
#   - Models: M0 null; M1 corpus; M2 corpus_group; M3 M2 + suffix + prefix +
#     I-yod + ayin-ayin; M4 M3 + corpus_group x suffix; M5 M4 + corpus_group
#     x prefix; M6 M5 + corpus_group x I-yod + corpus_group x ayin-ayin; M3n
#     M3 + I-nun; M3e M3 with `ending` instead of has_suffix; n3 (the book's
#     model, law_phase3) for comparison.
#   - Small cells: ayin-ayin has 7 non-QSP forms (and 10-16 in MT Pentateuch,
#     Former Prophets and LBH); these interaction terms rest partly on the
#     prior. In n3, several law_phase3 cells are empty (non-QSP LBH: 7 forms,
#     no prefix, I-yod or ayin-ayin; ayin-ayin in the non-QSP Pentateuch and
#     Former Prophets); their coefficients are prior only.
#   - Sampler: warmup 1000, iter 3000 (8000 draws) instead of the default
#     2000/6000, to keep the ~65 fits on 5716 forms within about a day.

PRIOR_SD <- 2.5
FIT_WARMUP <- 1000
FIT_ITER <- 3000
priors <- book_priors(PRIOR_SD)

model_specs <- list(
  M0  = has_vowel_letter ~ 1 + (1 | scr_book2/lex),
  M1  = has_vowel_letter ~ corpus + (1 | scr_book2/lex),
  M2  = has_vowel_letter ~ corpus_group + (1 | scr_book2/lex),
  M3  = has_vowel_letter ~ corpus_group + has_suffix + has_prefix + i_yod + ay_ay +
          (1 | scr_book2/lex),
  M4  = has_vowel_letter ~ corpus_group * has_suffix + has_prefix + i_yod + ay_ay +
          (1 | scr_book2/lex),
  M5  = has_vowel_letter ~ corpus_group * has_suffix + corpus_group * has_prefix +
          i_yod + ay_ay + (1 | scr_book2/lex),
  M6  = has_vowel_letter ~ corpus_group * has_suffix + corpus_group * has_prefix +
          corpus_group * i_yod + corpus_group * ay_ay + (1 | scr_book2/lex),
  M3n = has_vowel_letter ~ corpus_group + has_suffix + has_prefix + i_yod + ay_ay + i_nun +
          (1 | scr_book2/lex),
  M3e = has_vowel_letter ~ corpus_group + ending + has_prefix + i_yod + ay_ay +
          (1 | scr_book2/lex),
  n3  = has_vowel_letter ~ has_suffix * law_phase3 + has_prefix * law_phase3 +
          ay_ay * law_phase3 + i_yod * law_phase3 + (1 | scr_book2/lex),
  # Final model (author, 2026-10-17): M6 without corpus_group x ay_ay, the
  # only interaction with no credible level; has_suffix instead of ending.
  M7  = has_vowel_letter ~ corpus_group * has_suffix + corpus_group * has_prefix +
          corpus_group * i_yod + ay_ay + (1 | scr_book2/lex),
  # Check model for the book (author, 2026-10-19): M7 + III-he verbs (the
  # book's Bayes-factor result for ל״ה is replaced by this k-fold comparison).
  M7_iii_h = has_vowel_letter ~ corpus_group * has_suffix + corpus_group * has_prefix +
          corpus_group * i_yod + ay_ay + iii_h + (1 | scr_book2/lex)
)
# Drop-one comparison for the final model M7 (rule 4). Without
# corpus_group x i_yod, M7 is M5, which is already in the list.
M7_DROP_ONE <- c(M7_no_suffix_x = 'corpus_group:has_suffix',
                 M7_no_prefix_x = 'corpus_group:has_prefix',
                 M7_no_ay_ay    = 'ay_ay')
model_specs <- c(model_specs,
                 imap(M7_DROP_ONE, \(term, id) update(model_specs$M7,
                                                     as.formula(paste('. ~ . -', term)))))

model_file <- function(id, scale_b = PRIOR_SD) {
  if (scale_b == PRIOR_SD) paste0('ptca_', id, '.rds')
  else paste0('ptca_', id, '_prior', scale_b, '.rds')
}

fit_ptca <- function(file_name, formula, data, priors, ...) {
  fit_model(file_name, formula, data, priors, warmup = FIT_WARMUP, iter = FIT_ITER, ...)
}

# ---- 3a. Prior predictive check ----

model_prior_only <- fit_ptca('ptca_M6_prior_only.rds', model_specs$M6, dat, priors,
                             sample_prior = 'only')

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
save_book_figure(p, 'check_ptca_prior_predictive', height = 8)
rm(model_prior_only); gc()

# ---- 3b. Candidate models ----

ensure_model <- function(id, scale_b = PRIOR_SD) {
  if (!file.exists(file.path(MODEL_FOLDER, model_file(id, scale_b)))) {
    fit_ptca(model_file(id, scale_b), model_specs[[id]], dat,
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
  print(VarCorr(m))
  rm(m); gc()
}

# ---- 3c. Grouped k-fold cross-validation ----
# 5 folds; every scroll-book is left out as a whole.

set.seed(2026)
folds <- loo::kfold_split_grouped(K = 5, x = as.character(dat$scr_book2))

if (RUN_KFOLD) {
  kfolds <- map(set_names(names(model_specs)),
                \(id) kfold_lazy(model_file(id), paste0('ptca_', id, '_k5'), folds))
  kfold_comparison <- loo_compare(kfolds)
  print(kfold_comparison)
  kfold_table <- as.data.frame(kfold_comparison) |>
    rownames_to_column('model') |>
    select(model, elpd_diff, se_diff, elpd_kfold, se_elpd_kfold)
  write_csv(kfold_table, file.path(IMAGE_FOLDER, 'table_ptca_kfold.csv'))

  # Final model M7 against the model without each of its effects (rule 4).
  drop_one <- drop_one_kfold_table(
    kfolds, 'M7',
    c('corpus group x suffix' = 'M7_no_suffix_x', 'corpus group x prefix' = 'M7_no_prefix_x',
      'corpus group x I-yod' = 'M5', 'ע-ע verbs' = 'M7_no_ay_ay'))
  print(drop_one)
  write_csv(drop_one, file.path(IMAGE_FOLDER, 'table_ptca_kfold_drop_one.csv'))
}

# ---- 3d. Robustness ----
# The fullest model M6 without JCB[ (I-yod), without HLK[ (I-yod; prefix in
# the MT Pentateuch), without 1QIsaa (457 of the 640 QSP forms), and with the
# two halves of 1QIsaa as separate groups, so that every effect can be checked
# (rule 3(i)).

isa_formula <- has_vowel_letter ~ corpus_group_isa * has_suffix + corpus_group_isa * has_prefix +
  corpus_group_isa * i_yod + corpus_group_isa * ay_ay + (1 | scr_book2/lex)

robustness_specs <- list(
  no_jcb    = list(file = 'ptca_M6_no_JCB.rds', formula = model_specs$M6, data = dat_no_jcb),
  no_hlk    = list(file = 'ptca_M6_no_HLK.rds', formula = model_specs$M6, data = dat_no_hlk),
  no_1qisaa = list(file = 'ptca_M6_no_1QIsaa.rds', formula = model_specs$M6,
                   data = dat_no_1qisaa),
  isa_split = list(file = 'ptca_M6_1QIsaa_split.rds', formula = isa_formula, data = dat)
)
walk(robustness_specs, function(r) {
  if (!file.exists(file.path(MODEL_FOLDER, r$file))) {
    fit_ptca(r$file, r$formula, r$data, priors)
    gc()
  }
})

# Check model M7_iii_h without ZNH[ (decision E1 (a), author 2026-11-03;
# BOOK_CHANGES_9.9.md). ZNH[ has 42 forms, 29 of them full (the lexicalised
# זוֹנָה). Fitted 2026-11-03 on 5674 forms: iii_h median 0.25, 95% [-0.13,
# 0.64], pd 0.902; no longer credible, so the ל״ה effect is a lexeme effect of
# זנה (rule 3(i)) and M7 stays the final model. Max Rhat 1.006, min bulk ESS
# 1277, no divergences.
dat_no_znh <- dat |> filter(lex != 'ZNH[') |> droplevels()
model_iii_h_no_znh <- fit_ptca('ptca_M7_iii_h_no_ZNH.rds', model_specs$M7_iii_h,
                               dat_no_znh, priors)
tibble(value = as_draws_df(model_iii_h_no_znh)$b_iii_h1) |> summarise_effects()
rm(model_iii_h_no_znh); gc()

# ---- 3e. Final model ----
# M7 (author, 2026-10-17). Credible and robust without JCB[, HLK[ and 1QIsaa
# (M6 robustness fits): QSP x suffix, corpus_group x prefix, QSP x I-yod,
# ayin-ayin. Not credible: corpus_group x ay_ay, i_nun (M3n). The
# interactions bring no k-fold gain (M4-M6 below M3); see REPORT.md.

FINAL_ID <- 'M7'

# Prior sensitivity: the final model with sd 1.5 and 4
walk(c(1.5, 4), \(scale_b) ensure_model(FINAL_ID, scale_b))

final_model <- load_model(model_file(FINAL_ID))
summary(final_model)


# ==== 4. DATA VISUALISATION ====

# ---- 4a. Table of fixed effects ----

fixed_table <- make_fixed_effects_table(final_model)
fixed_table
write_csv(rownames_to_column(fixed_table, 'parameter'),
          file.path(IMAGE_FOLDER, 'table_ptca_fixed_effects.csv'))

# ---- 4b. Effects per corpus group (odds ratios) ----
# With the interactions, a coefficient alone is the effect in the MT
# Pentateuch only. The figure shows the total effect in every corpus group
# (main effect + interaction): the corpus group vs the MT Pentateuch (form
# without suffix or prefix, not I-yod), and the effect of a suffix or ending,
# a prefix and I-yod within each group. Ayin-ayin is one effect for all
# groups (no credible interaction, M6).

CORPUS_COEF <- c('MT Pentateuch' = NA, 'MT Former Prophets' = 'MTFormerProphets',
                 'MT LBH' = 'MTLBH', 'MT other books' = 'MTotherbooks',
                 'Non-QSP' = 'NonMQSP', 'QSP' = 'QSP')
EFFECT_LABELS <- c(corpus = 'Corpus group (vs MT Pentateuch)',
                   has_suffix1 = 'Suffix or ending (vs none)',
                   has_prefix1 = 'Prefix (vs none)',
                   i_yod1 = 'I-yod verb (vs other verbs)',
                   ay_ay1 = 'Ayin-ayin verb (vs other verbs)')

# Draws of the total effects of a model with corpus_group interactions (M6,
# M7 and their robustness and prior fits). In M6 the ayin-ayin effect is the
# one in the MT Pentateuch.
total_effects <- function(model) {
  d <- as_draws_df(model)
  coef_or_0 <- function(name) if (name %in% names(d)) d[[name]] else 0
  imap_dfr(CORPUS_COEF, function(g, group) {
    bind_rows(
      if (!is.na(g)) tibble(effect = 'corpus', value = d[[paste0('b_corpus_group', g)]]),
      map_dfr(c('has_suffix1', 'has_prefix1', 'i_yod1'), function(eff) {
        interaction <- if (is.na(g)) 0 else coef_or_0(paste0('b_corpus_group', g, ':', eff))
        tibble(effect = eff, value = d[[paste0('b_', eff)]] + interaction)
      })
    ) |>
      mutate(group = group)
  }) |>
    bind_rows(tibble(effect = 'ay_ay1', group = 'All groups', value = d$b_ay_ay1))
}

# Summaries with summarise_effects() and plot_or() from ../functions.R
# (median, 66% and 95% quantile intervals, pd; harmonised 2026-10-17).
group_order <- c(names(CORPUS_COEF), 'All groups')
effects <- total_effects(final_model) |>
  summarise_effects(effect, group) |>
  mutate(effect_label = factor(EFFECT_LABELS[effect], levels = EFFECT_LABELS),
         group = factor(group, levels = rev(group_order))) |>
  arrange(effect_label, desc(group))
effects
write_csv(effects, file.path(IMAGE_FOLDER, 'table_ptca_effects.csv'))

p <- plot_or(effects, group) +
  facet_grid(effect_label ~ ., scales = 'free_y', space = 'free_y', switch = 'y') +
  theme(strip.placement = 'outside', strip.text.y.left = element_text(angle = 0, hjust = 1),
        plot.caption.position = 'plot')
p
save_book_figure(p, 'fig_ptca_effects', height = 16)

# One figure per effect for the book (Figs. 9.8-9.10): the effect in each
# corpus group; 'MT Other' as in the book.
effect_figure <- function(eff, name) {
  tab <- effects |>
    filter(effect == eff) |>
    mutate(group = fct_recode(droplevels(group), 'MT Other' = 'MT other books'))
  p <- plot_or(tab, group)
  save_book_figure(p, name, height = 7)
  p
}
effect_figure('has_suffix1', 'fig_ptca_effect_suffix')
effect_figure('has_prefix1', 'fig_ptca_effect_prefix')
effect_figure('i_yod1', 'fig_ptca_effect_iyod')

# ---- 4b2. Effects not in the final model ----
# No credible effect (rule 1); estimates from the comparison models. The
# finer coding of the ending (M3e) is shown as an alternative to has_suffix.

not_in_final <- effects_not_in_final_model(tribble(
  ~label,                                          ~file,             ~parameter,
  'I-nun verb (M3n)',                              model_file('M3n'), 'b_i_nun1',
  'Ayin-ayin x MT Former Prophets (extra; M6)',    model_file('M6'),  'b_corpus_groupMTFormerProphets:ay_ay1',
  'Ayin-ayin x MT LBH (extra; M6)',                model_file('M6'),  'b_corpus_groupMTLBH:ay_ay1',
  'Ayin-ayin x MT other books (extra; M6)',        model_file('M6'),  'b_corpus_groupMTotherbooks:ay_ay1',
  'Ayin-ayin x non-QSP (extra; M6)',               model_file('M6'),  'b_corpus_groupNonMQSP:ay_ay1',
  'Ayin-ayin x QSP (extra; M6)',                   model_file('M6'),  'b_corpus_groupQSP:ay_ay1',
  'Ending: fem. sg. (M3e, vs none)',               model_file('M3e'), 'b_endingfem_sg',
  'Ending: masc. pl. (M3e, vs none)',              model_file('M3e'), 'b_endingmasc_pl',
  'Ending: fem. pl. (M3e, vs none)',               model_file('M3e'), 'b_endingfem_pl',
  'Ending: pronominal suffix (M3e, vs none)',      model_file('M3e'), 'b_endingpron_suffix'
))
not_in_final
write_csv(not_in_final, file.path(IMAGE_FOLDER, 'table_ptca_effects_not_in_final_model.csv'))
p <- plot_effects_not_in_final_model(
  not_in_final, OR_BREAKS, OR_LABELS,
  caption = paste0('Not in the final model M7. "Extra": vs ayin-ayin in the MT Pentateuch.\n',
                   'Endings (M3e): the finer coding of has_suffix, without interactions.\n',
                   OR_CAPTION))
p
save_book_figure(p, 'fig_ptca_effects_not_in_final_model', height = 9)

# ע״ע for the book (Fig. 9.11): the common effect of M7 and, in grey, the
# group-specific differences from MT Pentateuch in M6 (not credible, not in
# the final model).
ayay_tab <- bind_rows(
  effects |> filter(effect == 'ay_ay1') |>
    mutate(label = paste(heb_md('ע״ע'), 'verbs (all groups)'),
           panel = 'Retained model', type = 'final'),
  not_in_final |> filter(grepl('^Ayin-ayin x', label)) |>
    mutate(label = sub('^Ayin-ayin x (.*) \\(extra; M6\\)$', '\\1', as.character(label)),
           label = recode(label, 'MT other books' = 'MT Other', 'non-QSP' = 'Non-QSP'),
           panel = 'Check model: difference from MT Pentateuch', type = 'check')
) |>
  mutate(label = factor(label, levels = rev(unique(label))),
         panel = factor(panel, levels = c('Retained model',
                                          'Check model: difference from MT Pentateuch')))
p <- ggplot(ayay_tab, aes(y = label, x = exp(value), colour = type)) +
  geom_vline(xintercept = 1, colour = BOOK_GREY, linewidth = 0.5) +
  geom_linerange(aes(xmin = exp(.lower), xmax = exp(.upper)), linewidth = 0.6) +
  geom_linerange(aes(xmin = exp(lower66), xmax = exp(upper66)), linewidth = 1.6) +
  geom_point(size = 2.5) +
  scale_colour_manual(values = c(final = BOOK_BLUE, check = BOOK_GREY), guide = 'none') +
  scale_x_log10(breaks = OR_BREAKS, labels = OR_LABELS) +
  facet_grid(panel ~ ., scales = 'free_y', space = 'free_y', switch = 'y',
             labeller = label_wrap_gen(22)) +
  labs(x = 'Odds ratio for full spelling (log scale)', y = NULL, caption = OR_CAPTION) +
  theme_book() +
  theme(strip.placement = 'outside', strip.text.y.left = element_text(angle = 0, hjust = 1),
        plot.caption.position = 'plot') +
  markdown_y()
p
save_book_figure(p, 'fig_ptca_effect_ayay', height = 7)

# ---- 4c. Predicted probability of full spelling ----
# Population level (re_formula = NA): a typical scroll-book and lexeme, not a
# ayin-ayin verb. Table: with and without suffix, prefix and I-yod; figure:
# suffix x prefix for other verbs.

newdata <- expand_grid(corpus_group = factor(CORPUS_GROUPS, levels = CORPUS_GROUPS),
                       has_suffix = factor(c('0', '1'), levels = levels(dat$has_suffix)),
                       has_prefix = factor(c('0', '1'), levels = levels(dat$has_prefix)),
                       i_yod = factor(c('0', '1'), levels = levels(dat$i_yod))) |>
  mutate(ay_ay = factor('0', levels = levels(dat$ay_ay)))

predicted <- newdata |>
  add_epred_draws(final_model, re_formula = NA) |>
  group_by(corpus_group, has_suffix, has_prefix, i_yod) |>
  median_qi(.epred, .width = c(0.66, 0.95)) |>
  mutate(suffix_lab = factor(if_else(has_suffix == '1', 'Suffix or ending', 'No suffix or ending'),
                             levels = c('No suffix or ending', 'Suffix or ending')),
         prefix_lab = factor(if_else(has_prefix == '1', 'With prefix', 'Without prefix'),
                             levels = c('Without prefix', 'With prefix')),
         corpus_group = factor(corpus_group, levels = rev(CORPUS_GROUPS)))
predicted
write_csv(predicted, file.path(IMAGE_FOLDER, 'table_ptca_predicted.csv'))

p <- predicted |>
  filter(i_yod == '0') |>
  mutate(corpus_group = fct_recode(corpus_group, 'MT Other' = 'MT other books')) |>
  ggplot(aes(y = corpus_group, x = .epred, xmin = .lower, xmax = .upper, colour = suffix_lab)) +
  geom_pointinterval(point_size = 2.5, interval_size_range = c(0.8, 2),
                     position = position_dodge(width = 0.6)) +
  facet_wrap(~ prefix_lab) +
  scale_colour_manual(values = c(BOOK_BLUE, BOOK_ORANGE),
                      guide = guide_legend(reverse = TRUE)) +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25),
                     labels = scales::percent) +
  labs(x = 'Predicted probability of full spelling', y = NULL, colour = NULL,
       caption = paste0(OR_CAPTION, '<br>Typical document and lexeme; not a ', heb_md('פ״ו'),
                        ' or ', heb_md('ע״ע'), ' verb.')) +
  theme_book() +
  theme(panel.spacing.x = unit(0.8, 'cm')) +
  markdown_caption()
p
save_book_figure(p, 'fig_ptca_predicted', height = 9)

# ---- 4d. Robustness and prior sensitivity ----
# The key effects in M7, in M6 (with corpus_group x ay_ay), in M6 without
# JCB[, HLK[ and 1QIsaa, and in M7 with priors sd 1.5 and 4.

robust_specs <- c('M7 (final)'           = model_file('M7'),
                  'M6'                   = model_file('M6'),
                  'M6 without JCB['      = 'ptca_M6_no_JCB.rds',
                  'M6 without HLK['      = 'ptca_M6_no_HLK.rds',
                  'M6 without 1QIsaa'    = 'ptca_M6_no_1QIsaa.rds',
                  'M7, prior sd 1.5'     = model_file('M7', 1.5),
                  'M7, prior sd 4'       = model_file('M7', 4))
key_effects <- tribble(
  ~effect,       ~group,
  'corpus',      'MT other books',
  'corpus',      'Non-QSP',
  'corpus',      'QSP',
  'has_suffix1', 'MT Pentateuch',
  'has_suffix1', 'QSP',
  'has_prefix1', 'MT Pentateuch',
  'has_prefix1', 'MT other books',
  'i_yod1',      'MT Pentateuch',
  'i_yod1',      'QSP',
  'ay_ay1',      'All groups'
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
write_csv(robustness, file.path(IMAGE_FOLDER, 'table_ptca_robustness.csv'))

p <- plot_or(robustness, variant) +
  facet_wrap(~ effect_label, ncol = 2, labeller = label_wrap_gen(40)) +
  labs(caption = paste0('Ayin-ayin in M6 and its robustness fits: the effect in the MT Pentateuch\n',
                        '(M6 has a corpus group x ayin-ayin interaction).\n', OR_CAPTION))
p
save_book_figure(p, 'fig_ptca_robustness', height = 22)

# The two halves of 1QIsaa as separate groups (M6 with corpus_group_isa).
isa_split <- load_model('ptca_M6_1QIsaa_split.rds')
isa_table <- as_draws_df(isa_split) |>
  select(matches('^b_corpus_group_isa(QSP|1QIsaa)')) |>
  pivot_longer(everything(), names_to = 'parameter') |>
  summarise_effects(parameter)
isa_table
write_csv(isa_table, file.path(IMAGE_FOLDER, 'table_ptca_1qisaa_split.csv'))
rm(isa_split); gc()

# ---- 4e. The book's model n3 (comparison with Table 9.16) ----

n3_model <- load_model(model_file('n3'))
n3_table <- make_fixed_effects_table(n3_model)
write_csv(rownames_to_column(n3_table, 'parameter'),
          file.path(IMAGE_FOLDER, 'table_ptca_n3_fixed_effects.csv'))
rm(n3_model); gc()

# ---- 4f. Random intercepts of the books (check) ----

p <- plot_random_intercepts(final_model, 'scr_book2', text_size = 5) + theme_book()
save_book_figure(p, 'check_ptca_random_books', height = 22)


# ==== 5. MODEL VERIFICATION ====

# Convergence, trace and density plots, posterior predictive checks, LOO (for
# completeness; unreliable with the nested structure) and Bayes R2. The
# in-sample classification it prints is optimistic.
verification <- verify_model(final_model, IMAGE_FOLDER, 'check_ptca')

# Observed vs predicted share of full spellings per corpus group and suffix,
# per verb class and for the most frequent lexemes.
dat$group_suffix <- factor(paste0(dat$corpus_group, if_else(dat$has_suffix == '1', ': suffix', ': no suffix')),
                           levels = paste0(rep(CORPUS_GROUPS, each = 2), c(': no suffix', ': suffix')))
ppc_groups <- group_ppc(final_model, dat, 'group_suffix')
ppc_groups
save_book_figure(plot_ppc(ppc_groups), 'check_ptca_ppc_groups', height = 10)

dat$verb_class <- factor(paste0(dat$corpus, ': ',
                                case_when(dat$i_yod == '1' ~ 'I-yod', dat$ay_ay == '1' ~ 'ayin-ayin',
                                          dat$i_nun == '1' ~ 'I-nun', TRUE ~ 'other')),
                         levels = paste0(rep(levels(dat$corpus), each = 4), ': ',
                                         c('I-yod', 'ayin-ayin', 'I-nun', 'other')))
ppc_class <- group_ppc(final_model, dat, 'verb_class')
ppc_class
save_book_figure(plot_ppc(ppc_class), 'check_ptca_ppc_verb_classes', height = 9)

main_lexemes <- c('JCB[', '<FH[', 'HLK[', 'NTN[', '<MD[', '>MR[', 'JY>[')
dat$lex_main <- factor(if_else(dat$lex %in% main_lexemes, as.character(dat$lex), 'other lexemes'),
                       levels = c(main_lexemes, 'other lexemes'))
ppc_lex <- group_ppc(final_model, dat, 'lex_main')
ppc_lex
save_book_figure(plot_ppc(ppc_lex), 'check_ptca_ppc_lexemes', height = 7)


# ==== 6. APPENDIX: POOLED, UNPOOLED AND PARTIALLY POOLED MODELS ====
# EXPLANATION BAYESIAN MODEL FOR BOOK CHAPTER ON EXPLANATION OF HIERARCHICAL
# MODELING (MT Pentateuch and LBH only). Unchanged in content from
# ../../script_ptca_cleaned.R (old priors via fit_or_load()); only runs with
# RUN_APPENDIX = TRUE.

if (RUN_APPENDIX) {

mt_pent_lbh <- dat |> filter(scroll == 'MT') |> filter(book %in% LAW_BOOKS | book %in% LBH_BOOKS)
mt_pent_lbh <- droplevels(mt_pent_lbh)
mt_pent_lbh$book2 <- factor(mt_pent_lbh$book2, levels = c("Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
                                                          "Esther", "Daniel", "Ezra", "Nehemiah", "Chronicles"))

levels(mt_pent_lbh$book2)
table(mt_pent_lbh$law_phase2, mt_pent_lbh$has_vowel_letter)
table(mt_pent_lbh$has_suffix, mt_pent_lbh$has_vowel_letter)

# FREQUENCIES OF LEXEMES IN ESTHER AND CHRONICLES
est_chr_mt <- mt_pent_lbh |> filter(book2 %in% c('Chronicles', 'Esther')) |> droplevels()
lex_df <- as.data.frame.matrix(table(est_chr_mt$lex, est_chr_mt$book2))
lex_df$lex <- rownames(lex_df)
lex_df$Esther <- lex_df$Esther * -1

lex_df_melt <- lex_df |>
  pivot_longer(c(Chronicles, Esther), names_to = 'variable', values_to = 'value') |>
  mutate(variable = factor(variable, levels = c('Chronicles', 'Esther')))

p <- lex_df_melt %>%
  ggplot(aes(x = lex, y = value, group = variable, fill = variable)) +
  geom_bar(stat = "identity", width = 0.75) +
  coord_flip() +
  scale_y_continuous(breaks = seq(-50, 50, 2),
                     labels = abs(seq(-50, 50, 2))) +
  labs(x = "", y = "Count", title = "") +
  theme(legend.position = "bottom",
        legend.title = element_blank(),
        plot.title = element_text(hjust = 0.5),
        panel.background = element_rect(fill =  "grey90")) +
  guides(fill = guide_legend(reverse = TRUE)) +
  scale_fill_manual(values = c("red", "blue"),
                    name = "",
                    breaks = c("Chronicles", "Esther"),
                    labels = c("Chronicles", "Esther"))
print(p)
ggsave(file.path(IMAGE_FOLDER, 'ptca_lexeme_counts_est_chr.png'), p)

prior_intercept_prob_mt_pent_lbh <- mean(as.numeric(as.character(mt_pent_lbh$has_vowel_letter)))
prior_intercept_logit_mt_pent_lbh <- prob2logit(prior_intercept_prob_mt_pent_lbh)

# POOLED MODEL
formula_practice_ptca <- has_vowel_letter ~ has_suffix
bayes_model_practice <- fit_or_load('bayes_model_ptca_practice_pooled.rds', mt_pent_lbh,
                                    formula_practice_ptca, prior_intercept_logit_mt_pent_lbh,
                                    warmup = 1000, iter = 2000, adapt_delta = 0.9)
summary(bayes_model_practice)

# UNPOOLED MODEL
formula_practice_ptca_unpooled <- has_vowel_letter ~ has_suffix*book2
bayes_model_practice_unpooled <- fit_or_load('bayes_model_ptca_practice_unpooled.rds', mt_pent_lbh,
                                             formula_practice_ptca_unpooled, prior_intercept_logit_mt_pent_lbh,
                                             warmup = 2000, iter = 4000, adapt_delta = 0.9)
summary(bayes_model_practice_unpooled)

# PARTIAL POOLING
formula_practice_ptca_part_pool <- has_vowel_letter ~ has_suffix + (1 | book2)
bayes_model_practice_part_pool <- fit_or_load('bayes_model_ptca_practice_part_pool.rds', mt_pent_lbh,
                                              formula_practice_ptca_part_pool, prior_intercept_logit_mt_pent_lbh,
                                              warmup = 1000, iter = 2000, adapt_delta = 0.97)
summary(bayes_model_practice_part_pool)
ranef(bayes_model_practice_part_pool)

# Partially pooled model figures
fixed_draws_part_pool <- bayes_model_practice_part_pool %>%
  spread_draws(b_Intercept, b_has_suffix1,
               `r_book2[Genesis,Intercept]`,
               `r_book2[Exodus,Intercept]`, `r_book2[Leviticus,Intercept]`, `r_book2[Numbers,Intercept]`,
               `r_book2[Deuteronomy,Intercept]`, `r_book2[Esther,Intercept]`, `r_book2[Daniel,Intercept]`,
               `r_book2[Ezra,Intercept]`, `r_book2[Nehemiah,Intercept]`, `r_book2[Chronicles,Intercept]`)

summary_ptca_part_pool <- fixed_draws_part_pool %>%
  transmute(
    'Genesis without suffix' = b_Intercept + `r_book2[Genesis,Intercept]`,
    'Genesis with suffix' = b_Intercept + b_has_suffix1 + `r_book2[Genesis,Intercept]`,
    'Exodus without suffix' = b_Intercept + `r_book2[Exodus,Intercept]`,
    'Exodus with suffix' = b_Intercept + b_has_suffix1 + `r_book2[Exodus,Intercept]`,
    'Leviticus without suffix' = b_Intercept + `r_book2[Leviticus,Intercept]`,
    'Leviticus with suffix' = b_Intercept + b_has_suffix1 + `r_book2[Leviticus,Intercept]`,
    'Numbers without suffix' = b_Intercept + `r_book2[Numbers,Intercept]`,
    'Numbers with suffix' = b_Intercept + b_has_suffix1 + `r_book2[Numbers,Intercept]`,
    'Deuteronomy without suffix' = b_Intercept + `r_book2[Deuteronomy,Intercept]`,
    'Deuteronomy with suffix' = b_Intercept + b_has_suffix1 + `r_book2[Deuteronomy,Intercept]`,
    'Esther without suffix' = b_Intercept + `r_book2[Esther,Intercept]`,
    'Esther with suffix' = b_Intercept + b_has_suffix1 + `r_book2[Esther,Intercept]`,
    'Daniel without suffix' = b_Intercept + `r_book2[Daniel,Intercept]`,
    'Daniel with suffix' = b_Intercept + b_has_suffix1 + `r_book2[Daniel,Intercept]`,
    'Ezra without suffix' = b_Intercept + `r_book2[Ezra,Intercept]`,
    'Ezra with suffix' = b_Intercept + b_has_suffix1 + `r_book2[Ezra,Intercept]`,
    'Nehemiah without suffix' = b_Intercept + `r_book2[Nehemiah,Intercept]`,
    'Nehemiah with suffix' = b_Intercept + b_has_suffix1 + `r_book2[Nehemiah,Intercept]`,
    'Chronicles without suffix' = b_Intercept + `r_book2[Chronicles,Intercept]`,
    'Chronicles with suffix' = b_Intercept + b_has_suffix1 + `r_book2[Chronicles,Intercept]`
  ) %>%
  gather() %>%
  group_by(key) %>%
  mean_hdi(.width = c(.95, .66))

labels_ptca_books <- c(
  'Chronicles with suffix', 'Chronicles without suffix',
  'Nehemiah with suffix', 'Nehemiah without suffix',
  'Ezra with suffix', 'Ezra without suffix',
  'Daniel with suffix', 'Daniel without suffix',
  'Esther with suffix', 'Esther without suffix',
  'Deuteronomy with suffix', 'Deuteronomy without suffix',
  'Numbers with suffix', 'Numbers without suffix',
  'Leviticus with suffix', 'Leviticus without suffix',
  'Exodus with suffix', 'Exodus without suffix',
  'Genesis with suffix', 'Genesis without suffix'
)

summary_ptca_part_pool$key <- factor(summary_ptca_part_pool$key, levels = labels_ptca_books)
summary_ptca_part_pool$prob_value <- logit2prob(summary_ptca_part_pool$value)
summary_ptca_part_pool$prob_lower <- logit2prob(summary_ptca_part_pool$.lower)
summary_ptca_part_pool$prob_upper <- logit2prob(summary_ptca_part_pool$.upper)

globals_part_pool <- fixed_draws_part_pool %>%
  transmute(
    'global_no_suffix' = b_Intercept,
    'globalwith_suffix' = b_Intercept + b_has_suffix1
  ) %>%
  gather() %>%
  group_by(key) %>%
  mean_hdi(.width = c(.95))
globals_part_pool
global_intercept <- globals_part_pool$value[1] |> logit2prob()
global_with_suffix <- globals_part_pool$value[2] |> logit2prob()

p <- summary_ptca_part_pool %>%
  ggplot(aes(y = key, x = prob_value, xmin = prob_lower, xmax = prob_upper)) +
  geom_pointinterval() +
  geom_vline(xintercept = global_intercept, linetype = "dotted", color = "blue", linewidth = 1.5) +
  geom_vline(xintercept = global_with_suffix, linetype = "dotted", color = "red", linewidth = 1.5) +
  xlim(0, 1) +
  xlab('Probability') +
  ylab('') +
  ggtitle('')
print(p)
ggsave(file.path(IMAGE_FOLDER, 'ptca_partially_model_blue_red_lines.png'), p)

# Unpooled model figure
fixed_draws <- bayes_model_practice_unpooled %>%
  spread_draws(b_Intercept, b_has_suffix1,
               b_book2Chronicles,
               b_book2Daniel, b_book2Deuteronomy, b_book2Esther,
               b_book2Exodus, b_book2Ezra,
               b_book2Leviticus, b_book2Nehemiah, b_book2Numbers,
               `b_has_suffix1:book2Chronicles`, `b_has_suffix1:book2Daniel`, `b_has_suffix1:book2Deuteronomy`,
               `b_has_suffix1:book2Esther`, `b_has_suffix1:book2Exodus`, `b_has_suffix1:book2Ezra`,
               `b_has_suffix1:book2Leviticus`, `b_has_suffix1:book2Nehemiah`,
               `b_has_suffix1:book2Numbers`)

summary_ptca_unpooled <- fixed_draws %>%
  transmute(
    'Genesis without suffix' = b_Intercept,
    'Genesis with suffix' = b_Intercept + b_has_suffix1,
    'Exodus without suffix' = b_Intercept + b_book2Exodus,
    'Exodus with suffix' = b_Intercept + b_has_suffix1 + b_book2Exodus + `b_has_suffix1:book2Exodus`,
    'Leviticus without suffix' = b_Intercept + b_book2Leviticus,
    'Leviticus with suffix' = b_Intercept + b_has_suffix1 + b_book2Leviticus + `b_has_suffix1:book2Leviticus`,
    'Numbers without suffix' = b_Intercept + b_book2Numbers,
    'Numbers with suffix' = b_Intercept + b_has_suffix1 + b_book2Numbers + `b_has_suffix1:book2Numbers`,
    'Deuteronomy without suffix' = b_Intercept + b_book2Deuteronomy,
    'Deuteronomy with suffix' = b_Intercept + b_has_suffix1 + b_book2Deuteronomy + `b_has_suffix1:book2Deuteronomy`,
    'Esther without suffix' = b_Intercept + b_book2Esther,
    'Esther with suffix' = b_Intercept + b_has_suffix1 + b_book2Esther + `b_has_suffix1:book2Esther`,
    'Daniel without suffix' = b_Intercept + b_book2Daniel,
    'Daniel with suffix' = b_Intercept + b_has_suffix1 + b_book2Daniel + `b_has_suffix1:book2Daniel`,
    'Ezra without suffix' = b_Intercept + b_book2Ezra,
    'Ezra with suffix' = b_Intercept + b_has_suffix1 + b_book2Ezra + `b_has_suffix1:book2Ezra`,
    'Nehemiah without suffix' = b_Intercept + b_book2Nehemiah,
    'Nehemiah with suffix' = b_Intercept + b_has_suffix1 + b_book2Nehemiah + `b_has_suffix1:book2Nehemiah`,
    'Chronicles without suffix' = b_Intercept + b_book2Chronicles,
    'Chronicles with suffix' = b_Intercept + b_has_suffix1 + b_book2Chronicles + `b_has_suffix1:book2Chronicles`
  ) %>%
  gather() %>%
  group_by(key) %>%
  mean_hdi(.width = c(.95, .66))

summary_ptca_unpooled$key <- factor(summary_ptca_unpooled$key, levels = labels_ptca_books)
summary_ptca_unpooled$prob_value <- logit2prob(summary_ptca_unpooled$value)
summary_ptca_unpooled$prob_lower <- logit2prob(summary_ptca_unpooled$.lower)
summary_ptca_unpooled$prob_upper <- logit2prob(summary_ptca_unpooled$.upper)

# IMAGE OF UNPOOLED MODEL WITH GLOBAL VALUES OF HIERARCHICAL MODEL to make comparison
p <- summary_ptca_unpooled %>%
  ggplot(aes(y = key, x = prob_value, xmin = prob_lower, xmax = prob_upper)) +
  geom_pointinterval() +
  geom_vline(xintercept = global_intercept, linetype = "dotted", color = "blue", linewidth = 1.5) +
  geom_vline(xintercept = global_with_suffix, linetype = "dotted", color = "red", linewidth = 1.5) +
  xlim(0, 1) +
  xlab('Probability') +
  ylab('') +
  ggtitle('')
print(p)
ggsave(file.path(IMAGE_FOLDER, 'ptca_unpooled_model_blue_red_lines.png'), p)

figure_unpooled <- summary_ptca_unpooled %>%
  ggplot(aes(y = key, x = prob_value, xmin = prob_lower, xmax = prob_upper)) +
  geom_pointinterval() +
  theme(axis.title.y = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank()) +
  geom_vline(xintercept = global_intercept, linetype = "dotted", color = "blue", linewidth = 1.5) +
  geom_vline(xintercept = global_with_suffix, linetype = "dotted", color = "red", linewidth = 1.5) +
  xlim(0, 0.75) +
  xlab('Probability') +
  ylab('') +
  ggtitle('Unpooled model')

figure_part_pooled <- summary_ptca_part_pool %>%
  ggplot(aes(y = key, x = prob_value, xmin = prob_lower, xmax = prob_upper)) +
  geom_pointinterval() +
  geom_vline(xintercept = global_intercept, linetype = "dotted", color = "blue", linewidth = 1.5) +
  geom_vline(xintercept = global_with_suffix, linetype = "dotted", color = "red", linewidth = 1.5) +
  xlim(0, 0.75) +
  xlab('Probability') +
  ylab('') +
  ggtitle('Partially pooled model')

p <- ggarrange(figure_part_pooled,
               figure_unpooled + theme(axis.ticks.y = element_blank()),
               ncol = 2,
               nrow = 1,
               align = 'h')
print(p)
ggsave(file.path(IMAGE_FOLDER, 'ptca_partially_pooled_and_unpooled_model.png'), p)

}  # end RUN_APPENDIX
