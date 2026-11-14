################################################################################
# Chapter 12: block spelling and rapid alternation (2026-11-03)
#
# Replaces the earlier notebook block_spelling_and_rapid_alternation.ipynb (removed)
# (hebrew_spelling_variation). Decisions: Claude doc "Chapter 12 revision: block
# spelling and rapid alternation" (author, 2026-11-03):
#   1. Main null model: the spellings are shuffled within each lexeme x suffix
#      status in a book (stratified permutation). Free shuffling is reported as
#      the descriptive baseline.
#   2. Statistic: the number of changes between defective and full. Free
#      shuffling: exact runs test (Wald and Wolfowitz 1940). Stratified: B
#      permutations; p = share of permutations as extreme or more extreme
#      (ties on the null side), (k + 1) / (B + 1).
#   3. Main question: all books together (total number of changes against its
#      null distribution, from the same permutations). Single books: two-sided
#      p, Benjamini-Hochberg across the books of a feature.
#   4. Rapid alternation: number of overlapping D F D F / F D F D, same tests.
#   5. Features: qal active participle and qal infinitive construct
#      (triliteral). Final-syllable waw in nouns and adjectives was dropped
#      (author, 2026-11-13: too vague a feature).
#   6. Corpora: MT books; 1QIsaa (two halves) as a check.
#   7. Fullness: linear regression of the stratified z on the share of full
#      forms.
# Revision 2026-11-13:
#   - A book is informative for the stratified test only if the order can vary
#     within lexeme x suffix (sd of the permuted changes > 0). Only informative
#     books enter the stratified Benjamini-Hochberg correction, the fullness
#     regression and the stratified points of the figures; the free test and
#     the totals keep all books.
#   - Four-form alternations: BH on the two-sided p (2 x one-sided), as for the
#     changes, so that every corrected p is compared with 0.05.
#   - Extra checks of the totals: within chapter x lexeme x suffix (is the
#     remaining block spelling local?), within lexeme x suffix x prefix, without
#     Chronicles and Ezekiel, and a sign count of the informative books.
#   - Figures without the z bands; orange = significant after correction.
# Review of 2026-11-13 (afternoon):
#   - Model-based null: within each book, the observed number of full forms is
#     distributed over the forms with probabilities proportional to the odds
#     of the chapter 9 final model (conditional Bernoulli, exact sampling;
#     weights from model_weights.R). Book-level terms cancel; the book x lexeme
#     effects are shrunk, so this null lies between free shuffling and
#     shuffling within lexeme x suffix. MT books only.
#   - Per book: exchangeable forms (forms in a lexeme x suffix group that has
#     both spellings; only these can move in the stratified null) and isolated
#     full forms (a full form whose neighbours are defective).
#   - Robustness checks with the same number of permutations as the main
#     analysis (before: B / 5 = 2,000).
# Data: the cleaned chapter 8-9 datasets (../clustering/data, from
# ../clustering/export_cleaned_data.R). Forms in textual order (tf_id).
#
# Run:  Rscript sequence_analysis.R        (B from CH12_B, default 10000)
################################################################################

suppressMessages({
  library(tidyverse)
})
source('analysis/paths.R')
source(file.path(SHARED_DIR, 'functions.R'))  # theme_book, heb_md

HERE <- CH12_DIR
DATA <- CLEANED_DATA_DIR
RES <- file.path(HERE, 'results'); FIG <- file.path(HERE, 'figures')
dir.create(RES, showWarnings = FALSE); dir.create(FIG, showWarnings = FALSE)

B <- as.integer(Sys.getenv('CH12_B', '10000'))
SEED <- 20261103
MIN_ORDERINGS <- 100     # inclusion: at least 100 distinct orderings ...
MIN_EACH <- 2            # ... and at least two defective and two full forms
FEATURES <- c(ptca_qal = 'Qal active participle', infc_qal_triliteral = 'Qal infinitive construct')
TOP_LEXEME <- c(ptca_qal = 'JCB[', infc_qal_triliteral = '>MR[')

# ---- Data ------------------------------------------------------------------------

unit_label <- function(scroll, book2) {
  book <- recode(str_replace_all(book2, '_', ' '), 'Ecclesiastes' = 'Qoheleth', 'Song of songs' = 'Song of Songs')
  case_when(scroll == 'MT' ~ book,
            scroll == '1QisaaI' ~ '1QIsa\u1d43 I',
            scroll == '1QisaaII' ~ '1QIsa\u1d43 II')
}

