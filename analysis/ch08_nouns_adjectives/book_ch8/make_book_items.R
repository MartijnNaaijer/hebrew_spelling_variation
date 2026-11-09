################################################################################
# Book items for chapter 8 (phase 3 of ../BOOK_PLAN_8.md), made 2026-11-03.
#
# Figures and tables that the analysis scripts do not make, built from their
# CSV tables and (for the model summaries only) from the stored final fits.
# Nothing is fitted. Decisions: Claude doc "Chapter 8 revision" (author,
# 2026-11-03).
#
#   fig_finalw_effects, fig_singlew_effects, fig_firstw_effects,
#   fig_finaly_effects_not_in_final_model ... : redrawn with the noun breaks
#       (Figures 8.5, 8.17, 8.27)
#   fig_finaly_predicted        Figure 8.11: predicted probability with and
#                               without a suffix
#   fig_singlew_kol_robustness  Figure 8.18: effects with and without KL/
#   fig_firstw_prefix_robustness Figure 8.28: prefix with and without <WLM/ JWBL/
#   fig_affix_waw_effects_book  Figure 8.33: endings and suffixes, waw words
#   fig_affix_yod_effects_book  Figure 8.35: endings and suffixes, yod words
#   fig_affix_yod_effects_prefix_type_book  Figure 8.36: prefix types, yod
#                               words, one panel (the model has no interactions)
#   fig_finaly/singley/firsty_effects_not_in_final_model: redrawn with the
#                               note on three lines (Figures 8.11 old, 8.23, 8.32)
#   table_ch8_model_summaries.csv  intercept and SDs of the final models,
#                               median and 95% quantile interval (Tables
#                               8.10, 8.15, 8.20, 8.24, 8.32, 8.33)
#
# Run:  Rscript make_book_items.R [output folder]
# With an output folder (for testing), everything goes there; without it,
# figures go to the figures/ folder of their dataset and the table to this
# folder.
################################################################################

suppressMessages({
  library(tidyverse)
  library(brms)
})

ANALYSIS_DIR <- 'C:/Users/geitb/Dropbox/monograph_orthography/nouns_adjectives/analysis_nouns'
source(file.path(ANALYSIS_DIR, 'config.R'))
source(file.path(VERBS_DIR, 'functions.R'))
source(file.path(ANALYSIS_DIR, 'functions_nouns.R'))

args <- commandArgs(trailingOnly = TRUE)
TEST_FOLDER <- if (length(args) > 0) args[1] else NA
out_folder <- function(id) {
  if (!is.na(TEST_FOLDER)) TEST_FOLDER
  else if (id == 'book') file.path(ANALYSIS_DIR, 'book_ch8')
  else file.path(ANALYSIS_DIR, id, 'figures')
}
fig_csv <- function(id, tag, name) {
  read_csv(file.path(ANALYSIS_DIR, id, 'figures', paste0('table_', tag, '_', name, '.csv')),
           show_col_types = FALSE)
}
GROUP_LEVELS <- names(CORPUS_GROUP_COEF)

# ---- 1. Effects figures with the noun breaks ----------------------------------

for (d in list(c('final_w', 'finalw'), c('single_w', 'singlew'), c('first_w', 'firstw'))) {
  effects <- fig_csv(d[1], d[2], 'effects') |>
    mutate(group = factor(group, levels = rev(c(GROUP_LEVELS, 'All groups'))),
           effect_label = factor(effect_label, levels = NOUN_EFFECT_LABELS))
  save_book_figure(effects_figure(effects), paste0('fig_', d[2], '_effects'), height = 12,
                   folder = out_folder(d[1]))
}

# ---- 1b. Effects not in the final model (final_y, single_y, first_y) ----------
# The analysis scripts draw these with a one-line note that runs off the right
# edge; redrawn with the note on separate lines and with the noun breaks.

NOT_IN_FINAL_CAPTION <- paste0('Not in the final model; estimates from M2 (corpus group),\n',
                               'M3 (common affix effect) and M6 (affix effect per group).\n',
                               OR_CAPTION)
for (d in list(c('final_y', 'finaly'), c('single_y', 'singley'), c('first_y', 'firsty'))) {
  effects <- fig_csv(d[1], d[2], 'effects_not_in_final_model') |>
    mutate(group = factor(group, levels = rev(c(GROUP_LEVELS, 'All groups'))),
           effect_label = factor(effect_label, levels = NOUN_EFFECT_LABELS))
  save_book_figure(effects_figure(effects, caption = NOT_IN_FINAL_CAPTION, colour = BOOK_GREY),
                   paste0('fig_', d[2], '_effects_not_in_final_model'), height = 14,
                   folder = out_folder(d[1]))
}

# ---- 2. Figure 8.11: final_y, predicted probability with and without suffix ----

pred <- fig_csv('final_y', 'finaly', 'predicted') |>
  select(has_suffix, .epred, .lower, .upper, .width) |>
  pivot_wider(names_from = .width, values_from = c(.lower, .upper)) |>
  mutate(label = factor(if_else(has_suffix == 1, 'With suffix', 'Without suffix'),
                        levels = c('With suffix', 'Without suffix')))
