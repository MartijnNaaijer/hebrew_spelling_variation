################################################################################
# Chapter 10: documents by vowel-letter profile (revision of 2026-11-13)
#
# Replaces the Python notebooks notebooks/clustering_spelling*.ipynb (removed;
# in the repository history up to v1.2.0). The version of 2026-11-03/04 (counts
# profile as main analysis, bootstrap of forms) is in the repository history. Methodological revision agreed with the author on
# 2026-11-13:
#   1. Main profile: spelling rates = share of full spelling per feature
#      (dataset x suffix status), shrunk toward the corpus share with PSEUDO
#      forms; squared differences weighted by the feature's share of all forms
#      (columns x sqrt(weight)), the same weights for every document. Checks:
#      the counts profile of the earlier version (content and spelling) and a
#      lexeme-adjusted profile (each form compared with the spelling of its
#      lexeme in the other documents; differences in vocabulary removed).
#   2. A priori groups tested directly: is a group of documents closer together
#      than random sets of the same size from a reference pool (mean pairwise
#      distance, permutations)? Two-group contrasts (Trebolle's two series; SP
#      against MT Pentateuch) with a permutation F test (PERMANOVA).
#   3. Map: principal components of the main profile (PC1-PC2), next to the
#      dendrograms.
#   4. Bootstrap: lexemes (all forms of a lexeme in a document and dataset)
#      resampled within each document, not single forms.
#   5. Rule fixed in advance: a cluster counts as an orthographic affinity only
#      if its bootstrap support in the main profile is at least 70 percent AND
#      it recurs in at least two-thirds of the settings (24 of 36: lexeme cut-off
#      2, 4, 10, none x inclusion 50, 80, 120 forms x the three profiles); a
#      cluster of more than half the documents (the rest of a split) does not count.
# Unchanged: data (cleaned chapter 8-9 datasets, export_cleaned_data.R); lexeme
# cap (within document and dataset, share of full spelling kept; main 4);
# documents with at least MIN_FORMS forms before capping; units as in the
# models (scr_book2; 1QIsaa in two halves); Ward linkage on Euclidean
# distances; three analyses (nouns and adjectives with SP, verbs, combined).
#
# Run:  Rscript cluster_analysis.R      (CH10_B bootstrap replicates, default 1000;
#                                       CH10_BT permutations for the tests, default 10000)
# Output: results/*.tsv, figures/*.png|pdf
################################################################################

suppressMessages({
  library(tidyverse)
  library(ggrepel)
})
source('analysis/paths.R')
source(file.path(SHARED_DIR, 'functions.R'))  # theme_book, BOOK_*, heb_md

HERE <- CH10_DIR
DATA <- CLEANED_DATA_DIR; RES <- file.path(HERE, 'results'); FIG <- file.path(HERE, 'figures')
dir.create(RES, showWarnings = FALSE); dir.create(FIG, showWarnings = FALSE)

CUT_MAIN <- 4          # lexeme cap
MIN_FORMS <- 80        # documents: at least this many forms (before capping)
FEATURE_MIN <- 10      # features: total (capped) count over the documents > FEATURE_MIN
PSEUDO <- 2            # rates: pseudo-forms toward the corpus share
LEX_PSEUDO <- 2        # lexeme-adjusted: pseudo-forms toward the corpus share for a lexeme's expectation
SUPPORT_MIN <- 0.70    # rule: bootstrap support ...
RECUR_MIN <- 24        # ... and recurrence in at least 24 of the 36 settings
PROFILES <- c('rates', 'counts', 'lexadj')
MAIN <- 'rates'
B <- as.integer(Sys.getenv('CH10_B', '1000'))
BT <- as.integer(Sys.getenv('CH10_BT', '10000'))
SEED <- 20261113

NOUNS <- c('final_w', 'final_y', 'single_w', 'single_y', 'first_w', 'first_y')
VERBS <- c('ptca_qal', 'ptcp_qal', 'infc_qal_triliteral', 'infc_qal_lamed_he', 'infa_qal',
           'hiphil_triliteral', 'niph_hiph_pe_yod')