read_sequences <- function(feature) {
  read_tsv(file.path(DATA, paste0('cleaned_', feature, '.tsv')), col_types = cols(.default = 'c')) |>
    filter(scroll %in% c('MT', '1QisaaI', '1QisaaII')) |>
    mutate(tf_id = as.integer(tf_id), full = as.integer(has_vowel_letter),
           corpus = if_else(scroll == 'MT', 'MT', '1QIsaa'),
           unit = unit_label(scroll, book2), stratum = paste(lex, has_suffix, sep = '_'),
           # book, not book2: 1 and 2 Samuel, Kings, Chronicles have their own chapter numbers
           chapter_stratum = paste(book, chapter, lex, has_suffix, sep = '_'),
           prefix_stratum = paste(lex, has_suffix, has_prefix, sep = '_')) |>
    left_join(read_weights(feature), by = c('tf_id', 'scroll')) |>
    arrange(tf_id)
}

# linear predictors of the chapter 9 final models (model_weights.R); MT only
read_weights <- function(feature) {
  f <- file.path(RES, 'model_weights.tsv')
  if (!file.exists(f)) return(tibble(tf_id = integer(), scroll = character(), eta = numeric()))
  read_tsv(f, col_types = cols(tf_id = 'i', eta = 'd', .default = 'c')) |>
    filter(.data$feature == !!feature) |> select(tf_id, scroll, eta)
}

# ---- Statistics -------------------------------------------------------------------

n_changes <- function(x) sum(x[-1] != x[-length(x)])
n_alt4 <- function(x) {          # overlapping D F D F and F D F D = three changes in a row
  d <- x[-1] != x[-length(x)]; n <- length(d)
  if (n < 3) return(0L)
  sum(d[1:(n - 2)] & d[2:(n - 1)] & d[3:n])
}

included <- function(x) {
  n1 <- sum(x); n0 <- length(x) - n1
  n1 >= MIN_EACH && n0 >= MIN_EACH && lchoose(n0 + n1, n1) >= log(MIN_ORDERINGS)
}

# Exact distribution of the number of changes for n0 zeros and n1 ones under
# random ordering (runs test); returns P(changes = 0, ..., n - 1).
runs_pmf <- function(n0, n1) {
  n <- n0 + n1; lt <- lchoose(n, n1)
  r <- 2:n; k <- r %/% 2
  lc <- function(a, b) ifelse(b < 0 | b > a, -Inf, lchoose(a, b))
  even <- log(2) + lc(n1 - 1, k - 1) + lc(n0 - 1, k - 1)
  odd <- log(exp(lc(n1 - 1, k - 1) + lc(n0 - 1, k) - lt) + exp(lc(n1 - 1, k) + lc(n0 - 1, k - 1) - lt)) + lt
  lp <- ifelse(r %% 2 == 0, even, odd) - lt
  c(0, exp(lp))[seq_len(n)]       # index c + 1 = changes c (0 changes impossible when n0, n1 > 0)
}

exact_test <- function(x) {
  n1 <- sum(x); n0 <- length(x) - n1
  pmf <- runs_pmf(n0, n1); obs <- n_changes(x); cc <- seq_along(pmf) - 1
  m <- sum(cc * pmf); s <- sqrt(sum((cc - m)^2 * pmf))
  tibble(free_mean = m, free_sd = s, free_z = (obs - m) / s,
         free_p_block = sum(pmf[cc <= obs]), free_p_alt = sum(pmf[cc >= obs]))
}

# B permutations of one sequence; strata = NULL means free shuffling.
permute <- function(x, strata, B) {
  idx <- if (is.null(strata)) list(seq_along(x)) else split(seq_along(x), strata)
  idx <- idx[lengths(idx) > 1]
  from <- unlist(idx, use.names = FALSE)
  ch <- integer(B); al <- integer(B)
  for (b in seq_len(B)) {
    y <- x
    if (length(from)) y[from] <- x[unlist(lapply(idx, function(g) g[sample.int(length(g))]), use.names = FALSE)]
    ch[b] <- n_changes(y); al[b] <- n_alt4(y)
  }
  list(changes = ch, alt4 = al)
}

logsumexp2 <- function(a, b) {
  m <- pmax(a, b)
  ifelse(is.infinite(m) & m < 0, -Inf, m + log1p(exp(-abs(a - b))))
}