p <- ggplot(pred, aes(y = label, x = .epred)) +
  geom_linerange(aes(xmin = .lower_0.95, xmax = .upper_0.95), colour = BOOK_BLUE, linewidth = 0.6) +
  geom_linerange(aes(xmin = .lower_0.66, xmax = .upper_0.66), colour = BOOK_BLUE, linewidth = 1.6) +
  geom_point(colour = BOOK_BLUE, size = 2.5) +
  scale_x_continuous(limits = c(0.5, 1), labels = scales::percent) +
  labs(x = 'Predicted probability of full spelling', y = NULL,
       caption = paste0('Lexeme of average fullness in a typical document.
', OR_CAPTION)) +
  theme_book() + theme(plot.caption.position = 'plot')
save_book_figure(p, 'fig_finaly_predicted', height = 5, folder = out_folder('final_y'))

# ---- 3. Robustness figures (two variants side by side) ------------------------

robustness_pair <- function(tab, keep, variants, variant_labels, height) {
  one_effect <- n_distinct(keep$effect) == 1
  p <- tab |>
    filter(variant %in% variants) |>
    semi_join(keep, by = c('effect', 'group')) |>
    mutate(variant = factor(variant_labels[variant], levels = rev(variant_labels)),
           group = book_group_labels(factor(group, levels = rev(GROUP_LEVELS))),
           effect_label = factor(NOUN_EFFECT_LABELS[effect], levels = NOUN_EFFECT_LABELS)) |>
    ggplot(aes(y = group, x = exp(value), colour = variant)) +
    geom_vline(xintercept = 1, colour = BOOK_GREY, linewidth = 0.5) +
    geom_linerange(aes(xmin = exp(.lower), xmax = exp(.upper)), linewidth = 0.6,
                   position = position_dodge(width = 0.6)) +
    geom_linerange(aes(xmin = exp(lower66), xmax = exp(upper66)), linewidth = 1.6,
                   position = position_dodge(width = 0.6)) +
    geom_point(size = 2.3, position = position_dodge(width = 0.6)) +
    scale_x_log10(breaks = NOUN_OR_BREAKS, labels = NOUN_OR_LABELS) +
    scale_colour_manual(values = c(BOOK_BLUE, BOOK_ORANGE), breaks = unname(variant_labels)) +
    labs(x = if (one_effect) paste('Odds ratio for full spelling,',
                                   tolower(NOUN_EFFECT_LABELS[[keep$effect[1]]]), '(log scale)')
             else 'Odds ratio for full spelling (log scale)',
         y = NULL, caption = OR_CAPTION) +
    theme_book() + markdown_legend() +
    theme(plot.caption.position = 'plot')
  if (one_effect) return(p)
  p + facet_grid(effect_label ~ ., scales = 'free_y', space = 'free_y', switch = 'y',
                 labeller = label_wrap_gen(20)) +
    theme(strip.placement = 'outside', strip.text.y.left = element_text(angle = 0, hjust = 1))
}

# Figure 8.18 (single_w): the effects that change without KL/, with MT
# Pentateuch as reference for the affixes.
kol_keep <- tribble(~effect, ~group,
  'corpus', 'Non-QSP', 'corpus', 'QSP',
  'has_suffix1', 'MT Pentateuch', 'has_suffix1', 'Non-QSP', 'has_suffix1', 'QSP',
  'has_prefix1', 'MT Pentateuch', 'has_prefix1', 'Non-QSP', 'has_prefix1', 'QSP')
p <- robustness_pair(fig_csv('single_w', 'singlew', 'robustness'), kol_keep,
                     c('M6 (final)', 'M6 without KL/'),
                     c('M6 (final)' = 'All lexemes',
                       'M6 without KL/' = paste('Without', heb_md('כל'))),
                     height = 11)
save_book_figure(p, 'fig_singlew_kol_robustness', height = 11, folder = out_folder('single_w'))

# Figure 8.28 (first_w): the prefix effect in every group, with and without
# Barr's examples.
barr_keep <- tibble(effect = 'has_prefix1', group = GROUP_LEVELS)
p <- robustness_pair(fig_csv('first_w', 'firstw', 'robustness'), barr_keep,
                     c('M6 (final)', 'M6 without <WLM/ JWBL/'),
                     c('M6 (final)' = 'All lexemes',
                       'M6 without <WLM/ JWBL/' = paste('Without', heb_md('עולם'), 'and',
                                                        heb_md('יובל'))),
                     height = 9)
save_book_figure(p, 'fig_firstw_prefix_robustness', height = 9, folder = out_folder('first_w'))

# ---- 4. Figures 8.33 and 8.35: endings and suffixes in one figure --------------

AFFIX_HEBREW <- c('-H' = 'ה', '-T' = 'ת', '-JM' = 'ים', '-M' = 'ם', '-J' = 'י', '-WT' = 'ות',
                  '-K' = 'ך', '-W' = 'ו', '-NW' = 'נו', '-KM' = 'כם', '-HM' = 'הם')
AFFIX_ORDER <- c('fem. sg. -H', 'fem. sg. -T', 'masc. pl. -JM', 'masc. pl. -M', 'masc. pl. constr. -J',
                 'fem. pl. -WT', 'fem. pl. -T',
                 '1 sg. -J', '2 sg. -K', '3 m. sg. -W', '3 f. sg. -H', '1 pl. -NW', '2 m. pl. -KM',
                 '3 m. pl. -HM', '3 m. pl. -M')
hebrew_category <- function(x) {
  code <- str_extract(x, '-[A-Z]+$')
  paste(str_remove(x, ' -[A-Z]+$'), heb_md(AFFIX_HEBREW[code]))
}
affix_figure <- function(letter, by_group) {
  tab <- read_csv(file.path(ANALYSIS_DIR, 'affix_types_mt', 'figures',
                            paste0('table_affix_', letter, '_effects.csv')), show_col_types = FALSE) |>
    filter(variable %in% c('nme2', 'prs2'))
  if (!by_group) tab <- filter(tab, group == 'MT Pentateuch')   # one effect for all groups
  # Order of Tables 8.34-8.35, top to bottom
  order <- intersect(AFFIX_ORDER, tab$category)
  stopifnot(setequal(order, unique(tab$category)))
  tab <- tab |>
    mutate(category = factor(hebrew_category(category), levels = rev(hebrew_category(order))),
           variable = factor(if_else(variable == 'nme2', 'Nominal endings', 'Pronominal suffixes'),
                             levels = c('Nominal endings', 'Pronominal suffixes')),
           group = book_group_labels(factor(group, levels = GROUP_LEVELS[1:4])))
  # four narrow panels (waw): no label at 1/32, or it runs into 1/1,024
  p <- plot_or(tab, category, breaks = c(1/1024, 1/32, 1, 32),
               labels = c('1/1,024', if (by_group) '' else '1/32', '1', '32')) +
    markdown_y() +
    theme(strip.placement = 'outside', plot.caption.position = 'plot')
  if (by_group) {
    p + facet_grid(variable ~ group, scales = 'free_y', space = 'free_y', switch = 'y',
                   labeller = labeller(group = label_wrap_gen(12), variable = label_wrap_gen(12))) +
      theme(strip.text.y.left = element_text(angle = 90))
  } else {
    p + facet_grid(variable ~ ., scales = 'free_y', space = 'free_y', switch = 'y',
                   labeller = labeller(variable = label_wrap_gen(12))) +
      theme(strip.text.y.left = element_text(angle = 90))
  }
}
save_book_figure(affix_figure('waw', TRUE), 'fig_affix_waw_effects_book', width = 16, height = 14,
                 folder = out_folder('affix_types_mt'))
save_book_figure(affix_figure('yod', FALSE), 'fig_affix_yod_effects_book', width = 12, height = 10,
                 folder = out_folder('affix_types_mt'))

# Figure 8.36: prefix types, yod words. The yod model (A3) has no interactions,
# so the analysis figure repeats one estimate in four identical panels; one
# panel instead.
yod_prefix <- read_csv(file.path(ANALYSIS_DIR, 'affix_types_mt', 'figures', 'table_affix_yod_effects.csv'),
                       show_col_types = FALSE) |>
  filter(variable == 'prefix_type', group == 'MT Pentateuch') |>   # one effect for all groups
  mutate(category = factor(category, levels = rev(c('article', 'conjunction', 'preposition', 'other'))))
stopifnot(nrow(yod_prefix) == 4)
save_book_figure(plot_or(yod_prefix, category, breaks = c(1/4, 1/2, 1, 2, 4),
                         labels = c('1/4', '1/2', '1', '2', '4')) +
                   theme(plot.caption.position = 'plot'),
                 'fig_affix_yod_effects_prefix_type_book', width = 12, height = 6,
                 folder = out_folder('affix_types_mt'))

# ---- 5. Model summaries: intercept and SDs of the final models (medians) ----------

FINAL_MODELS <- c(final_w = 'na_finalw_M6.rds', final_y = 'na_finaly_nB.rds',
                  single_w = 'na_singlew_M6.rds', single_y = 'na_singley_M0.rds',
                  first_w = 'na_firstw_M6.rds', first_y = 'na_firsty_M0.rds')
PARAMETERS <- c(Intercept = 'b_Intercept', has_suffix = 'b_has_suffix1',
                sd_book = 'sd_scr_book2__Intercept', sd_lex_book = 'sd_scr_book2:lex__Intercept')
summaries <- imap_dfr(FINAL_MODELS, function(file, id) {
  m <- readRDS(file.path(MODEL_FOLDER, file))
  dr <- as_draws_df(m)
  out <- imap_dfr(PARAMETERS, function(col, name) {
    if (!col %in% names(dr)) return(NULL)
    v <- dr[[col]]
    tibble(dataset = id, parameter = name, median = median(v),
           lower95 = quantile(v, 0.025), upper95 = quantile(v, 0.975))
  })
  rm(m, dr); gc()
  out
})
print(summaries, n = Inf)
write_csv(summaries, file.path(out_folder('book'), 'table_ch8_model_summaries.csv'))
cat('done\n')