ANALYSES <- list(nouns = list(sets = NOUNS, sp = TRUE),
                 verbs = list(sets = VERBS, sp = FALSE),
                 combined = list(sets = c(NOUNS, VERBS), sp = FALSE))
SUFFIX_COL <- c(infc_qal_lamed_he = 'has_prs', infa_qal = NA, infc_qal_triliteral = NA)  # others: has_suffix

# ---- Data ---------------------------------------------------------------------

read_forms <- function(sets, sp) {
  map_dfr(sets, function(id) {
    d <- read_tsv(file.path(DATA, paste0('cleaned_', id, '.tsv')), col_types = cols(.default = 'c'))
    scol <- if (id %in% names(SUFFIX_COL)) SUFFIX_COL[[id]] else 'has_suffix'
    tibble(doc = d$scr_book2, scroll = d$scroll, group = d$corpus_group, dataset = id, lex = d$lex,
           full = as.integer(d$has_vowel_letter),
           suffix = if (is.na(scol)) NA_integer_ else as.integer(d[[scol]]))
  }) |>
    filter(sp | scroll != 'SP') |>
    mutate(base = if_else(is.na(suffix), dataset, paste(dataset, suffix, sep = '_s')),
           unit = paste(doc, dataset, lex, sep = '|'))
}

doc_label <- function(doc) {
  parts <- str_match(doc, '^([^_]+)_(.*)$')
  scroll <- recode(parts[, 2], '1QisaaI' = '1QIsa\u1d43 I', '1QisaaII' = '1QIsa\u1d43 II')
  book <- parts[, 3] |> str_replace_all('_', ' ') |>
    recode('Ecclesiastes' = 'Qoheleth', 'Song of songs' = 'Song of Songs')
  paste(scroll, book)
}

# ---- Form weights and lexeme expectations --------------------------------------

# Lexeme cap: a lexeme with n forms in a document and dataset counts min(cut, n)
# forms in total, in its own proportions.
form_weights <- function(f, cut) {
  n <- ave(rep(1, nrow(f)), f$unit, FUN = length)
  pmin(cut, n) / n
}

# Lexeme-adjusted profile: expected probability of full spelling of each form =
# share of full spelling of its lexeme (same dataset and suffix status) in the
# OTHER documents, shrunk toward the corpus share of the feature.
lexeme_expectation <- function(f) {
  key <- paste(f$base, f$lex)
  p_base <- ave(f$full, f$base)
  n_all <- ave(rep(1, nrow(f)), key, FUN = length); f_all <- ave(f$full, key, FUN = sum)
  kd <- paste(key, f$doc)
  n_doc <- ave(rep(1, nrow(f)), kd, FUN = length); f_doc <- ave(f$full, kd, FUN = sum)
  (f_all - f_doc + LEX_PSEUDO * p_base) / (n_all - n_doc + LEX_PSEUDO)
}

included_docs <- function(f, min_forms) {
  cnt <- table(f$doc)
  sort(names(cnt)[cnt >= min_forms])
}

# Sums per document x feature (dataset x suffix): weighted forms, weighted full
# forms, weighted expected full forms.
aggregate_docs <- function(f, w, docs, bases) {
  keep <- f$doc %in% docs & f$base %in% bases
  key <- paste(f$doc[keep], f$base[keep], sep = '\t')
  s <- rowsum(cbind(w[keep], w[keep] * f$full[keep], w[keep] * f$expect[keep]), key, reorder = FALSE)
  kk <- str_split_fixed(rownames(s), '\t', 2)
  mk <- function(j) { m <- matrix(0, length(docs), length(bases), dimnames = list(docs, bases))
                      m[cbind(match(kk[, 1], docs), match(kk[, 2], bases))] <- s[, j]; m }
  list(tot = mk(1), full = mk(2), expv = mk(3))
}

corpus_stats <- function(a) list(p = colSums(a$full) / colSums(a$tot), w = colSums(a$tot) / sum(a$tot))

