################################################################################
# analysis/ch07_regression_illustrations/figures_ch07.R
#
# All figures of chapter 7 (hierarchical Bayesian regression) and of the
# Appendix (regression analysis), in the style of chapters 8-9 (theme_book(),
# save_book_figure(): 16 cm wide, 600 dpi PNG + PDF, Charis; book colours).
#
#   7.1  logit transformation (new)                 fig_ch07_logit
#   7.2  one-sided p-value                          fig_ch07_p_value
#   7.3  complete pooling                           fig_ch07_pooled
#   7.4  no pooling                                 fig_ch07_unpooled
#   7.5a partial pooling, with overall estimates    fig_ch07_partial_pooling
#   7.5b no pooling, with the same overall lines    fig_ch07_unpooled_lines
#   7.6  lexeme counts in MT Esther and Chronicles  fig_ch07_lexemes_est_chr
#   A.1-A.7 appendix (simulated heights/weights)    fig_appA_1 ... fig_appA_7
#
# Teaching example (§§7.5.3-7.6.1): qal active participles of MT Pentateuch and
# the MT core LBH books (Esther, Daniel, Ezra, Nehemiah, Chronicles), data
# v1.2.0, prepared as in ../ch09_verbs/ptca_qal/analysis.R
# (has_suffix = nominal ending or pronominal suffix). Three small brms models
# with the book's priors (normal(0, 2.5) for intercept and coefficients,
# exponential(1) for the SD), fitted once and stored in MODEL_FOLDER
# (author's approval, 2026-11-11). Summaries: posterior median with
# equal-tailed 66% and 95% intervals, as in the rest of the book. Figures 7.4
# and 7.5b come from the same fit. Values plotted: table_ch07_teaching_models.csv.
#
# Replaces bell_curve_p_value.R, linear_logistic_regression.R (appendix; same
# simulated data, seed 42) and section 6 of ptca_qal/analysis.R (old priors,
# mean and HDI, separate fits for Figs. 7.4 and 7.5b).
#
# CHANGES 2026-11-11 (new script).
################################################################################

# ==== 0. SETUP ====

library(tidyverse)
library(brms)
library(tidybayes)
library(binom)

source('analysis/paths.R')
source(file.path(SHARED_DIR, 'config.R'))
source(file.path(SHARED_DIR, 'functions.R'))
IMAGE_FOLDER <- file.path(CH07_DIR, 'figures')
dir.create(IMAGE_FOLDER, showWarnings = FALSE)

ALLOW_FIT <- TRUE   # three small teaching models (author, 2026-11-11)
options(analysis_verbs.allow_fit = ALLOW_FIT)
PRIOR_SD <- 2.5     # as in chapters 8-9

LBH_CORE <- c('Esther', 'Daniel', 'Ezra', 'Nehemiah', 'Chronicles')
BOOKS <- c('Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', LBH_CORE)
SUFFIX_LABELS <- c('0' = 'No suffix', '1' = 'Suffix')

# ==== 1. DATA (teaching example) ====

dat <- import_bib_data(DATA_FOLDER, 'ptca_qal.csv') |>
  remove_ketiv_qere() |>
  add_col_has_suffix() |>
  make_book2_column() |>
  make_factor_columns(factor_columns) |>
  filter(!lex %in% c('ML>[', 'JR>[', '>SP['), scroll == 'MT', book2 %in% BOOKS) |>
  mutate(scr_book2 = factor(book2, levels = BOOKS),
         has_suffix = factor(as.character(has_suffix), levels = c('0', '1'))) |>
  droplevels()

counts <- dat |>
  count(has_suffix, has_vowel_letter) |>
  pivot_wider(names_from = has_vowel_letter, values_from = n, names_prefix = 'vl_')
print(nrow(dat)); print(counts)
cat('lexemes:', n_distinct(dat$lex), '\n')

# ==== 2. TEACHING MODELS ====

FORMULAS <- list(
  pooled   = has_vowel_letter ~ has_suffix,
  unpooled = has_vowel_letter ~ has_suffix * scr_book2,
  partial  = has_vowel_letter ~ has_suffix + (1 | scr_book2)
)
models <- imap(FORMULAS, \(f, id)
  fit_model(paste0('ch07_teaching_', id, '.rds'), f, dat,
            book_priors(PRIOR_SD, has_fixed = TRUE) |>
              (\(p) if (id == 'partial') p else p[p$class != 'sd', ])(),
            warmup = 1000, iter = 3000))