# Model-based null: B sequences in which the observed number of full forms k is
# placed with P(x) proportional to prod(w_i^x_i), w_i = exp(eta_i) (conditional
# Bernoulli). Exact sequential sampling: P(x_i = 1 | r full left) =
# w_i e_{r-1}(w_{i+1..n}) / e_r(w_{i..n}), with e_j the elementary symmetric
# polynomials (log scale). Equal weights give free shuffling.
cb_sim <- function(x, eta, B) {
  n <- length(x); k <- sum(x); eta <- eta - mean(eta)
  logR <- matrix(-Inf, n + 1, k + 1)        # logR[i, j + 1] = log e_j(w_i, ..., w_n)
  logR[, 1] <- 0
  if (k >= 1) for (i in n:1) {
    j <- 1:k
    logR[i, j + 1] <- logsumexp2(logR[i + 1, j + 1], eta[i] + logR[i + 1, j])
  }
  r <- rep(k, B); prev <- integer(B); ch <- integer(B); al <- integer(B)
  d1 <- d2 <- logical(B)
  for (i in seq_len(n)) {
    p <- numeric(B); pos <- r > 0
    if (any(pos)) p[pos] <- exp(eta[i] + logR[i + 1, r[pos]] - logR[i, r[pos] + 1])
    xi <- as.integer(runif(B) < p)
    r <- r - xi
    if (i > 1) {
      d <- xi != prev
      ch <- ch + d; al <- al + (d & d1 & d2)
      d2 <- d1; d1 <- d
    }
    prev <- xi
  }
  stopifnot(all(r == 0))
  list(changes = ch, alt4 = al)
}

# forms that can move under shuffling within the strata: groups with both spellings
n_exchangeable <- function(x, strata) {
  g <- split(x, strata)
  sum(lengths(g)[vapply(g, function(v) any(v == 0) && any(v == 1), logical(1))])
}

# full forms whose neighbours (one at the ends) are defective
n_isolated_full <- function(x) {
  n <- length(x)
  left <- c(TRUE, x[-n] == 0); right <- c(x[-1] == 0, TRUE)
  sum(x == 1 & left & right)
}

p_low <- function(sim, obs) (sum(sim <= obs) + 1) / (length(sim) + 1)
p_high <- function(sim, obs) (sum(sim >= obs) + 1) / (length(sim) + 1)

# ---- One feature -----------------------------------------------------------------------