make_profile <- function(a, profile, corpus, cells = NULL) {
  P <- matrix(corpus$p, nrow(a$tot), ncol(a$tot), byrow = TRUE)
  W <- matrix(sqrt(corpus$w), nrow(a$tot), ncol(a$tot), byrow = TRUE)
  if (profile == 'rates') return(((a$full + PSEUDO * P) / (a$tot + PSEUDO)) * W)
  if (profile == 'lexadj') return((P + (a$full - a$expv) / (a$tot + PSEUDO)) * W)
  # counts: defective and full forms of each feature, as shares of all forms of the document
  m <- cbind(a$tot - a$full, a$full)
  colnames(m) <- c(paste0(colnames(a$tot), '_f0'), paste0(colnames(a$tot), '_f1'))
  if (!is.null(cells)) m <- m[, cells, drop = FALSE]
  m / rowSums(m)
}

ward <- function(x) hclust(dist(x), method = 'ward.D2')

run_analysis <- function(f, cut = CUT_MAIN, min_forms = MIN_FORMS, profile = MAIN) {
  w <- form_weights(f, cut)
  docs <- included_docs(f, min_forms)
  a <- aggregate_docs(f, w, docs, sort(unique(f$base)))
  # features: bases with more than FEATURE_MIN (capped) forms; counts cells likewise
  bases <- colnames(a$tot)[colSums(a$tot) > FEATURE_MIN]
  a <- lapply(a, function(m) m[, bases, drop = FALSE])
  corpus <- corpus_stats(a)
  cells <- c(paste0(bases, '_f0'), paste0(bases, '_f1'))
  cells <- cells[c(colSums(a$tot - a$full), colSums(a$full)) > FEATURE_MIN]
  x <- make_profile(a, profile, corpus, cells)
  list(docs = docs, bases = bases, cells = cells, corpus = corpus, agg = a, w = w, x = x, hc = ward(x))
}

# ---- Clades and support -----------------------------------------------------------

clades <- function(hc) {
  members <- vector('list', nrow(hc$merge))
  for (i in seq_len(nrow(hc$merge))) {
    side <- function(k) if (k < 0) hc$labels[-k] else members[[k]]
    members[[i]] <- sort(c(side(hc$merge[i, 1]), side(hc$merge[i, 2])))
  }
  members
}
clade_key <- function(x) paste(x, collapse = '|')

# Lexeme bootstrap: within each document, the units (document x dataset x
# lexeme, with all their forms) are resampled with replacement. Weights and
# lexeme expectations stay those of the full data (they belong to the unit);
# documents, features and corpus weights fixed. For each replicate the trees of
# all profiles are built; support of a set of documents = share of replicates
# in which it is a clade of the tree of that profile.
bootstrap_support <- function(f, res, targets, B, seed) {
  set.seed(seed)
  keep <- f$doc %in% res$docs
  f <- f[keep, ]; w <- res$w[keep]
  units_by_doc <- split(unique(f$unit), f$doc[match(unique(f$unit), f$unit)])
  rows_by_unit <- split(seq_len(nrow(f)), f$unit)
  tk <- vapply(targets, clade_key, '')
  hits <- matrix(0, length(tk), length(PROFILES), dimnames = list(tk, PROFILES))
  for (b in seq_len(B)) {
    picked <- unlist(lapply(units_by_doc, function(u) u[sample.int(length(u), length(u), replace = TRUE)]),
                     use.names = FALSE)
    rows <- unlist(rows_by_unit[picked], use.names = FALSE)
    a <- aggregate_docs(f[rows, ], w[rows], res$docs, res$bases)
    for (p in PROFILES) {
      got <- vapply(clades(ward(make_profile(a, p, res$corpus, res$cells))), clade_key, '')
      hits[, p] <- hits[, p] + (tk %in% got)
    }
  }
  hits / B
}

ari <- function(a, b) {
  ct <- table(a, b); comb <- function(x) x * (x - 1) / 2
  s <- sum(comb(ct)); sa <- sum(comb(rowSums(ct))); sb <- sum(comb(colSums(ct))); n <- comb(sum(ct))
  e <- sa * sb / n
  (s - e) / ((sa + sb) / 2 - e)
}

# ---- Tests of a priori groups --------------------------------------------------------

TREBOLLE_1 <- paste0('MT_', c('Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Isaiah',
                             'Hosea', 'Joel', 'Amos', 'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk',
                             'Zephaniah', 'Haggai', 'Zechariah', 'Malachi', 'Psalms', 'Job', 'Proverbs'))