walk(models, \(m) print(summary(m)))
walk(models, \(m) cat('max Rhat', max(brms::rhat(m), na.rm = TRUE), '\n'))

grid_books <- expand_grid(scr_book2 = factor(BOOKS, levels = BOOKS),
                          has_suffix = factor(c('0', '1'), levels = c('0', '1')))
grid_pop <- tibble(has_suffix = factor(c('0', '1'), levels = c('0', '1')))

summ <- function(draws, ...) {
  draws |>
    group_by(...) |>
    summarise(median = median(.epred),
              lower95 = quantile(.epred, 0.025), upper95 = quantile(.epred, 0.975),
              lower66 = quantile(.epred, 0.17),  upper66 = quantile(.epred, 0.83),
              .groups = 'drop')
}
pred <- bind_rows(
  grid_pop |> add_epred_draws(models$pooled) |> summ(has_suffix) |>
    mutate(model = 'pooled', scr_book2 = 'all'),
  grid_books |> add_epred_draws(models$unpooled) |> summ(scr_book2, has_suffix) |>
    mutate(model = 'unpooled'),
  grid_books |> add_epred_draws(models$partial) |> summ(scr_book2, has_suffix) |>
    mutate(model = 'partial'),
  grid_pop |> add_epred_draws(models$partial, re_formula = NA) |> summ(has_suffix) |>
    mutate(model = 'partial_overall', scr_book2 = 'all')
) |>
  mutate(scr_book2 = as.character(scr_book2), has_suffix = as.character(has_suffix)) |>
  relocate(model, scr_book2, has_suffix)
print(pred, n = Inf)
write_csv(pred, file.path(IMAGE_FOLDER, 'table_ch07_teaching_models.csv'))

# Raw shares per book and suffix (for the text)
raw <- dat |>
  group_by(scr_book2, has_suffix) |>
  summarise(full = sum(as.numeric(as.character(has_vowel_letter))), n = n(), .groups = 'drop')
write_csv(raw, file.path(IMAGE_FOLDER, 'table_ch07_teaching_raw.csv'))

# ==== 3. FIGURES 7.3-7.5 ====

plot_pred <- function(tab, overall = NULL, rows = 'scr_book2') {
  tab <- tab |>
    mutate(suffix = factor(SUFFIX_LABELS[has_suffix], levels = rev(SUFFIX_LABELS)),
           row = factor(.data[[rows]], levels = rev(unique(.data[[rows]]))))
  p <- ggplot(tab, aes(y = row, x = median, colour = suffix))
  if (!is.null(overall)) {
    overall <- overall |> mutate(suffix = factor(SUFFIX_LABELS[has_suffix], levels = rev(SUFFIX_LABELS)))
    p <- p + geom_vline(data = overall, aes(xintercept = median, colour = suffix),
                        linetype = 'dashed', linewidth = 0.5, show.legend = FALSE)
  }
  dodge <- position_dodge(width = 0.6)
  p +
    geom_linerange(aes(xmin = lower95, xmax = upper95), linewidth = 0.6, position = dodge) +
    geom_linerange(aes(xmin = lower66, xmax = upper66), linewidth = 1.6, position = dodge) +
    geom_point(size = 2.5, position = dodge) +
    scale_colour_manual(values = c('No suffix' = BOOK_BLUE, 'Suffix' = BOOK_ORANGE),
                        breaks = unname(SUFFIX_LABELS)) +
    scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25), labels = scales::percent) +
    labs(x = 'Predicted probability of full spelling', y = NULL) +
    theme_book()
}

p <- pred |> filter(model == 'pooled') |> mutate(scr_book2 = 'MT Pentateuch and core LBH') |>
  plot_pred() + labs(caption = OR_CAPTION)
save_book_figure(p, 'fig_ch07_pooled', height = 5)

p <- pred |> filter(model == 'unpooled') |> plot_pred() + labs(caption = OR_CAPTION)
save_book_figure(p, 'fig_ch07_unpooled', height = 14)

LINES_CAPTION <- paste0(OR_CAPTION, '\nDashed lines: overall estimate of the partial-pooling model ',
                        '(blue: no suffix; orange: suffix).')
