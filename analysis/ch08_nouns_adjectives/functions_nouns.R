################################################################################
# analysis_nouns: helpers for the noun and adjective analyses
#
# Source after config.R and ../shared/functions.R (the shared
# helpers for fitting, k-fold, effect summaries and book figures).
#
# Data preparation (the same for all scripts, so that the six datasets and the
# affix-type data come from one pipeline):
#   - read_nouns()          import, standard columns, corpus / corpus_group,
#                           syllable position (type, type2, lex_type)
#   - keep_varying()        keep the lexemes that vary in a syllable position
#   - add_lex_vowel_letter() most frequent vowel letter of a lexeme in a position
#   - noun_dataset()        one of the six datasets of NOUN_DATASETS
#   - noun_counts()         forms and lexemes per dataset and corpus, with the
#                           counts in the book
################################################################################

read_nouns <- function() {
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

  # The old script removed tf_id 589682, 595094 (SP lexeme errors) and 1912384
  # (suspect 1QIsaa form); they are no longer in the data (checked 2026-10-19).
  stopifnot(!any(dat$tf_id %in% c(589682, 595094, 1912384)))

  # SP BRJWT (BRJ>/, Gen 41, 6 forms) is full; corrected in the preprocessing
  # since 2026-10-19 (hebrew_spelling_variation, branch sp-brj-vowel-letter).
  stopifnot(all(dat$has_vowel_letter[dat$lex == 'BRJ>/' & dat$g_cons == 'BRJWT'] == 1))

  # Syllable position: last, first or single (monosyllabic stem). type2 merges
  # single and last; lex_type (lexeme + type2) is the unit of the variation
  # filter, as in the book.
  dat$type <- factor(dat$type, levels = c('last', 'first', 'single'))
  dat$type2 <- factor(if_else(dat$type == 'first', 'first', 'last'), levels = c('last', 'first'))
  dat$lex_type <- factor(paste(dat$lex, dat$type2, sep = '_'))

  # Corpus: MT, SP, non-QSP scrolls, QSP scrolls.
  dat$corpus <- factor(case_when(dat$scroll == 'MT' ~ 'MT',
                                 dat$scroll == 'SP' ~ 'SP',
                                 dat$scroll %in% QSP_SCROLLS ~ 'QSP',
                                 TRUE ~ 'Non-QSP'),
                       levels = c('MT', 'SP', 'Non-QSP', 'QSP'))

  # Group of books (for all corpora): Pentateuch, Former Prophets, LBH, Other.
  dat$book_group <- factor(case_when(dat$book %in% LAW_BOOKS ~ 'Pentateuch',
                                     dat$book %in% EBH_BOOKS ~ 'Former Prophets',
                                     dat$book %in% LBH_BOOKS ~ 'LBH',
                                     TRUE ~ 'Other'),
                           levels = c('Pentateuch', 'Former Prophets', 'LBH', 'Other'))

  # Corpus group (config.R): the MT split by group of books; SP, non-QSP and
  # QSP one group each. Reference level MT Pentateuch.
  dat$corpus_group <- factor(case_when(dat$corpus == 'MT' & dat$book_group == 'Other' ~ 'MT other books',
                                       dat$corpus == 'MT' ~ paste('MT', dat$book_group),
                                       TRUE ~ as.character(dat$corpus)),
                             levels = CORPUS_GROUP_LEVELS)
  stopifnot(!anyNA(dat$corpus_group), levels(dat$corpus_group)[1] == 'MT Pentateuch')

  # Robustness: the two halves of 1QIsaa separate from the other QSP scrolls.
  dat$corpus_group_isa <- factor(case_when(dat$scroll == '1QisaaI' ~ '1QIsaa I',
                                           dat$scroll == '1QisaaII' ~ '1QIsaa II',
                                           TRUE ~ as.character(dat$corpus_group)),
                                 levels = c(CORPUS_GROUP_LEVELS, '1QIsaa I', '1QIsaa II'))

  # Passage (book, chapter, verse, lexeme), to find parallel forms.
  dat$passage <- paste(dat$book, dat$chapter, dat$verse, dat$lex)
  dat
}

