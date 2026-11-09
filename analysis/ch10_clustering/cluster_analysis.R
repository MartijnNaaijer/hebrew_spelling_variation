################################################################################
# Chapter 10: hierarchical cluster analysis of documents (2026-11-03)
#
# Replaces notebooks/clustering_spelling*.ipynb (hebrew_spelling_variation).
# Decisions: Claude doc "Chapter 10 revision: cluster analysis" (author,
# 2026-11-03):
#   1. Main profile: counts (which texts look alike in their spelling, as a
#      reader meets them), normalised within each document. Check profile:
#      share of full spelling per feature cell, weighted by the cell's frequency
#      in the whole corpus (spelling habits without differences in content).
#   2. Frequent lexemes: cap per lexeme (within document and dataset); the
#      lexeme keeps its share of full spelling.
#   3. Data: the cleaned datasets of chapters 8 and 9 (export_cleaned_data.R).
#   4. Documents: one rule, counted before capping: at least MIN_FORMS forms.
#      Units as in the models (scr_book2; 1QIsaa in two halves).
#   5. Stability: bootstrap support per cluster (forms resampled within each
#      document) and a grid of settings.
#   6. Three analyses: nouns and adjectives (with SP), verbs, combined.
#
# Feature = dataset x spelling (0 defective, 1 full) x suffix (0, 1). The
# suffix variable is the one of the chapter 8-9 models (SUFFIX_COL).
#
# Run:  Rscript cluster_analysis.R            (all; B bootstrap replicates)
# Output: results/*.tsv, figures/*.png|pdf
################################################################################

suppressMessages({
  library(tidyverse)
  library(patchwork)
})
source('analysis/paths.R')
source(file.path(SHARED_DIR, 'functions.R'))  # theme_book, BOOK_*

HERE <- CH10_DIR
DATA <- CLEANED_DATA_DIR; RES <- file.path(HERE, 'results'); FIG <- file.path(HERE, 'figures')
dir.create(RES, showWarnings = FALSE); dir.create(FIG, showWarnings = FALSE)

CUT_MAIN <- 4          # lexeme cap
MIN_FORMS <- 80        # documents: at least this many forms (before capping)
FEATURE_MIN <- 10      # features: total (capped) count over the documents > FEATURE_MIN
PSEUDO <- 2            # check profile: pseudo-count toward the corpus rate
B <- as.integer(Sys.getenv('CH10_B', '1000'))   # bootstrap replicates (CH10_B=50 for a quick test)
SEED <- 20261103

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
    tibble(doc = d$scr_book2, scroll = d$scroll, dataset = id, lex = d$lex,
           full = as.integer(d$has_vowel_letter),
           suffix = if (is.na(scol)) NA_integer_ else as.integer(d[[scol]]))
  }) |>
    filter(sp | scroll != 'SP') |>
    mutate(base = if_else(is.na(suffix), dataset, paste(dataset, suffix, sep = '_s')),
           cell = paste(base, full, sep = '_f'))
}

# Readable document labels: 'MT Qoheleth', '1QIsaa I Isaiah', '4Q22 Exodus'.
doc_label <- function(doc) {
  parts <- str_match(doc, '^([^_]+)_(.*)$')
  scroll <- recode(parts[, 2], '1QisaaI' = '1QIsa\u1d43 I', '1QisaaII' = '1QIsa\u1d43 II')
  book <- parts[, 3] |> str_replace_all('_', ' ') |>
    recode('Ecclesiastes' = 'Qoheleth', 'Song of songs' = 'Song of Songs')
  paste(scroll, book)
}

# ---- Profiles -------------------------------------------------------------------

# Weight of each form: a lexeme with n forms in a document and dataset counts
# min(cut, n) forms in total, in its own proportions (decision 2).
form_weights <- function(f, cut) {
  n <- ave(rep(1, nrow(f)), f$doc, f$dataset, f$lex, FUN = length)
  pmin(cut, n) / n
}

included_docs <- function(f, min_forms) {
  cnt <- table(f$doc)
  names(cnt)[cnt >= min_forms]
}