overall <- pred |> filter(model == 'partial_overall')
p <- pred |> filter(model == 'partial') |> plot_pred(overall) + labs(caption = LINES_CAPTION)
save_book_figure(p, 'fig_ch07_partial_pooling', height = 14)
p <- pred |> filter(model == 'unpooled') |> plot_pred(overall) + labs(caption = LINES_CAPTION)
save_book_figure(p, 'fig_ch07_unpooled_lines', height = 14)

# ==== 4. FIGURE 7.6: LEXEMES IN MT ESTHER AND CHRONICLES ====

lex_counts <- dat |>
  filter(scr_book2 %in% c('Esther', 'Chronicles')) |>
  count(lex, scr_book2) |>
  complete(lex, scr_book2 = factor(c('Esther', 'Chronicles')), fill = list(n = 0)) |>
  filter(scr_book2 %in% c('Esther', 'Chronicles')) |>
  group_by(lex) |> mutate(total = sum(n)) |> ungroup() |>
  filter(total > 0) |>
  mutate(label = heb_md(etcbc_to_hebrew(lex)),
         label = fct_reorder(label, total),
         book = factor(as.character(scr_book2), levels = c('Esther', 'Chronicles')),
         value = if_else(book == 'Esther', -n, n))
cat('lexemes in Esther and Chronicles:', n_distinct(lex_counts$lex), '\n')
write_csv(lex_counts |> select(lex, book, n), file.path(IMAGE_FOLDER, 'table_ch07_lexemes_est_chr.csv'))
max_n <- max(lex_counts$n)
p <- lex_counts |>
  ggplot(aes(y = label, x = value, fill = book)) +
  geom_col(width = 0.75) +
  geom_vline(xintercept = 0, colour = BOOK_INK_2, linewidth = 0.3) +
  scale_x_continuous(breaks = seq(-50, 50, 5), labels = \(x) abs(x),
                     limits = c(-10, max_n + 1)) +
  scale_fill_manual(values = c(Esther = BOOK_ORANGE, Chronicles = BOOK_BLUE)) +
  labs(x = 'Number of qal active participles (Esther to the left, Chronicles to the right)', y = NULL) +
  theme_book(base_size = 9) +
  theme(panel.grid.major.y = element_blank()) +
  markdown_y()
save_book_figure(p, 'fig_ch07_lexemes_est_chr', height = 18)

# ==== 5. FIGURES 7.1 AND 7.2 ====

marks <- tibble(p = c(0.05, 0.25, 0.5, 0.75, 0.95)) |>
  mutate(logit = qlogis(p),
         label = sub('-', '−', sprintf('p = %.2f\nlogit = %.2f', p, logit)))
p <- tibble(logit = seq(-6, 6, 0.01)) |>
  mutate(p = plogis(logit)) |>
  ggplot(aes(x = logit, y = p)) +
  geom_hline(yintercept = 0.5, colour = BOOK_GRID) +
  geom_vline(xintercept = 0, colour = BOOK_GRID) +
  geom_line(colour = BOOK_BLUE, linewidth = 0.9) +
  geom_point(data = marks, colour = BOOK_ORANGE, size = 2.5) +
  geom_text(data = marks, aes(label = label), family = BOOK_FONT, size = 3, colour = BOOK_INK_2,
            hjust = -0.12, vjust = 1.1, lineheight = 0.9) +
  scale_x_continuous(breaks = -6:6, labels = scales::label_number(style_negative = 'minus')) +
  scale_y_continuous(breaks = seq(0, 1, 0.25)) +
  labs(x = 'Logit (log-odds)', y = 'Probability') +
  theme_book()
save_book_figure(p, 'fig_ch07_logit', height = 9)

OBS <- 2
curve_df <- tibble(x = seq(-4, 4, 0.01)) |> mutate(density = dnorm(x))
p <- ggplot(curve_df, aes(x, density)) +
  geom_area(data = filter(curve_df, x >= OBS), fill = BOOK_ORANGE, alpha = 0.35) +
  geom_line(colour = BOOK_INK_2, linewidth = 0.7) +
  geom_vline(xintercept = OBS, colour = BOOK_ORANGE, linewidth = 0.8) +
  annotate('text', x = OBS + 0.08, y = 0.30, label = 'Observed effect', hjust = 0,
           family = BOOK_FONT, size = 3.6, colour = BOOK_INK) +
  annotate('text', x = 2.75, y = 0.045, label = 'p-value', hjust = 0,
           family = BOOK_FONT, size = 3.6, colour = BOOK_INK) +
  annotate('segment', x = 2.72, xend = 2.35, y = 0.042, yend = 0.015, colour = BOOK_INK_2,
           linewidth = 0.3) +
  scale_x_continuous(labels = scales::label_number(style_negative = 'minus')) +
  labs(x = 'Test statistic under the null hypothesis', y = 'Density') +
  theme_book()