analyse_feature <- function(feature, strata_col = 'stratum', drop_lexeme = NULL, min_orderings = MIN_ORDERINGS,
                            min_each = MIN_EACH, nperm = B, seed = SEED, drop_units = NULL, model = FALSE) {
  set.seed(seed)
  d <- read_sequences(feature)
  if (!is.null(drop_lexeme)) d <- filter(d, lex != drop_lexeme)
  if (!is.null(drop_units)) d <- filter(d, !unit %in% drop_units)
  units <- split(d, d$unit)
  rows <- list(); sims <- list()
  for (u in names(units)) {
    du <- units[[u]]; x <- du$full
    n1 <- sum(x); n0 <- length(x) - n1
    if (!(n1 >= min_each && n0 >= min_each && lchoose(n0 + n1, n1) >= log(min_orderings))) next
    obs <- n_changes(x); obs4 <- n_alt4(x)
    st <- permute(x, du[[strata_col]], nperm)
    fr <- permute(x, NULL, nperm)
    sims[[u]] <- list(strat = st$changes, free = fr$changes, strat4 = st$alt4, free4 = fr$alt4)
    use_model <- model && du$corpus[1] == 'MT' && !anyNA(du$eta)
    mo <- NULL
    if (use_model) {     # own random stream, so that the permutation results stay as before
      old_seed <- .Random.seed
      set.seed(seed + match(u, names(units)))
      mo <- cb_sim(x, du$eta, nperm)
      assign('.Random.seed', old_seed, envir = globalenv())
    }
    if (use_model) sims[[u]]$model <- mo$changes
    rows[[u]] <- bind_cols(
      tibble(feature = feature, unit = u, corpus = du$corpus[1], n = length(x), full = n1, fullness = n1 / length(x),
             lexemes = n_distinct(du$lex), changes = obs, alt4 = obs4,
             exchangeable = n_exchangeable(x, du[[strata_col]]), isolated_full = n_isolated_full(x)),
      if (use_model) tibble(model_mean = mean(mo$changes), model_sd = sd(mo$changes),
                            model_z = (obs - mean(mo$changes)) / sd(mo$changes),
                            model_p_block = p_low(mo$changes, obs), model_p_alt = p_high(mo$changes, obs),
                            alt4_model_p = p_high(mo$alt4, obs4))
      else tibble(model_mean = NA_real_, model_sd = NA_real_, model_z = NA_real_, model_p_block = NA_real_,
                  model_p_alt = NA_real_, alt4_model_p = NA_real_),
      exact_test(x),
      tibble(strat_mean = mean(st$changes), strat_sd = sd(st$changes), strat_informative = sd(st$changes) > 0,
             # no stratum with both spellings: the order cannot vary, z = 0
             strat_z = if (sd(st$changes) > 0) (obs - mean(st$changes)) / sd(st$changes) else 0,
             strat_p_block = p_low(st$changes, obs), strat_p_alt = p_high(st$changes, obs),
             alt4_free_p = p_high(fr$alt4, obs4), alt4_strat_p = p_high(st$alt4, obs4),
             alt4_strat_z = if (sd(st$alt4) > 0) (obs4 - mean(st$alt4)) / sd(st$alt4) else 0))
  }
  res <- bind_rows(rows) |>
    mutate(free_p2 = pmin(1, 2 * pmin(free_p_block, free_p_alt)),
           strat_p2 = pmin(1, 2 * pmin(strat_p_block, strat_p_alt)),
           alt4_strat_p2 = pmin(1, 2 * alt4_strat_p),
           model_p2 = pmin(1, 2 * pmin(model_p_block, model_p_alt)))
  mt <- res$corpus == 'MT'
  mi <- mt & res$strat_informative
  mm <- mt & !is.na(res$model_p2)
  res$free_q <- NA_real_; res$strat_q <- NA_real_; res$alt4_q <- NA_real_; res$model_q <- NA_real_
  res$free_q[mt] <- p.adjust(res$free_p2[mt], 'BH')
  res$strat_q[mi] <- p.adjust(res$strat_p2[mi], 'BH')
  res$alt4_q[mi] <- p.adjust(res$alt4_strat_p2[mi], 'BH')
  if (any(mm)) res$model_q[mm] <- p.adjust(res$model_p2[mm], 'BH')
  # all MT books together: totals per permutation (the same permutation index in every book)
  mt_units <- res$unit[mt]
  total <- function(key) Reduce(`+`, lapply(sims[mt_units], `[[`, key))
  obs_tot <- sum(res$changes[mt]); obs4_tot <- sum(res$alt4[mt])
  overall <- tibble(feature = feature, strata = strata_col, drop_lexeme = drop_lexeme %||% '', books = sum(mt),
                    min_orderings = min_orderings, min_each = min_each,
                    changes = obs_tot,
                    free_expected = mean(total('free')), free_z = (obs_tot - mean(total('free'))) / sd(total('free')),
                    free_p_block = p_low(total('free'), obs_tot),
                    strat_expected = mean(total('strat')), strat_z = (obs_tot - mean(total('strat'))) / sd(total('strat')),
                    strat_p_block = p_low(total('strat'), obs_tot), strat_p_alt = p_high(total('strat'), obs_tot),
                    alt4 = obs4_tot, alt4_strat_expected = mean(total('strat4')),
                    alt4_strat_p = p_high(total('strat4'), obs4_tot),
                    books_q05_strat = sum(res$strat_q < 0.05, na.rm = TRUE),
                    books_q05_free = sum(res$free_q < 0.05, na.rm = TRUE),
                    books_informative = sum(mi),
                    books_z_neg = sum(res$strat_z[mi] < 0), books_z_pos = sum(res$strat_z[mi] > 0),
                    sign_p = if (sum(mi)) pbinom(sum(res$strat_z[mi] > 0), sum(res$strat_z[mi] != 0), 0.5) else NA_real_)
  model_units <- res$unit[mm]
  if (length(model_units) && length(model_units) == sum(mt)) {
    tm <- Reduce(`+`, lapply(sims[model_units], `[[`, 'model'))
    overall <- mutate(overall, model_expected = mean(tm), model_z = (obs_tot - mean(tm)) / sd(tm),
                      model_p_block = p_low(tm, obs_tot), model_p_alt = p_high(tm, obs_tot),
                      books_q05_model = sum(res$model_q < 0.05, na.rm = TRUE),
                      books_p025_model = sum(res$model_p_block[mm] < 0.025))
  }
  list(units = res, overall = overall)
}