cell_counts <- function(f, w, docs, cells = NULL) {
  keep <- f$doc %in% docs
  m <- xtabs(w[keep] ~ f$doc[keep] + f$cell[keep])
  m <- matrix(m, nrow = nrow(m), dimnames = dimnames(m))
  if (!is.null(cells)) {
    out <- matrix(0, nrow(m), length(cells), dimnames = list(rownames(m), cells))
    common <- intersect(cells, colnames(m)); out[, common] <- m[, common]; m <- out
  }
  m[docs, , drop = FALSE]
}

profile_counts <- function(m) m / rowSums(m)

# Check profile: share of full spelling per base cell (dataset x suffix),
# shrunk toward the corpus share with PSEUDO forms, columns weighted by the
# square root of the base cell's share of all forms (weighted Euclidean distance).
profile_rates <- function(m, corpus = NULL) {
  base <- str_remove(colnames(m), '_f[01]$')
  bases <- unique(base)
  full <- sapply(bases, function(b) { j <- colnames(m) == paste0(b, '_f1'); if (any(j)) m[, j] else rep(0, nrow(m)) })
  tot <- sapply(bases, function(b) rowSums(m[, base == b, drop = FALSE]))
  full <- matrix(full, nrow(m), dimnames = list(rownames(m), bases))
  tot <- matrix(tot, nrow(m), dimnames = list(rownames(m), bases))
  if (is.null(corpus)) corpus <- list(p = colSums(full) / colSums(tot), w = colSums(tot) / sum(tot))
  rate <- (full + matrix(PSEUDO * corpus$p, nrow(full), ncol(full), byrow = TRUE)) / (tot + PSEUDO)
  structure(sweep(rate, 2, sqrt(corpus$w), '*'), corpus = corpus)
}

ward <- function(x) hclust(dist(x), method = 'ward.D2')

# ---- Clusters and support --------------------------------------------------------

# All clades (sets of documents joined at a merge) of an hclust tree.
clades <- function(hc) {
  members <- vector('list', nrow(hc$merge))
  for (i in seq_len(nrow(hc$merge))) {
    side <- function(k) if (k < 0) hc$labels[-k] else members[[k]]
    members[[i]] <- sort(c(side(hc$merge[i, 1]), side(hc$merge[i, 2])))
  }
  members
}
clade_key <- function(x) paste(x, collapse = '|')

# Bootstrap: forms resampled within each document; documents, features and
# corpus weights fixed. Support = share of replicates that contain the clade.
bootstrap_support <- function(f, docs, cells, cut, profile, hc, B, seed) {
  set.seed(seed)
  f <- f[f$doc %in% docs, ]
  idx <- split(seq_len(nrow(f)), f$doc)
  target <- vapply(clades(hc), clade_key, '')
  hits <- setNames(numeric(length(target)), target)
  corpus <- if (profile == 'rates') attr(profile_rates(cell_counts(f, form_weights(f, cut), docs, cells)), 'corpus')
  for (b in seq_len(B)) {
    pick <- unlist(lapply(idx, function(i) i[sample.int(length(i), length(i), replace = TRUE)]), use.names = FALSE)
    fb <- f[pick, ]
    m <- cell_counts(fb, form_weights(fb, cut), docs, cells)
    x <- if (profile == 'counts') profile_counts(m) else profile_rates(m, corpus)
    got <- vapply(clades(ward(x)), clade_key, '')
    hits <- hits + (target %in% got)
  }
  hits / B
}

ari <- function(a, b) {
  ct <- table(a, b); comb <- function(x) x * (x - 1) / 2
  s <- sum(comb(ct)); sa <- sum(comb(rowSums(ct))); sb <- sum(comb(colSums(ct))); n <- comb(sum(ct))
  e <- sa * sb / n
  (s - e) / ((sa + sb) / 2 - e)
}

# ---- One analysis ------------------------------------------------------------------

run_analysis <- function(f, cut = CUT_MAIN, min_forms = MIN_FORMS, profile = 'counts') {
  w <- form_weights(f, cut)
  docs <- included_docs(f, min_forms)
  m <- cell_counts(f, w, docs)
  m <- m[, colSums(m) > FEATURE_MIN, drop = FALSE]
  x <- if (profile == 'counts') profile_counts(m) else profile_rates(m)
  list(docs = docs, cells = colnames(m), counts = m, x = x, hc = ward(x))
}

# ---- Self-tests (small, synthetic) ---------------------------------------------------

