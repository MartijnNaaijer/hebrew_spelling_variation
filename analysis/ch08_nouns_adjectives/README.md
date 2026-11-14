# Chapter 8: nouns and adjectives

Bayesian multilevel logistic regression (brms) of the use of the vowel letters ו and י in nouns and adjectives
in MT, SP and the biblical DSS. One folder per dataset:

| Folder | Book § | Dataset | Final model |
|---|---|---|---|
| `final_w` | 8.2.2 | final syllable, optional ו | M6 |
| `final_y` | 8.2.3 | final syllable, optional י | nB |
| `single_w` | 8.3.2 | monosyllabic stem, optional ו | M6 |
| `single_y` | 8.3.3 | monosyllabic stem, optional י | M0 |
| `first_w` | 8.4.2 | first syllable, optional ו | M6 |
| `first_y` | 8.4.3 | first syllable, optional י | M0 |
| `affix_types_mt` | 8.5 | types of affixes, final syllable ו and י, MT only | waw A2, yod A3 |

All models have the random intercepts `(1 | scr_book2/lex)` (lexemes within documents). The formulas, the
model comparison (grouped k-fold cross-validation), the checks and the results are in each folder's
`REPORT.md`.

## Files

```
config.R              model folder, corpus groups, the datasets (sources ../shared/config.R)
functions_nouns.R     data preparation shared by the noun analyses (read_nouns, noun_dataset)
<dataset>/
  analysis.R          the complete analysis of the dataset
  REPORT.md           results and decisions
  figures/            tables (CSV); the figures are written here too, but are not in the repository
book_ch8/             make_book_items.R: book figures and tables built from the CSV tables and the
                      stored final fits (nothing is fitted); table_ch8_model_summaries.csv
checks/               convergence, credible terms and pointwise k-fold checks of the stored fits
tools/                run_dataset.R (fitting run of one dataset), refit_m6_newdata.R (check of
                      data release v1.2.0), fit_firstw_nb_cg.R (first_w: model nB_cg of
                      Table 8.36 and its k-folds)
```

Every `analysis.R` has the same sections: 0 setup, 1 data import and preparation, 2 exploratory analysis,
3 data modelling, 4 data visualisation, 5 model verification. Shared helpers are in `../shared/functions.R`.

## Running

From the repository root, e.g. `Rscript analysis/ch08_nouns_adjectives/final_w/analysis.R`. The model fits
are read from `analysis_nouns` in the model folder (see `../README.md`). With `ALLOW_FIT <- FALSE` (the
default) the script only loads stored fits.

## Data

`final_w` and `single_w` were fitted on the data of 19 October 2026. Data release v1.2.0 changed
`has_suffix` of 2 and 9 DSS forms in these datasets; M6 was refitted on v1.2.0 as a check
(`tools/refit_m6_newdata.R`): the estimates of `final_w` changed by at most 0.02, and no credible effect of
`single_w` changed. The stored models were kept. The model data of the other five datasets are the same in
v1.2.0.
