################################################################################
# Chapter 12: Figures 12.3 and 12.6 (fig_ch12_<feature>_books) redrawn from the
# stored results, without new permutations (2026-11-14): results/units.tsv of the
# main run, and for Chronicles (qal active participle) the corrected p-values of
# results/chronicles_precision.tsv (1,000,000 orderings). Use after a change of
# the figure code in sequence_analysis.R (here: the caption on books whose
# stratified comparison is not possible).
#
# Run from the repository root, after sequence_analysis.R and chronicles_precision.R:
#   Rscript analysis/ch12_sequences/redraw_books_figures.R
################################################################################

suppressMessages(source('analysis/ch12_sequences/sequence_analysis.R'))   # definitions only (main block is skipped)

u <- read_tsv(file.path(RES, 'units.tsv'), show_col_types = FALSE)
cp <- read_tsv(file.path(RES, 'chronicles_precision.tsv'), show_col_types = FALSE)
for (f in names(FEATURES)) {
  uf <- filter(u, feature == f)
  if (f == 'ptca_qal')
    uf <- mutate(uf,
      strat_q = if_else(corpus == 'MT' & unit == 'Chronicles', cp$p_corrected[cp$null == 'within lexeme and suffix'], strat_q),
      model_q = if_else(corpus == 'MT' & unit == 'Chronicles', cp$p_corrected[cp$null == 'model-based'], model_q))
  save_fig(books_plot(uf), paste0('fig_ch12_', f, '_books'), 15.8, max(8, 0.42 * sum(uf$corpus == 'MT') + 3))
  message(f, ': redrawn')
}