# ---- Figures ----------------------------------------------------------------------------

save_fig <- function(p, name, width, height) {
  ggsave(file.path(FIG, paste0(name, '.png')), p, width = width, height = height, units = 'cm', dpi = 600,
         device = ragg::agg_png, bg = 'white')
  ggsave(file.path(FIG, paste0(name, '.pdf')), p, width = width, height = height, units = 'cm', device = cairo_pdf)
}

# Books: z of the number of changes under free shuffling (open) and within
# lexeme x suffix (filled, informative books only); orange = significant after
# Benjamini-Hochberg (corrected two-sided p < 0.05).
books_plot <- function(res) {
  d <- res |> filter(corpus == 'MT') |>
    mutate(sig_free = !is.na(free_q) & free_q < 0.05, sig_strat = !is.na(strat_q) & strat_q < 0.05)
  # top to bottom: informative books by stratified z, then the others by free z
  lev <- c(with(filter(d, !strat_informative), unit[order(-free_z)]),
           with(filter(d, strat_informative), unit[order(-strat_z)]))
  d <- mutate(d, unit = factor(unit, levels = lev))
  di <- filter(d, strat_informative)
  n_un <- sum(!d$strat_informative)
  cap <- paste0('Open: free shuffling. Filled: shuffling within lexeme and suffix status',
                if (n_un) ' (no filled circle: no lexeme has both spellings with the same suffix status)' else '',
                '. Orange: significant after correction for the number of books.')
  ggplot(d, aes(y = unit)) +
    geom_vline(xintercept = 0, colour = BOOK_GREY, linewidth = 0.4) +
    geom_segment(data = di, aes(x = free_z, xend = strat_z, yend = unit), colour = BOOK_GREY, linewidth = 0.3) +
    geom_point(aes(x = free_z, colour = sig_free), shape = 21, fill = 'white', size = 1.8, stroke = 0.6) +
    geom_point(data = di, aes(x = strat_z, colour = sig_strat), size = 2) +
    scale_y_discrete(limits = lev) +    # keep this order (the first layer only has the informative books)
    scale_colour_manual(values = c(`FALSE` = BOOK_BLUE, `TRUE` = BOOK_ORANGE), guide = 'none') +
    labs(x = 'Fewer changes (block spelling)  \u2190  z  \u2192  more changes (alternation)', y = NULL,
         caption = str_wrap(cap, 120)) +
    theme_book() +
    theme(panel.grid.major.y = element_blank(), plot.caption.position = 'plot',
          plot.caption = element_text(size = 7.5, colour = BOOK_INK_2, hjust = 0), axis.text.y = element_text(size = 8))
}

alt_plot <- function(res) {
  d <- res |> filter(corpus == 'MT', strat_informative) |>
    mutate(unit = fct_reorder(unit, alt4_strat_z), sig = !is.na(alt4_q) & alt4_q < 0.05)
  ggplot(d, aes(x = alt4_strat_z, y = unit, colour = sig)) +
    geom_vline(xintercept = 0, colour = BOOK_GREY, linewidth = 0.4) +
    geom_point(size = 2) +
    geom_text(aes(label = alt4), hjust = -0.8, size = 2.4, colour = BOOK_INK_2, family = BOOK_FONT) +
    scale_colour_manual(values = c(`FALSE` = BOOK_BLUE, `TRUE` = BOOK_ORANGE), guide = 'none') +
    scale_x_continuous(expand = expansion(mult = c(0.05, 0.12))) +
    labs(x = 'z of the number of four-form alternations (D F D F, F D F D)', y = NULL,
         caption = str_wrap(paste('Numbers: observed four-form alternations. Shuffling within lexeme and suffix status.',
                                  'Orange: significant after correction for the number of books (permutation p).'), 120)) +
    theme_book() +
    theme(panel.grid.major.y = element_blank(), plot.caption.position = 'plot',
          plot.caption = element_text(size = 7.5, colour = BOOK_INK_2, hjust = 0), axis.text.y = element_text(size = 8))
}