self_tests <- function() {
  f <- tibble(doc = rep(c('A', 'B'), c(102, 10)), dataset = 'd', lex = c(rep('L', 102), rep('M', 10)),
              full = c(rep(0, 100), 1, 1, rep(1, 10)), cell = paste0('d_f', full))
  w <- form_weights(f, 4)
  stopifnot(abs(sum(w[f$doc == 'A']) - 4) < 1e-9,                       # capped to 4 in total
            abs(sum(w[f$doc == 'A' & f$full == 1]) - 4 * 2 / 102) < 1e-9)  # share of full kept
  m <- cell_counts(f, w, c('A', 'B'))
  stopifnot(all(abs(rowSums(profile_counts(m)) - 1) < 1e-9))
  r <- profile_rates(m)
  stopifnot(all(r >= 0))
  hc <- hclust(dist(matrix(c(0, 0.1, 5, 5.1), 4, dimnames = list(c('a', 'b', 'c', 'd')))), 'ward.D2')
  cl <- vapply(clades(hc), clade_key, '')
  stopifnot(setequal(cl, c('a|b', 'c|d', 'a|b|c|d')))
  stopifnot(abs(ari(c(1, 1, 2, 2), c(2, 2, 1, 1)) - 1) < 1e-9)
  invisible(TRUE)
}
self_tests()

# ---- Labels for features --------------------------------------------------------------

SET_LABEL <- c(final_w = paste('final syll.', heb_md('ו')), final_y = paste('final syll.', heb_md('י')),
               single_w = paste('monosyll.', heb_md('ו')), single_y = paste('monosyll.', heb_md('י')),
               first_w = paste('first syll.', heb_md('ו')), first_y = paste('first syll.', heb_md('י')),
               ptca_qal = 'qal act. ptc.', ptcp_qal = 'qal pass. ptc.', infc_qal_triliteral = 'qal inf. cs.',
               infc_qal_lamed_he = paste('qal inf. cs.', heb_md('ל״ה')), infa_qal = 'qal inf. abs.',
               hiphil_triliteral = 'hiphil', niph_hiph_pe_yod = paste(heb_md('פ״י'), 'verbs'))
feature_label <- function(cell) {
  m <- str_match(cell, '^(.*?)(?:_s([01]))?_f([01])$')
  paste0(SET_LABEL[m[, 2]], if_else(is.na(m[, 3]), '', if_else(m[, 3] == '1', ', suffix', ', no suffix')),
         if_else(m[, 4] == '1', ', full', ', defective'))
}

# ---- Figures ---------------------------------------------------------------------------

# Horizontal dendrogram with bootstrap support (percent) at the internal nodes;
# a filled dot marks clades that also occur with the check profile (spelling rates).
dendro_plot <- function(hc, support, in_check, title = NULL) {
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
  nodes <- tibble(x = hc$height, y = node_y, s = floor(100 * support + 0.5), check = in_check) |>
    slice(-nrow(hc$merge)) |>          # the root (all documents) always has 100
    filter(s >= 50)
  ggplot() +
    geom_segment(data = segs, aes(x = x, xend = xend, y = y, yend = yend), colour = BOOK_INK_2, linewidth = 0.35) +
    geom_point(data = filter(nodes, check), aes(x = x, y = y), colour = BOOK_BLUE, size = 1.2) +
    geom_text(data = nodes, aes(x = x, y = y, label = s), hjust = 1.15, vjust = -0.35, size = 2.3,
              family = BOOK_FONT, colour = BOOK_BLUE) +
    scale_y_continuous(breaks = seq_len(n), labels = doc_label(hc$labels[hc$order]), expand = expansion(add = 0.8)) +
    scale_x_reverse(expand = expansion(mult = c(0.02, 0.08))) +
    labs(x = 'Distance (Ward)', y = NULL, title = title,
         caption = 'Numbers: bootstrap support in percent (50 and above). Dot: the cluster also occurs with the spelling rates.') +
    theme_book() +
    theme(panel.grid = element_blank(), axis.text.y = element_text(size = if (n > 50) 6.5 else 7.5),
          plot.caption.position = 'plot', plot.caption = element_text(size = 7.5, colour = BOOK_INK_2, hjust = 0))
}

