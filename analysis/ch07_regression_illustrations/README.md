# Chapter 7: illustrations of regression analysis

`figures_ch07.R` makes all figures of chapter 7 (hierarchical Bayesian regression) and of the Appendix
(regression analysis), in the style of chapters 8–9 (`theme_book()`, `save_book_figure()` of
`../shared/functions.R`). They are not part of the analyses of chapters 8–12.

| Figure | Content | File |
|---|---|---|
| 7.1 | logit transformation | `fig_ch07_logit` |
| 7.2 | one-sided p-value | `fig_ch07_p_value` |
| 7.3 | complete pooling | `fig_ch07_pooled` |
| 7.4 | no pooling | `fig_ch07_unpooled` |
| 7.5a | partial pooling, with the overall estimates | `fig_ch07_partial_pooling` |
| 7.5b | no pooling, with the same overall lines | `fig_ch07_unpooled_lines` |
| 7.6 | lexeme counts in MT Esther and Chronicles | `fig_ch07_lexemes_est_chr` |
| A.1–A.7 | linear and logistic regression on simulated heights and weights (seed 42) | `fig_appA_1` … `fig_appA_7` |

Teaching example (§§7.5.3–7.6.1): the qal active participles of MT Pentateuch and the MT core LBH books
(Esther, Daniel, Ezra, Nehemiah, Chronicles), prepared as in `../ch09_verbs/ptca_qal/analysis.R`. Three small
brms models (complete, no and partial pooling) with the book's priors (normal(0, 2.5) for the intercept and
coefficients, exponential(1) for the SD) are fitted once and stored as `ch07_teaching_<pooled|unpooled|partial>.rds`
in `analysis_verbs/` of the model folder (see `../README.md`); a few minutes. Summaries: posterior median with
equal-tailed 66% and 95% intervals; Figures 7.4 and 7.5b come from the same fit.

Run from the repository root: `Rscript analysis/ch07_regression_illustrations/figures_ch07.R`. The plotted
values are written to `figures/` (`table_ch07_teaching_models.csv`, `table_ch07_teaching_raw.csv`,
`table_ch07_lexemes_est_chr.csv`, `table_appA_categ_model.csv`); the figures themselves are not in the
repository.

Replaces `bell_curve_p_value.R`, `linear_logistic_regression.R` and
`make_images_unpooled_pooled_mixed_models.R` (2026-11-11; in the repository history). The last of these
illustrated the models with nouns and adjectives and was not used for the book.
