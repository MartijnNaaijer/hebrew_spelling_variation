# Chapter 7: illustrations of regression analysis

Scripts for the explanatory figures of chapter 7 (Bayesian regression analysis). They are not part of the
analyses of chapters 8–12.

| Script | Figures |
|---|---|
| `bell_curve_p_value.R` | normal curve with a marked effect (p-value illustration) |
| `linear_logistic_regression.R` | linear and logistic regression on made-up data; writes `figures/*.png` |
| `make_images_unpooled_pooled_mixed_models.R` | pooled, unpooled and multilevel (mixed) models of the vowel letters in MT nouns and adjectives with spelling variation (`data/nouns_adjectives.csv`; Genesis, Exodus, Jonah, Obadiah, Ruth; predictor `has_nme`), fitted with brms |

Run from the repository root, e.g. `Rscript analysis/ch07_regression_illustrations/linear_logistic_regression.R`.
`make_images_unpooled_pooled_mixed_models.R` fits its models each time (no stored fits) and draws its
figures in the R session.