# Keep the lexemes that are written both full and defective in a syllable
# position (lex_type), counted over all corpora together (as in the book;
# author, 2026-10-19).
keep_varying <- function(dat) {
  varying <- dat |>
    group_by(lex_type) |>
    filter(n_distinct(has_vowel_letter) > 1) |>
    ungroup()
  droplevels(varying)
}

# Most frequent vowel letter of each lexeme among its full forms in one
# syllable position (column lex_vl: W, J, > or a combination such as >W).
# Ties: the old script used max.col() with random ties; here a tie goes to the
# letter that comes first in the order W, J, > (deterministic). In the data of
# 2026-10-19 this concerns FRJG/ and XMC==/ (last), BRK/ and CQMH/ (first).
# Tie rule confirmed by the author (2026-10-19).
LEX_VL_ORDER <- c('W', 'J', '>')

add_lex_vowel_letter <- function(df) {
  vl <- df |>
    filter(vowel_letter != '') |>
    count(lex, vowel_letter) |>
    mutate(order = match(vowel_letter, LEX_VL_ORDER, nomatch = length(LEX_VL_ORDER) + 1)) |>
    group_by(lex) |>
    arrange(desc(n), order, vowel_letter, .by_group = TRUE) |>
    summarise(lex_vl = first(vowel_letter), lex_vl_tie = sum(n == max(n)) > 1, .groups = 'drop')
  left_join(df, vl, by = 'lex')
}

# One of the six datasets (id from NOUN_DATASETS), from the output of
# read_nouns(). Lexemes without a full form in the position cannot occur here
# (keep_varying() keeps only lexemes with full and defective forms).
noun_dataset <- function(dat, id) {
  spec <- NOUN_DATASETS[NOUN_DATASETS$id == id, ]
  stopifnot(nrow(spec) == 1)
  keep_varying(dat) |>
    filter(type == spec$type) |>
    droplevels() |>
    add_lex_vowel_letter() |>
    filter(lex_vl == spec$letter) |>
    droplevels()
}

# Forms and lexemes per dataset (and per corpus), next to the counts in the
# manuscript of 2026-09-10.
noun_counts <- function(dat) {
  map_dfr(NOUN_DATASETS$id, function(id) {
    d <- noun_dataset(dat, id)
    tibble(id = id, forms = nrow(d), lexemes = n_distinct(d$lex),
           ties = n_distinct(d$lex[d$lex_vl_tie]),
           MT = sum(d$corpus == 'MT'), SP = sum(d$corpus == 'SP'),
           `Non-QSP` = sum(d$corpus == 'Non-QSP'), QSP = sum(d$corpus == 'QSP'))
  }) |>
    left_join(BOOK_COUNTS, by = 'id')
}


################################################################################
# TABLES OF SINGLE LEXEMES (the lexeme sections of chapter 8)
#   - lexeme_label()      Hebrew label of an ETCBC lexeme, for book figures
#   - spelling_by_doc()   defective / full per document (scr_book2)
#   - lexeme_profile()    forms and share full per corpus, suffix and prefix
#   - parallel_crosstab() MT vs scroll spelling in parallel passages
#   - parallel_list()     the parallel forms themselves (Hebrew)
# `parallels` is the output of parallel_forms() (verbs functions.R), which
# pairs SP and scroll forms with the MT form of the same lexeme in the verse.
################################################################################

lexeme_label <- function(lex) heb_md(etcbc_to_hebrew(lex))

is_full <- function(x) as.numeric(as.character(x)) == 1