heatmap_plot <- function(res) {
  x <- res$x
  fo <- hclust(dist(t(x)), 'ward.D2')$order
  d <- as_tibble(x, rownames = 'doc') |>
    pivot_longer(-doc, names_to = 'cell', values_to = 'value') |>
    mutate(doc = factor(doc_label(doc), levels = doc_label(res$hc$labels[res$hc$order])),
           cell = factor(feature_label(cell), levels = feature_label(colnames(x)[fo])))
  ggplot(d, aes(x = doc, y = cell, fill = value)) +
    geom_tile(colour = 'white', linewidth = 0.2) +
    scale_fill_gradient(low = '#ffffff', high = BOOK_BLUE, name = "Share of the document's forms") +
    labs(x = NULL, y = NULL) +
    theme_book() +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = if (nrow(x) > 50) 6 else 7),
          axis.text.y.left = ggtext::element_markdown(size = if (ncol(x) > 30) 6.2 else 7.5, colour = BOOK_INK_2),
          panel.grid = element_blank(), legend.position = 'bottom',
          legend.title = element_text(size = 8, colour = BOOK_INK_2, vjust = 0.8))
}

save_fig <- function(p, name, width, height) {
  ggsave(file.path(FIG, paste0(name, '.png')), p, width = width, height = height, units = 'cm', dpi = 600,
         device = ragg::agg_png, bg = 'white')
  ggsave(file.path(FIG, paste0(name, '.pdf')), p, width = width, height = height, units = 'cm', device = cairo_pdf)
}

# ---- Named groups of the book (§10.5) ---------------------------------------------------

GROUPS <- list(
  QSP = c('11Q5_Psalms', '1QisaaI_Isaiah', '1QisaaII_Isaiah', '4Q27_Numbers', '4Q57_Isaiah'),
  `MT Pentateuch` = paste0('MT_', c('Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy')),
  `MT LBH` = paste0('MT_', c('Chronicles', 'Ezra', 'Nehemiah', 'Esther', 'Daniel')),
  `middle tier` = paste0('MT_', c('Isaiah', 'Jeremiah', 'Ezekiel', 'Psalms', 'Nehemiah', 'Chronicles')),
  SP = paste0('SP_', c('Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy')))

# Smallest clade that contains all members of a group, and how many others it holds.
group_clade <- function(hc, members, support) {
  m <- intersect(members, hc$labels)
  if (length(m) < 2) return(tibble(present = length(m), smallest_clade = NA, others = NA, support = NA))
  cl <- clades(hc)
  ok <- which(vapply(cl, function(c) all(m %in% c), TRUE))
  i <- ok[which.min(lengths(cl[ok]))]
  tibble(present = length(m), smallest_clade = length(cl[[i]]), others = length(cl[[i]]) - length(m),
         support = unname(support[i]))
}

# ---- Main --------------------------------------------------------------------------------