TREBOLLE_2 <- paste0('MT_', c('Joshua', 'Judges', 'Samuel', 'Kings', 'Jeremiah', 'Ezekiel', 'Daniel'))
MIDDLE <- paste0('MT_', c('Isaiah', 'Jeremiah', 'Ezekiel', 'Psalms', 'Nehemiah', 'Chronicles'))

# Is the group closer together than random sets of the same size from the pool?
# Statistic: mean pairwise distance. p = share of random sets at least as close.
group_test <- function(D, members, pool, BT, seed) {
  members <- intersect(members, rownames(D)); pool <- intersect(pool, rownames(D))
  k <- length(members)
  if (k < 2) return(tibble(n = k, pool = length(pool), mean_dist = NA, expected = NA, ratio = NA, p = NA))
  md <- function(s) { d <- D[s, s]; mean(d[upper.tri(d)]) }
  obs <- md(members)
  set.seed(seed)
  null <- replicate(BT, md(sample(pool, k)))
  tibble(n = k, pool = length(pool), mean_dist = obs, expected = mean(null), ratio = obs / mean(null),
         p = (sum(null <= obs) + 1) / (BT + 1))
}

# PERMANOVA F for two (or more) labelled sets of documents; labels permuted.
permanova <- function(D, labels, BT, seed) {
  ids <- names(labels); D <- D[ids, ids]; D2 <- D^2; N <- length(ids)
  fstat <- function(l) {
    g <- unique(l); sst <- sum(D2[upper.tri(D2)]) / N
    ssw <- sum(vapply(g, function(x) { s <- which(l == x); d <- D2[s, s]; sum(d[upper.tri(d)]) / length(s) }, 0))
    ((sst - ssw) / (length(g) - 1)) / (ssw / (N - length(g)))
  }
  obs <- fstat(labels)
  set.seed(seed)
  null <- replicate(BT, fstat(sample(labels)))
  tibble(n = N, groups = paste(table(labels), collapse = ' / '), F = obs, p = (sum(null >= obs) + 1) / (BT + 1))
}

run_tests <- function(res, doc_group, BT, seed) {
  D <- as.matrix(dist(res$x))
  docs <- rownames(D); grp <- doc_group[docs]
  mt <- docs[startsWith(docs, 'MT_')]
  single <- list(
    list('QSP', docs[grp == 'QSP'], docs, 'all documents'),
    list('MT Pentateuch', docs[grp == 'MT Pentateuch'], mt, 'MT books'),
    list('MT Former Prophets', docs[grp == 'MT Former Prophets'], mt, 'MT books'),
    list('MT LBH', docs[grp == 'MT LBH'], mt, 'MT books'),
    list('Middle tier', MIDDLE, mt, 'MT books'),
    list('Non-QSP scrolls', docs[grp == 'Non-QSP'], docs[!grp %in% 'QSP'], 'documents other than QSP'),
    list('SP', docs[grp == 'SP'], c(mt, docs[grp == 'SP']), 'MT and SP books'))
  t1 <- map_dfr(seq_along(single), function(i) {
    s <- single[[i]]
    group_test(D, s[[2]], s[[3]], BT, seed + i) |> mutate(test = s[[1]], reference = s[[4]], .before = 1)
  })
  lab <- function(a, b, na, nb) { ids <- c(intersect(a, docs), intersect(b, docs))
                                  setNames(rep(c(na, nb), c(length(intersect(a, docs)), length(intersect(b, docs)))), ids) }
  pairs <- list(
    list('Trebolle: first vs second series', lab(TREBOLLE_1, TREBOLLE_2, '1', '2')),
    list('Trebolle without the Pentateuch', lab(setdiff(TREBOLLE_1, docs[grp == 'MT Pentateuch']), TREBOLLE_2, '1', '2')),
    list('SP vs MT Pentateuch', lab(docs[grp == 'SP'], docs[grp == 'MT Pentateuch'], 'SP', 'MT')))
  t2 <- map_dfr(seq_along(pairs), function(i) {
    l <- pairs[[i]][[2]]
    if (length(unique(l)) < 2 || min(table(l)) < 2) return(NULL)
    permanova(D, l, BT, seed + 100 + i) |> mutate(test = pairs[[i]][[1]], .before = 1)
  })
  list(single = t1, pairs = t2)
}