spelling_by_doc <- function(dataset, lexeme, docs = NULL) {
  d <- filter(dataset, lex == lexeme)
  if (!is.null(docs)) d <- filter(d, scr_book2 %in% docs)
  d |>
    mutate(scr_book2 = droplevels(scr_book2)) |>
    group_by(document = scr_book2) |>
    summarise(defective = sum(!is_full(has_vowel_letter)), full = sum(is_full(has_vowel_letter)),
              .groups = 'drop')
}

lexeme_profile <- function(dataset, lexemes) {
  dataset |>
    filter(lex %in% lexemes) |>
    mutate(lex = factor(lex, levels = lexemes)) |>
    group_by(lex, corpus, has_suffix, has_prefix) |>
    summarise(n = n(), full = sum(is_full(has_vowel_letter)), .groups = 'drop') |>
    mutate(share_full = round(full / n, 2))
}

parallel_crosstab <- function(parallels, lexeme, corpora, books = NULL) {
  p <- filter(parallels, lex == lexeme, corpus %in% corpora)
  if (!is.null(books)) p <- filter(p, book %in% books)
  p |>
    mutate(scroll_spelling = if_else(is_full(has_vowel_letter), 'full', 'defective'),
           mt_spelling = if_else(is_full(mt_full), 'MT full', 'MT defective')) |>
    count(scroll_spelling, mt_spelling) |>
    complete(scroll_spelling = c('defective', 'full'), mt_spelling = c('MT defective', 'MT full'),
             fill = list(n = 0)) |>
    pivot_wider(names_from = mt_spelling, values_from = n)
}

# The prefix of the paired MT form (parallel_forms() keeps only its g_cons,
# which has no prefix), numbered in the same way as in parallel_forms().
# Since 2026-11-05 parallel_forms() returns mt_tf_id; the MT form is then
# found by its tf_id (needed with raw occurrences).
add_mt_prefix <- function(parallels, dataset) {
  if ('mt_tf_id' %in% names(parallels)) {
    mt <- dataset |>
      filter(scroll == 'MT') |>
      transmute(.key = as.numeric(as.character(tf_id)), mt_prefix = prefix) |>
      distinct(.key, .keep_all = TRUE)
    return(parallels |> mutate(.key = as.numeric(as.character(mt_tf_id))) |>
             left_join(mt, by = '.key') |> select(-.key))
  }
  mt <- dataset |>
    filter(scroll == 'MT') |>
    group_by(book, chapter, verse, lex) |>
    arrange(tf_id, .by_group = TRUE) |>
    mutate(occurrence = row_number()) |>
    ungroup() |>
    select(book, chapter, verse, lex, occurrence, mt_prefix = prefix)
  left_join(parallels, mt, by = c('book', 'chapter', 'verse', 'lex', 'occurrence'))
}

# Needs the column mt_prefix (add_mt_prefix()).
parallel_list <- function(parallels, lexeme, corpora, books = NULL) {
  p <- filter(parallels, lex == lexeme, corpus %in% corpora)
  if (!is.null(books)) p <- filter(p, book %in% books)
  p |>
    arrange(tf_id) |>
    transmute(reference = paste(book, paste0(chapter, ':', verse)), manuscript = scroll,
              scroll_form = etcbc_to_hebrew(paste0(coalesce(prefix, ''), g_cons)),
              mt_form = etcbc_to_hebrew(paste0(coalesce(mt_prefix, ''), mt_g_cons)), pattern)
}


################################################################################
# STANDARD DESCRIPTIVE FIGURES (the same in every script; harmonised with the
# verbs, author 2026-10-19: corpus_group in the main figures, the book's
# law_phase3 split in one extra figure)
#   - add_affix_labels()   labels for has_suffix / has_prefix
#   - standard_figures()   groups (corpus_group and law_phase3), suffix and
#                          prefix by corpus group, 1QIsaa halves, parallel
#                          passages: figures fig_<tag>_* and tables
#                          table_<tag>_* in IMAGE_FOLDER. Returns the tables.
################################################################################