fullness_plot <- function(res, fit) {
  d <- filter(res, corpus == 'MT', strat_informative)
  ggplot(d, aes(x = 100 * fullness, y = strat_z)) +
    geom_hline(yintercept = 0, colour = BOOK_GREY, linewidth = 0.4) +
    geom_smooth(method = 'lm', formula = y ~ x, colour = BOOK_BLUE, fill = BOOK_GRID, linewidth = 0.6) +
    geom_point(colour = BOOK_BLUE, size = 1.6) +
    geom_text(aes(label = unit), size = 2.2, vjust = -0.7, colour = BOOK_INK_2, family = BOOK_FONT, check_overlap = TRUE) +
    labs(x = 'Full forms (percent)', y = 'z of the number of changes',
         caption = sprintf('Shuffling within lexeme and suffix status. Linear regression: slope %.3f per percent, p = %.2f.',
                           coef(fit)[2] / 100, summary(fit)$coefficients[2, 4])) +
    theme_book() +
    theme(plot.caption.position = 'plot', plot.caption = element_text(size = 7.5, colour = BOOK_INK_2, hjust = 0))
}

# Figure 12.1: exact distribution of the number of changes, five D and five F.
example_plot <- function() {
  pmf <- runs_pmf(5, 5)
  d <- tibble(changes = seq_along(pmf) - 1, p = pmf) |> filter(changes >= 1)
  ggplot(d, aes(x = factor(changes), y = 100 * p)) +
    geom_col(fill = BOOK_BLUE, width = 0.7) +
    geom_text(aes(label = sprintf('%.1f', 100 * p)), vjust = -0.4, size = 2.6, colour = BOOK_INK_2, family = BOOK_FONT) +
    labs(x = 'Number of spelling changes', y = 'Probability (percent)') +
    theme_book() + theme(panel.grid.major.x = element_blank())
}

# Figure 12.2: the four hypothetical sequences of §12.3.3.
HYPOTHETICAL <- list(a = c(0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1), b = c(0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1),
                     c = c(1,1,1,1,0,1,0,1,0,0,1,1,0,0,0,0), d = c(0,1,0,1,0,1,0,1,0,1,0,0,0,1,1,1))
hypothetical_table <- function() {
  imap_dfr(HYPOTHETICAL, function(x, nm) bind_cols(tibble(sequence = nm, changes = n_changes(x)), exact_test(x)))
}
hypothetical_plot <- function(h) {
  ggplot(h, aes(x = free_z, y = fct_rev(sequence))) +
    geom_vline(xintercept = 0, colour = BOOK_GREY, linewidth = 0.4) +
    geom_point(colour = BOOK_BLUE, size = 2.4) +
    geom_text(aes(label = paste(changes, if_else(changes == 1, 'change', 'changes'))), vjust = -1.1, size = 2.5,
              colour = BOOK_INK_2, family = BOOK_FONT) +
    scale_y_discrete(expand = expansion(add = c(0.6, 0.9))) +
    labs(x = 'Fewer changes (block spelling)  \u2190  z  \u2192  more changes (alternation)', y = 'Sequence',
         caption = 'Eight defective and eight full forms; z from the exact distribution of the number of changes (expected: 8).') +
    theme_book() +
    theme(panel.grid.major.y = element_blank(), plot.caption.position = 'plot',
          plot.caption = element_text(size = 7.5, colour = BOOK_INK_2, hjust = 0))
}

# ---- Self-tests --------------------------------------------------------------------------

self_tests <- function() {
  stopifnot(n_changes(c(0, 0, 1, 1, 0)) == 2, n_alt4(c(0, 1, 0, 1, 0, 1)) == 3, n_alt4(c(0, 0, 1, 1)) == 0)
  p <- runs_pmf(5, 5)
  stopifnot(abs(sum(p) - 1) < 1e-12, abs(p[2] - 2 / choose(10, 5)) < 1e-12, abs(p[10] - 2 / choose(10, 5)) < 1e-12)
  # exact distribution agrees with brute force for 4 zeros and 3 ones
  perms <- combn(7, 3, function(i) { x <- rep(0, 7); x[i] <- 1; n_changes(x) })
  bf <- as.numeric(table(factor(perms, levels = 0:6))) / length(perms)
  stopifnot(max(abs(bf - runs_pmf(4, 3))) < 1e-12)
  # stratified shuffling keeps each stratum's spellings
  set.seed(1); x <- c(1, 1, 0, 0, 1, 0); s <- c('a', 'a', 'a', 'b', 'b', 'c')
  y <- permute(x, s, 50)
  stopifnot(length(y$changes) == 50)
  # conditional Bernoulli: equal weights reproduce the exact runs distribution;
  # extreme weights force the full forms onto the heavy positions
  set.seed(2); x <- c(rep(0, 6), rep(1, 4))
  sim <- cb_sim(x, rep(0, 10), 40000)$changes
  pmf <- runs_pmf(6, 4); stopifnot(abs(mean(sim) - sum((seq_along(pmf) - 1) * pmf)) < 0.03)
  stopifnot(all(cb_sim(x, c(rep(-30, 6), rep(30, 4)), 100)$changes == 1))
  stopifnot(n_exchangeable(c(1, 0, 1, 1), c('a', 'a', 'b', 'b')) == 2, n_isolated_full(c(1, 0, 1, 1, 0, 1)) == 2)
  invisible(TRUE)
}
self_tests()