save_book_figure(p, 'fig_ch07_p_value', height = 8)

# ==== 6. APPENDIX FIGURES A.1-A.7 (same simulated data as before, seed 42) ====

set.seed(42)
height <- runif(n = 100, min = 140, max = 200)
weight <- height / (2 + rnorm(100) / 10)
sim <- tibble(height, weight) |>
  mutate(heavy = as.numeric(weight > 90),
         is_tall = factor(as.numeric(height > 180)))
lin <- lm(weight ~ height, data = sim)
print(coef(lin))
print(table(sim$is_tall, sim$heavy))
categ <- glm(heavy ~ is_tall, data = sim, family = binomial)
print(summary(categ)$coefficients)

# Points grey, fitted line blue (the Appendix text refers to 'the blue line' and 'the grey band')
pt <- list(geom_point(colour = BOOK_INK_2, size = 1.6, alpha = 0.7))
WCLASS <- 'Weight class (1 = heavyweight)'

p <- ggplot(sim, aes(height, weight)) + pt + labs(x = 'Height (cm)', y = 'Weight (kg)') + theme_book()
save_book_figure(p, 'fig_appA_1', height = 9)
p <- p + geom_smooth(method = 'lm', formula = y ~ x, colour = BOOK_BLUE, fill = BOOK_GREY)
save_book_figure(p, 'fig_appA_2', height = 9)

pb <- ggplot(sim, aes(height, heavy)) + pt +
  scale_y_continuous(breaks = c(0, 1)) +
  labs(x = 'Height (cm)', y = WCLASS) + theme_book()
save_book_figure(pb, 'fig_appA_3', height = 8)
save_book_figure(pb + geom_smooth(method = 'lm', formula = y ~ x, colour = BOOK_BLUE,
                                  fill = BOOK_GREY) +
                   scale_y_continuous(breaks = seq(-0.25, 1.25, 0.25)),
                 'fig_appA_4', height = 8)
save_book_figure(pb + geom_smooth(method = 'glm', method.args = list(family = 'binomial'),
                                  formula = y ~ x, colour = BOOK_BLUE, fill = BOOK_GREY),
                 'fig_appA_5', height = 8)

pr <- predict(categ, newdata = tibble(is_tall = factor(c('0', '1'))), se.fit = TRUE)
ci <- tibble(class = factor(c('Not tall', 'Tall'), levels = c('Not tall', 'Tall')),
             logit = pr$fit, lower = pr$fit - 1.96 * pr$se.fit, upper = pr$fit + 1.96 * pr$se.fit)
write_csv(ci, file.path(IMAGE_FOLDER, 'table_appA_categ_model.csv'))
p <- ci |> mutate(across(c(logit, lower, upper), plogis)) |>
  ggplot(aes(x = class, y = logit, ymin = lower, ymax = upper)) +
  geom_linerange(colour = BOOK_BLUE, linewidth = 0.8) +
  geom_point(colour = BOOK_BLUE, size = 3) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
  labs(x = NULL, y = 'Probability of the heavyweight class',
       caption = 'Point: estimate; line: 95% confidence interval.') +
  theme_book()
save_book_figure(p, 'fig_appA_6', width = 12, height = 8)
p <- ci |>
  ggplot(aes(x = class, y = logit, ymin = lower, ymax = upper)) +
  geom_hline(yintercept = 0, colour = BOOK_GREY, linewidth = 0.4) +
  geom_linerange(colour = BOOK_BLUE, linewidth = 0.8) +
  geom_point(colour = BOOK_BLUE, size = 3) +
  labs(x = NULL, y = 'Log odds of the heavyweight class',
       caption = 'Point: estimate; line: 95% confidence interval.') +
  theme_book()
save_book_figure(p, 'fig_appA_7', width = 12, height = 8)

sessionInfo()