add_affix_labels <- function(dat) {
  dat |>
    mutate(suffix_label = factor(if_else(has_suffix == 1, 'With suffix', 'Without suffix'),
                                 levels = c('Without suffix', 'With suffix')),
           prefix_label = factor(if_else(has_prefix == 1, 'With prefix', 'Without prefix'),
                                 levels = c('Without prefix', 'With prefix')))
}

# 'MT Other' for 'MT other books' in figures (never in the factor of a fit)
book_group_labels <- function(x) fct_recode(x, 'MT Other' = 'MT other books')

standard_figures <- function(dat, tag, parallels) {
  save_table <- function(tab, name) {
    write_csv(md_to_csv(select(tab, -any_of('row'))),
              file.path(IMAGE_FOLDER, paste0('table_', tag, '_', name, '.csv')))
  }
  out <- list()

  out$groups <- shares_by(dat, corpus_group) |>
    mutate(row = fct_rev(book_group_labels(corpus_group)))
  save_table(out$groups, 'groups')
  save_book_figure(plot_shares(out$groups), paste0('fig_', tag, '_groups'), height = 6)

  out$groups_all <- shares_by(dat, law_phase3) |>
    mutate(row = fct_rev(droplevels(law_phase3)))
  save_table(out$groups_all, 'groups_all')
  save_book_figure(plot_shares(out$groups_all) +
                     labs(caption = "The book's document groups (law_phase3)."),
                   paste0('fig_', tag, '_groups_all'), height = 8)

  for (affix in c('suffix', 'prefix')) {
    tab <- shares_by(dat, corpus_group, label = .data[[paste0(affix, '_label')]]) |>
      mutate(row = fct_rev(book_group_labels(corpus_group)))
    out[[affix]] <- tab
    save_table(tab, affix)
    p <- plot_shares(tab, colour_var = 'label', dodge_width = 0.6,
                     colours = c(BOOK_BLUE, BOOK_ORANGE))
    save_book_figure(p, paste0('fig_', tag, '_', affix), height = 9)
  }

  isaiah <- dat |>
    filter(book2 == 'Isaiah', scroll %in% c('MT', '1QisaaI', '1QisaaII')) |>
    mutate(row = recode(as.character(scroll), MT = 'MT Isaiah', `1QisaaI` = '1QIsaa I',
                        `1QisaaII` = '1QIsaa II')) |>
    shares_by(row)
  other_qsp <- dat |>
    filter(corpus == 'QSP', !scroll %in% c('1QisaaI', '1QisaaII')) |>
    shares_by() |>
    mutate(row = 'Other QSP scrolls')
  out$qsp_isaiah <- bind_rows(isaiah, other_qsp) |>
    mutate(group = row, .before = 1) |>   # kept in the csv (save_table drops row)
    mutate(row = factor(row, levels = rev(c('MT Isaiah', '1QIsaa I', '1QIsaa II',
                                            'Other QSP scrolls'))))
  save_table(out$qsp_isaiah, 'qsp_isaiah')
  save_book_figure(plot_shares(out$qsp_isaiah), paste0('fig_', tag, '_qsp_isaiah'), height = 5)

  out$parallels <- parallels |>
    mutate(corpus = droplevels(corpus)) |>
    count(corpus, pattern) |>
    complete(corpus, pattern = c('MT fuller', 'both defective', 'both full', 'scroll fuller'),
             fill = list(n = 0)) |>
    mutate(pattern = factor(pattern, levels = c('MT fuller', 'both defective', 'both full',
                                                'scroll fuller')))
  save_table(out$parallels, 'parallel_counts')
  p <- ggplot(out$parallels, aes(y = pattern, x = n)) +
    geom_col(fill = BOOK_BLUE, width = 0.6) +
    geom_text(aes(label = n), hjust = -0.3, size = 3, colour = BOOK_INK_2) +
    facet_wrap(~ corpus) +
    scale_x_continuous(expand = expansion(mult = c(0, 0.25))) +
    coord_cartesian(clip = 'off') +
    labs(x = 'Number of parallel forms', y = NULL,
         caption = 'SP and scroll forms paired with the MT form of the same lexeme in the verse.') +
    theme_book() +
    theme(panel.grid.major.y = element_blank(), panel.spacing.x = unit(1, 'cm'))
  save_book_figure(p, paste0('fig_', tag, '_parallel_passages'), height = 6)
  invisible(out)
}