# ---- Main ---------------------------------------------------------------------------------

if (sys.nframe() == 0) {
  t0 <- Sys.time()
  all_units <- list(); all_overall <- list(); robust <- list(); fits <- list()
  for (f in names(FEATURES)) {
    r <- analyse_feature(f, model = TRUE)
    all_units[[f]] <- r$units; all_overall[[f]] <- r$overall
    mt_units <- filter(r$units, corpus == 'MT', strat_informative)
    fit <- lm(strat_z ~ fullness, data = mt_units)
    fits[[f]] <- tibble(feature = f, slope_per_percent = unname(coef(fit)[2]) / 100,
                        p = summary(fit)$coefficients[2, 4], correlation = cor(mt_units$fullness, mt_units$strat_z),
                        books = nrow(mt_units))
    h <- max(8, 0.42 * sum(r$units$corpus == 'MT') + 3)
    hi <- max(6, 0.42 * nrow(mt_units) + 3)
    save_fig(books_plot(r$units), paste0('fig_ch12_', f, '_books'), 15.8, h)
    save_fig(alt_plot(r$units), paste0('fig_ch12_', f, '_alternation'), 15.8, hi)
    save_fig(fullness_plot(r$units, fit), paste0('fig_ch12_', f, '_fullness'), 15.8, 10)
    # robustness (phase 3): lexeme only; without the most frequent lexeme; stricter inclusion
    Br <- B    # review 2026-11-13: as many permutations as the main analysis (before B / 5)
    robust[[f]] <- bind_rows(
      r$overall |> mutate(check = 'main'),
      analyse_feature(f, strata_col = 'lex', nperm = Br)$overall |> mutate(check = 'within lexeme only'),
      analyse_feature(f, drop_lexeme = TOP_LEXEME[[f]], nperm = Br)$overall |> mutate(check = paste('without', TOP_LEXEME[[f]])),
      analyse_feature(f, min_orderings = 1000, min_each = 3, nperm = Br)$overall |> mutate(check = 'at least 1,000 orderings, 3 of each'),
      # revision 2026-11-13
      analyse_feature(f, strata_col = 'prefix_stratum', nperm = Br)$overall |> mutate(check = 'within lexeme, suffix and prefix'),
      analyse_feature(f, drop_units = c('Chronicles', 'Ezekiel'), nperm = Br)$overall |> mutate(check = 'without Chronicles and Ezekiel'),
      analyse_feature(f, strata_col = 'chapter_stratum', nperm = Br)$overall |> mutate(check = 'within chapter, lexeme and suffix'))
    message(f, ': ', sum(r$units$corpus == 'MT'), ' MT books; ', round(difftime(Sys.time(), t0, units = 'mins'), 1), ' min')
  }
  h <- hypothetical_table()
  save_fig(example_plot(), 'fig_ch12_runs_example', 15.8, 7)
  save_fig(hypothetical_plot(h), 'fig_ch12_hypothetical', 15.8, 6)
  write_tsv(bind_rows(all_units), file.path(RES, 'units.tsv'))
  write_tsv(bind_rows(all_overall), file.path(RES, 'overall.tsv'))
  write_tsv(bind_rows(robust), file.path(RES, 'robustness.tsv'))
  write_tsv(bind_rows(fits), file.path(RES, 'fullness_regression.tsv'))
  write_tsv(h, file.path(RES, 'hypothetical.tsv'))
  writeLines(c(paste('run', format(Sys.time())), paste('B =', B), paste('SEED =', SEED),
               paste('MIN_ORDERINGS =', MIN_ORDERINGS), paste('MIN_EACH =', MIN_EACH)), file.path(RES, 'settings.txt'))
}