# ---- Self-tests (small, synthetic) ------------------------------------------------------

self_tests <- function() {
  f <- tibble(doc = rep(c('A', 'B'), c(102, 10)), dataset = 'd', lex = c(rep('L', 102), rep('M', 10)),
              full = c(rep(0, 100), 1, 1, rep(1, 10)), base = 'd') |> mutate(unit = paste(doc, dataset, lex))
  w <- form_weights(f, 4)
  stopifnot(abs(sum(w[f$doc == 'A']) - 4) < 1e-9, abs(sum(w[f$doc == 'A' & f$full == 1]) - 4 * 2 / 102) < 1e-9)
  f$expect <- lexeme_expectation(f)
  # L occurs only in A: its expectation is the corpus share (no other document)
  stopifnot(abs(f$expect[1] - mean(f$full)) < 1e-9)
  a <- aggregate_docs(f, w, c('A', 'B'), 'd')
  stopifnot(abs(a$tot['A', 'd'] - 4) < 1e-9, abs(a$full['B', 'd'] - 4) < 1e-9)
  cp <- corpus_stats(a)
  stopifnot(all(abs(rowSums(make_profile(a, 'counts', cp)) - 1) < 1e-9))
  hc <- hclust(dist(matrix(c(0, 0.1, 5, 5.1), 4, dimnames = list(c('a', 'b', 'c', 'd')))), 'ward.D2')
  stopifnot(setequal(vapply(clades(hc), clade_key, ''), c('a|b', 'c|d', 'a|b|c|d')))
  stopifnot(abs(ari(c(1, 1, 2, 2), c(2, 2, 1, 1)) - 1) < 1e-9)
  # group test: a tight pair among spread points
  D <- as.matrix(dist(matrix(c(0, 0.01, 3, 6, 9, 12), 6, dimnames = list(letters[1:6]))))
  stopifnot(group_test(D, c('a', 'b'), letters[1:6], 2000, 1)$p < 0.1)
  invisible(TRUE)
}
self_tests()

# ---- Labels -----------------------------------------------------------------------------

SET_LABEL <- c(final_w = paste('final syll.', heb_md('ו')), final_y = paste('final syll.', heb_md('י')),
               single_w = paste('monosyll.', heb_md('ו')), single_y = paste('monosyll.', heb_md('י')),
               first_w = paste('first syll.', heb_md('ו')), first_y = paste('first syll.', heb_md('י')),
               ptca_qal = 'qal act. ptc.', ptcp_qal = 'qal pass. ptc.', infc_qal_triliteral = 'qal inf. cs.',
               infc_qal_lamed_he = paste('qal inf. cs.', heb_md('ל״ה')), infa_qal = 'qal inf. abs.',
               hiphil_triliteral = 'hiphil', niph_hiph_pe_yod = paste(heb_md('פ״י'), 'verbs'))
base_label <- function(base) {
  m <- str_match(base, '^(.*?)(?:_s([01]))?$')
  paste0(SET_LABEL[m[, 2]], if_else(is.na(m[, 3]), '', if_else(m[, 3] == '1', ', suffix', ', no suffix')))
}
GROUP_COLOURS <- c('MT Pentateuch' = BOOK_BLUE, 'MT Former Prophets' = '#6a9fd4', 'MT LBH' = BOOK_ORANGE,
                   'MT other books' = '#8c8c8c', 'SP' = '#2e8b57', 'Non-QSP' = '#7b5ea7', 'QSP' = '#b22222')
group_label <- function(g) recode(g, 'MT other books' = 'MT Other')

# ---- Figures ---------------------------------------------------------------------------