if (sys.nframe() == 0) {
  t0 <- Sys.time()
  all_clades <- list(); all_groups <- list(); all_grid <- list(); all_docs <- list(); recur <- list()
  for (a in names(ANALYSES)) {
    spec <- ANALYSES[[a]]
    f <- read_forms(spec$sets, spec$sp)
    main <- run_analysis(f)
    check <- run_analysis(f, profile = 'rates')
    stopifnot(identical(sort(main$docs), sort(check$docs)))
    sup <- bootstrap_support(f, main$docs, main$cells, CUT_MAIN, 'counts', main$hc, B, SEED)
    sup_chk <- bootstrap_support(f, check$docs, check$cells, CUT_MAIN, 'rates', check$hc, B, SEED)
    keys_chk <- vapply(clades(check$hc), clade_key, '')
    cl <- clades(main$hc)
    keys <- vapply(cl, clade_key, '')
    tab <- tibble(analysis = a, node = seq_along(cl), size = lengths(cl), height = main$hc$height,
                  support = unname(sup), in_check = keys %in% keys_chk,
                  support_check = unname(sup_chk[match(keys, keys_chk)]),
                  members = vapply(cl, function(x) paste(doc_label(x), collapse = '; '), ''))
    all_clades[[a]] <- tab
    all_docs[[a]] <- tibble(analysis = a, doc = main$docs, label = doc_label(main$docs),
                            forms = as.integer(table(f$doc)[main$docs]))
    all_groups[[a]] <- imap_dfr(GROUPS, function(m, g) bind_rows(
      group_clade(main$hc, m, sup) |> mutate(profile = 'counts'),
      group_clade(check$hc, m, sup_chk) |> mutate(profile = 'rates')) |> mutate(group = g)) |>
      mutate(analysis = a)
    # Grid of settings: do the well-supported clades (support >= 0.7, 2 to 15
    # documents) recur? Documents missing in a setting are left out of the clade.
    key_cl <- which(sup >= 0.7 & lengths(cl) >= 2 & lengths(cl) <= 15)
    grid <- expand_grid(cut = c(2, 4, 10, Inf), min_forms = c(50, 80, 120), profile = c('counts', 'rates'))
    all_grid[[a]] <- pmap_dfr(grid, function(cut, min_forms, profile) {
      r <- run_analysis(f, cut, min_forms, profile)
      got <- vapply(clades(r$hc), clade_key, '')
      for (j in key_cl) {
        y <- sort(intersect(cl[[j]], r$docs))
        recur[[length(recur) + 1]] <<- tibble(analysis = a, node = j, cut = cut, min_forms = min_forms,
                                               profile = profile, present = length(y),
                                               recovered = length(y) < 2 || clade_key(y) %in% got)
      }
      common <- intersect(main$docs, r$docs)
      k_ari <- map_dbl(2:6, function(k) ari(cutree(main$hc, k)[common], cutree(r$hc, k)[common]))
      tibble(analysis = a, cut = cut, min_forms = min_forms, profile = profile, documents = length(r$docs),
             !!!setNames(as.list(round(k_ari, 2)), paste0('ari_k', 2:6)),
             clades_recovered = sum(vapply(cl[key_cl], function(x) {
               y <- sort(intersect(x, r$docs)); length(y) < 2 || clade_key(y) %in% got }, TRUE)),
             clades_tested = length(key_cl))
    })
    write_tsv(as_tibble(main$x, rownames = 'doc'), file.path(RES, paste0('profile_counts_', a, '.tsv')))
    write_tsv(as_tibble(unclass(check$x), rownames = 'doc'), file.path(RES, paste0('profile_rates_', a, '.tsv')))
    # book text block: 15.8 cm wide, at most about 18 cm for a figure with its caption
    h <- min(18, max(10, 0.33 * length(main$docs) + 3))
    save_fig(dendro_plot(main$hc, sup, tab$in_check), paste0('fig_ch10_', a, '_dendrogram'), 16, h)
    save_fig(heatmap_plot(main), paste0('fig_ch10_', a, '_heatmap'), 16, min(18, 0.3 * length(main$cells) + 8))
    message(a, ': ', length(main$docs), ' documents, ', length(main$cells), ' features; ',
            round(difftime(Sys.time(), t0, units = 'mins'), 1), ' min')
  }
  write_tsv(bind_rows(all_clades), file.path(RES, 'clades_support.tsv'))
  write_tsv(bind_rows(all_groups), file.path(RES, 'named_groups.tsv'))
  write_tsv(bind_rows(all_grid), file.path(RES, 'settings_grid.tsv'))
  # Per well-supported cluster: in how many of the 24 settings it recurs (Table 10.1)
  write_tsv(bind_rows(recur), file.path(RES, 'clades_recurrence_by_setting.tsv'))
  bind_rows(recur) |>
    group_by(analysis, node) |>
    summarise(settings = n(), recovered = sum(recovered), .groups = 'drop') |>
    left_join(bind_rows(all_clades) |> select(analysis, node, size, support, in_check, support_check, members),
              by = c('analysis', 'node')) |>
    arrange(analysis, size) |>
    write_tsv(file.path(RES, 'table_10_1_supported_clusters.tsv'))
  write_tsv(bind_rows(all_docs), file.path(RES, 'documents.tsv'))
  writeLines(c(paste('run', format(Sys.time())), paste('B =', B), paste('CUT_MAIN =', CUT_MAIN),
               paste('MIN_FORMS =', MIN_FORMS), paste('FEATURE_MIN =', FEATURE_MIN), paste('PSEUDO =', PSEUDO)),
             file.path(RES, 'settings.txt'))
}