################################################################################
# MODELS (the same design for the six datasets; rules in analysis/README.md)
#
#   - NOUN_MODEL_SPECS    M0 null; M1 corpus; M2 corpus_group; M3 M2 + suffix
#                         + prefix; M4 M3 + corpus_group x suffix; M5 M3 +
#                         corpus_group x prefix; M6 both interactions. The
#                         book's model (nB) is added in the script.
#   - noun_model_file()   <prefix><id>.rds or <prefix><id>_prior<sd>.rds
#   - ensure_noun_model() fit and store a model unless stored (fit_model(),
#                         book_priors(sd), warmup 1000 / iter 3000); with
#                         ALLOW_FIT = FALSE it stops instead of fitting
#   - kfold_table()       loo_compare() of k-fold results as a data frame
#   - noun_total_effects() draws of the total effects: corpus group vs MT
#                         Pentateuch (form without suffix and prefix), and
#                         suffix and prefix within each group
#   - effects_figure()    odds ratios, one panel per effect
#   - noun_predicted()    predicted probability of full spelling per corpus
#                         group, suffix and prefix in the model (re_formula = NA)
################################################################################

NOUN_MODEL_SPECS <- list(
  M0 = has_vowel_letter ~ 1 + (1 | scr_book2/lex),
  M1 = has_vowel_letter ~ corpus + (1 | scr_book2/lex),
  M2 = has_vowel_letter ~ corpus_group + (1 | scr_book2/lex),
  M3 = has_vowel_letter ~ corpus_group + has_suffix + has_prefix + (1 | scr_book2/lex),
  M4 = has_vowel_letter ~ corpus_group * has_suffix + has_prefix + (1 | scr_book2/lex),
  M5 = has_vowel_letter ~ corpus_group * has_prefix + has_suffix + (1 | scr_book2/lex),
  M6 = has_vowel_letter ~ corpus_group * has_suffix + corpus_group * has_prefix +
         (1 | scr_book2/lex)
)

PRIOR_SD <- 2.5

noun_model_file <- function(prefix, id, scale_b = PRIOR_SD) {
  if (scale_b == PRIOR_SD) paste0(prefix, id, '.rds') else paste0(prefix, id, '_prior', scale_b, '.rds')
}

has_fixed_effects <- function(formula) {
  length(attr(terms(lme4::nobars(formula)), 'term.labels')) > 0
}

ensure_noun_model <- function(file, formula, data, scale_b = PRIOR_SD, ...) {
  if (!file.exists(file.path(MODEL_FOLDER, file))) {
    fit_model(file, formula, data, book_priors(scale_b, has_fixed = has_fixed_effects(formula)), ...)
    gc()
  }
  invisible(file)
}

kfold_table <- function(kfolds) {
  as.data.frame(loo_compare(kfolds)) |>
    rownames_to_column('model') |>
    select(model, elpd_diff, se_diff, elpd_kfold, se_elpd_kfold)
}

# brms coefficient names of the corpus groups (and of the 1QIsaa halves in
# corpus_group_isa)
CORPUS_GROUP_COEF <- c('MT Pentateuch' = NA, 'MT Former Prophets' = 'MTFormerProphets',
                       'MT LBH' = 'MTLBH', 'MT other books' = 'MTotherbooks', 'SP' = 'SP',
                       'Non-QSP' = 'NonMQSP', 'QSP' = 'QSP',
                       '1QIsaa I' = '1QIsaaI', '1QIsaa II' = '1QIsaaII')