dendro_plot <- function(hc, support, affinity) {
  n <- length(hc$labels)
  ypos <- numeric(n); ypos[hc$order] <- seq_len(n)
  node_y <- numeric(nrow(hc$merge)); segs <- list()
  pos <- function(k) if (k < 0) c(ypos[-k], 0) else c(node_y[k], hc$height[k])
  for (i in seq_len(nrow(hc$merge))) {
    a <- pos(hc$merge[i, 1]); b <- pos(hc$merge[i, 2]); h <- hc$height[i]
    node_y[i] <- mean(c(a[1], b[1]))
    segs[[i]] <- tibble(x = c(a[2], b[2], h), xend = c(h, h, h), y = c(a[1], b[1], a[1]), yend = c(a[1], b[1], b[1]))
  }
  segs <- bind_rows(segs)
  nodes <- tibble(x = hc$height, y = node_y, s = floor(100 * support + 0.5), aff = affinity) |>
    slice(-nrow(hc$merge)) |> filter(s >= 50)
  ggplot() +
    geom_segment(data = segs, aes(x = x, xend = xend, y = y, yend = yend), colour = BOOK_INK_2, linewidth = 0.35) +
    geom_point(data = filter(nodes, aff), aes(x = x, y = y), colour = BOOK_ORANGE, size = 1.4) +
    geom_text(data = nodes, aes(x = x, y = y, label = s), hjust = 1.15, vjust = -0.35, size = 2.3,
              family = BOOK_FONT, colour = BOOK_BLUE) +
    scale_y_continuous(breaks = seq_len(n), labels = doc_label(hc$labels[hc$order]), expand = expansion(add = 0.8)) +
    scale_x_reverse(expand = expansion(mult = c(0.02, 0.08))) +
    labs(x = 'Distance (Ward)', y = NULL,
         caption = str_wrap(paste('Numbers: bootstrap support in percent (lexemes resampled; 50 and above).',
                                  'Orange dot: support of at least 70 percent and recurrence in at least 24 of the 36 settings.'), 115)) +
    theme_book() +
    theme(panel.grid = element_blank(), axis.text.y = element_text(size = if (n > 50) 6.5 else 7.5),
          plot.caption.position = 'plot', plot.caption = element_text(size = 7.5, colour = BOOK_INK_2, hjust = 0))
}

# Heatmap of the percentage of full spelling per feature (unshrunk, after the cap).
heatmap_plot <- function(res) {
  pct <- 100 * res$agg$full / res$agg$tot
  fo <- hclust(dist(t(res$x)), 'ward.D2')$order
  d <- as_tibble(pct, rownames = 'doc') |>
    pivot_longer(-doc, names_to = 'base', values_to = 'value') |>
    mutate(doc = factor(doc_label(doc), levels = doc_label(res$hc$labels[res$hc$order])),
           base = factor(base_label(base), levels = base_label(colnames(res$x)[fo])))
  ggplot(d, aes(x = doc, y = base, fill = value)) +
    geom_tile(colour = 'white', linewidth = 0.2) +
    scale_fill_gradient(low = '#ffffff', high = BOOK_BLUE, limits = c(0, 100), na.value = '#b5b5b5',
                        name = 'Full spelling (percent)') +
    labs(x = NULL, y = NULL, caption = 'Grey: no forms of the feature in the document.') +
    theme_book() +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = if (nrow(pct) > 50) 6 else 7),
          axis.text.y.left = ggtext::element_markdown(size = 7.5, colour = BOOK_INK_2),
          panel.grid = element_blank(), legend.position = 'bottom',
          legend.title = element_text(size = 8, colour = BOOK_INK_2, vjust = 0.8),
          plot.caption.position = 'plot', plot.caption = element_text(size = 7.5, colour = BOOK_INK_2, hjust = 0))
}

map_plot <- function(res, doc_group) {
  pc <- prcomp(res$x, center = TRUE, scale. = FALSE)
  ve <- 100 * pc$sdev^2 / sum(pc$sdev^2)
  sc <- pc$x[, 1:2]
  # orient PC1 so that fuller documents lie to the right
  fullness <- rowSums(res$agg$full) / rowSums(res$agg$tot)
  if (cor(sc[, 1], fullness) < 0) sc[, 1] <- -sc[, 1]
  d <- tibble(doc = rownames(sc), x = sc[, 1], y = sc[, 2], group = doc_group[rownames(sc)],
              label = str_remove(doc_label(rownames(sc)), '^MT '))
  ggplot(d, aes(x, y, colour = group)) +
    geom_hline(yintercept = 0, colour = BOOK_GRID, linewidth = 0.3) +
    geom_vline(xintercept = 0, colour = BOOK_GRID, linewidth = 0.3) +
    geom_point(size = 1.6) +
    geom_text_repel(aes(label = label), size = 2.2, family = BOOK_FONT, max.overlaps = Inf, seed = 1,
                    segment.size = 0.2, min.segment.length = 0.2, show.legend = FALSE) +
    scale_colour_manual(values = GROUP_COLOURS, labels = group_label, name = NULL) +
    labs(x = sprintf('First component (%.0f percent of the variance)', ve[1]),
         y = sprintf('Second component (%.0f percent)', ve[2])) +
    theme_book() + theme(legend.position = 'bottom', legend.text = element_text(size = 7.5))
}

save_fig <- function(p, name, width, height) {
  ggsave(file.path(FIG, paste0(name, '.png')), p, width = width, height = height, units = 'cm', dpi = 600,
         device = ragg::agg_png, bg = 'white')
  ggsave(file.path(FIG, paste0(name, '.pdf')), p, width = width, height = height, units = 'cm', device = cairo_pdf)
}

# ---- Main --------------------------------------------------------------------------------

if (sys.nframe() == 0) {
  t0 <- Sys.time()
  out <- list(clades = list(), grid = list(), recur = list(), docs = list(), tests1 = list(), tests2 = list(),
              pca = list(), grates = list())
  for (a in names(ANALYSES)) {
    spec <- ANALYSES[[a]]
    f <- read_forms(spec$sets, spec$sp)
    f$expect <- lexeme_expectation(f)
    doc_group <- with(distinct(f, doc, .keep_all = TRUE), setNames(as.character(group), doc))
    main <- run_analysis(f)
    cl <- clades(main$hc)
    sup <- bootstrap_support(f, main, cl, B, SEED)
    # settings grid: does each clade of the main tree recur?
    grid <- expand_grid(cut = c(2, 4, 10, Inf), min_forms = c(50, 80, 120), profile = PROFILES)
    rec <- matrix(FALSE, length(cl), nrow(grid))
    grid_rows <- list()
    for (g in seq_len(nrow(grid))) {
      r <- run_analysis(f, grid$cut[g], grid$min_forms[g], grid$profile[g])
      got <- vapply(clades(r$hc), clade_key, '')
      rec[, g] <- vapply(cl, function(x) { y <- sort(intersect(x, r$docs)); length(y) < 2 || clade_key(y) %in% got }, TRUE)
      common <- intersect(main$docs, r$docs)
      k_ari <- map_dbl(2:6, function(k) ari(cutree(main$hc, k)[common], cutree(r$hc, k)[common]))
      grid_rows[[g]] <- tibble(analysis = a, cut = grid$cut[g], min_forms = grid$min_forms[g], profile = grid$profile[g],
                               documents = length(r$docs), !!!setNames(as.list(round(k_ari, 2)), paste0('ari_k', 2:6)))
    }
    tab <- tibble(analysis = a, node = seq_along(cl), size = lengths(cl), height = main$hc$height,
                  support = unname(sup[, 'rates']), support_counts = unname(sup[, 'counts']),
                  support_lexadj = unname(sup[, 'lexadj']), recur = rowSums(rec), settings = nrow(grid),
                  recur_counts = rowSums(rec[, grid$profile == 'counts', drop = FALSE]),
                  recur_lexadj = rowSums(rec[, grid$profile == 'lexadj', drop = FALSE]),
                  members = vapply(cl, function(x) paste(doc_label(x), collapse = '; '), '')) |>
      mutate(affinity = support >= SUPPORT_MIN & recur >= RECUR_MIN & size <= length(main$docs) / 2)
    out$clades[[a]] <- tab
    out$grid[[a]] <- bind_rows(grid_rows)
    out$docs[[a]] <- tibble(analysis = a, doc = main$docs, label = doc_label(main$docs), group = doc_group[main$docs],
                            forms = as.integer(table(f$doc)[main$docs]))
    # tests of a priori groups, in all three profiles (main settings)
    for (p in PROFILES) {
      r <- if (p == MAIN) main else run_analysis(f, profile = p)
      tt <- run_tests(r, doc_group, BT, SEED)
      out$tests1[[paste(a, p)]] <- tt$single |> mutate(analysis = a, profile = !!p, .before = 1)
      out$tests2[[paste(a, p)]] <- tt$pairs |> mutate(analysis = a, profile = !!p, .before = 1)
    }
    # principal components of the main profile
    pc <- prcomp(main$x, center = TRUE, scale. = FALSE)
    out$pca[[a]] <- tibble(analysis = a, feature = colnames(main$x), label = base_label(colnames(main$x)),
                           loading_pc1 = pc$rotation[, 1], loading_pc2 = pc$rotation[, 2],
                           var_pc1 = summary(pc)$importance[2, 1], var_pc2 = summary(pc)$importance[2, 2])
    # percentages of full spelling per group and feature (mean of document percentages, after the cap)
    pct <- 100 * main$agg$full / main$agg$tot
    out$grates[[a]] <- as_tibble(pct, rownames = 'doc') |> mutate(group = doc_group[doc]) |>
      pivot_longer(-c(doc, group), names_to = 'feature', values_to = 'pct') |>
      group_by(group, feature) |> summarise(mean_pct = mean(pct, na.rm = TRUE), docs = sum(!is.na(pct)), .groups = 'drop') |>
      mutate(analysis = a, label = base_label(feature), .before = 1)
    write_tsv(as_tibble(unclass(main$x), rownames = 'doc'), file.path(RES, paste0('profile_rates_', a, '.tsv')))
    write_tsv(as_tibble(pct, rownames = 'doc'), file.path(RES, paste0('percent_full_', a, '.tsv')))
    h <- min(18, max(10, 0.33 * length(main$docs) + 3))
    save_fig(dendro_plot(main$hc, tab$support, tab$affinity), paste0('fig_ch10_', a, '_dendrogram'), 16, h)
    save_fig(heatmap_plot(main), paste0('fig_ch10_', a, '_heatmap'), 16, min(18, 0.35 * length(main$bases) + 9))
    save_fig(map_plot(main, doc_group), paste0('fig_ch10_', a, '_map'), 16, 14)
    message(a, ': ', length(main$docs), ' documents, ', length(main$bases), ' features; ',
            round(difftime(Sys.time(), t0, units = 'mins'), 1), ' min')
  }
  # remove the outputs of the earlier version that no longer exist
  old <- file.path(RES, c('profile_counts_nouns.tsv', 'profile_counts_verbs.tsv', 'profile_counts_combined.tsv',
                          'named_groups.tsv', 'clades_recurrence_by_setting.tsv'))
  file.remove(old[file.exists(old)])
  write_tsv(bind_rows(out$clades), file.path(RES, 'clades_support.tsv'))
  write_tsv(bind_rows(out$clades) |> group_by(analysis) |> filter(size < max(size), support >= 0.5 | affinity) |>
              ungroup() |> arrange(analysis, -support),
            file.path(RES, 'table_10_1_supported_clusters.tsv'))
  write_tsv(bind_rows(out$grid), file.path(RES, 'settings_grid.tsv'))
  write_tsv(bind_rows(out$docs), file.path(RES, 'documents.tsv'))
  write_tsv(bind_rows(out$tests1), file.path(RES, 'group_tests.tsv'))
  write_tsv(bind_rows(out$tests2), file.path(RES, 'group_contrasts.tsv'))
  write_tsv(bind_rows(out$pca), file.path(RES, 'pca_loadings.tsv'))
  write_tsv(bind_rows(out$grates), file.path(RES, 'group_percent_full.tsv'))
  writeLines(c(paste('run', format(Sys.time())), paste('B =', B), paste('BT =', BT), paste('SEED =', SEED),
               paste('MAIN =', MAIN), paste('CUT_MAIN =', CUT_MAIN), paste('MIN_FORMS =', MIN_FORMS),
               paste('FEATURE_MIN =', FEATURE_MIN), paste('PSEUDO =', PSEUDO), paste('LEX_PSEUDO =', LEX_PSEUDO),
               paste('SUPPORT_MIN =', SUPPORT_MIN), paste('RECUR_MIN =', RECUR_MIN)), file.path(RES, 'settings.txt'))
}