NOUN_EFFECT_LABELS <- c(corpus = 'Corpus group (vs MT Pentateuch)',
                        corpus_mt = 'Corpus (vs MT)',
                        has_suffix1 = 'Suffix (vs none)',
                        has_prefix1 = 'Prefix (vs none)')

# For every model of NOUN_MODEL_SPECS from M2 on, and for the 1QIsaa split
# (group = 'corpus_group_isa'). An affix without interaction gets one row,
# 'All groups'.
# group = NULL: corpus_group if the model has it, else corpus (M1: MT / SP /
# non-QSP / QSP, effect 'corpus_mt', reference all of the MT; added 2026-11-14
# for first_y, whose final model is M1).
noun_total_effects <- function(model, group = NULL) {
  if (is.null(group))
    group <- if (!'corpus_group' %in% names(model$data) && 'corpus' %in% names(model$data)) 'corpus' else 'corpus_group'
  corpus_effect <- if (group == 'corpus') 'corpus_mt' else 'corpus'
  d <- as_draws_df(model)
  coef_or_0 <- function(name) if (name %in% names(d)) d[[name]] else 0
  b_group <- paste0('b_', group)
  groups <- CORPUS_GROUP_COEF[names(CORPUS_GROUP_COEF) %in% levels(model$data[[group]])]
  corpus <- imap_dfr(groups[!is.na(groups)], function(g, name) {
    if (paste0(b_group, g) %in% names(d)) tibble(effect = corpus_effect, group = name,
                                                  value = d[[paste0(b_group, g)]])
  })
  affixes <- map_dfr(c('has_suffix1', 'has_prefix1'), function(eff) {
    if (!paste0('b_', eff) %in% names(d)) return(NULL)
    interactions <- c(paste0(b_group, groups, ':', eff), paste0('b_', eff, ':', group, groups))
    if (!any(interactions %in% names(d))) {
      return(tibble(effect = eff, group = 'All groups', value = d[[paste0('b_', eff)]]))
    }
    imap_dfr(groups, function(g, name) {
      interaction <- if (is.na(g)) 0 else
        coef_or_0(paste0(b_group, g, ':', eff)) + coef_or_0(paste0('b_', eff, ':', group, g))
      tibble(effect = eff, group = name, value = d[[paste0('b_', eff)]] + interaction)
    })
  })
  # typed columns also for a model without effects (M0)
  bind_rows(tibble(effect = character(), group = character(), value = numeric()), corpus, affixes)
}

summarise_total_effects <- function(draws) {
  group_order <- c(names(CORPUS_GROUP_COEF), 'All groups')
  draws |>
    summarise_effects(effect, group) |>
    mutate(effect_label = factor(NOUN_EFFECT_LABELS[effect], levels = NOUN_EFFECT_LABELS),
           group = factor(group, levels = rev(group_order))) |>
    arrange(effect_label, desc(group))
}

# Odds-ratio breaks for the noun figures (2026-11-03): steps of 16 instead of 4,
# because the QSP contrasts reach odds ratios of 10^4-10^5 and the labels of
# OR_BREAKS ran together at the left ("1/641/16"). The verb figures keep OR_BREAKS.
NOUN_OR_BREAKS <- c(1/4096, 1/256, 1/16, 1, 16, 256, 4096, 65536)
NOUN_OR_LABELS <- c('1/4,096', '1/256', '1/16', '1', '16', '256', '4,096', '65,536')

effects_figure <- function(effects, caption = OR_CAPTION, colour = BOOK_BLUE,
                           breaks = NOUN_OR_BREAKS, labels = NOUN_OR_LABELS) {
  effects |>
    mutate(group = book_group_labels(droplevels(group))) |>
    plot_or(group, colour = colour, caption = caption, breaks = breaks, labels = labels) +
    facet_grid(effect_label ~ ., scales = 'free_y', space = 'free_y', switch = 'y',
               labeller = label_wrap_gen(20)) +
    theme(strip.placement = 'outside', strip.text.y.left = element_text(angle = 0, hjust = 1),
          plot.caption.position = 'plot')
}

# Terms that can be left out one at a time (rule 4): interactions, and main
# effects that are not part of an interaction.
droppable_terms <- function(formula) {
  labels <- attr(terms(lme4::nobars(formula)), 'term.labels')
  in_interaction <- unique(unlist(strsplit(labels[grepl(':', labels)], ':')))
  labels[grepl(':', labels) | !labels %in% in_interaction]
}

# Drop-one formulas of the final model, named <final_id>_no_<term>; a formula
# that is already in `specs` gets that id instead (no second fit).
noun_drop_one <- function(specs, final_id) {
  fixed_terms <- function(f) sort(attr(terms(lme4::nobars(f)), 'term.labels'))
  terms <- droppable_terms(specs[[final_id]])
  set_names(map(terms, function(term) {
    f <- update(specs[[final_id]], as.formula(paste('. ~ . -', term)))
    same <- names(specs)[map_lgl(specs, \(g) identical(fixed_terms(g), fixed_terms(f)))]
    list(id = if (length(same) > 0) same[1] else paste0(final_id, '_no_', gsub(':', '_x_', term)),
         formula = f)
  }), terms)
}

# Effects not in the final model (credible-effects rule), with their
# estimates from the comparison models: corpus group from M2, a common suffix
# or prefix effect from M3, group-specific affix effects from M6.
noun_effects_not_in_final <- function(final_model, prefix) {
  in_final <- noun_total_effects(final_model) |> distinct(effect, group)
  final_effects <- unique(in_final$effect)
  # affixes whose effect differs per group in the final model
  final_by_group <- unique(in_final$effect[in_final$group != 'All groups' & in_final$effect != 'corpus'])
  from <- function(id, effects) {
    if (length(effects) == 0) return(NULL)
    m <- load_model(noun_model_file(prefix, id))
    out <- noun_total_effects(m) |> filter(effect %in% effects) |> mutate(model = id)
    rm(m); gc()
    out
  }
  affixes <- c('has_suffix1', 'has_prefix1')
  # final model M1 (corpus MT / SP / non-QSP / QSP): from M2 only the MT groups
  # vs the MT Pentateuch, which M1 does not distinguish
  mt_groups <- c('MT Former Prophets', 'MT LBH', 'MT other books')
  out <- bind_rows(
    if ('corpus_mt' %in% final_effects) from('M2', 'corpus') |> filter(group %in% mt_groups)
    else from('M2', setdiff('corpus', final_effects)),
    from('M3', setdiff(affixes, final_effects)),
    from('M6', setdiff(affixes, final_by_group))
  )
  if (nrow(out) == 0) return(out)
  filter(out, !(model == 'M6' & group == 'All groups'))
}

noun_predicted <- function(model, data) {
  vars <- intersect(c('corpus_group', 'corpus', 'has_suffix', 'has_prefix'),
                    all.vars(lme4::nobars(formula(model)$formula)))
  grid <- if (length(vars) == 0) tibble(.row = 1) else if (identical(vars, 'corpus'))
    tibble(corpus = factor(levels(data$corpus), levels = levels(data$corpus))) else
    expand_grid(corpus_group = factor(CORPUS_GROUP_LEVELS, levels = CORPUS_GROUP_LEVELS),
                has_suffix = factor(c('0', '1'), levels = levels(data$has_suffix)),
                has_prefix = factor(c('0', '1'), levels = levels(data$has_prefix))) |>
      distinct(across(all_of(vars)))
  grid |>
    add_epred_draws(model, re_formula = NA) |>
    group_by(across(all_of(vars))) |>
    median_qi(.epred, .width = c(0.66, 0.95)) |>
    ungroup()
}
