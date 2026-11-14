# Analyses of the book

The R scripts of the statistical analyses in chapters 7–12 of the book. They read the datasets in
`../data`, which are made by the Python pipeline in `../preprocess_data` (see the main README).

| Folder | Chapter | What it does |
|---|---|---|
| `ch07_regression_illustrations` | 7 | Figures of chapter 7 and the Appendix (pooling models of a teaching example; linear and logistic regression) |
| `ch08_nouns_adjectives` | 8 | Bayesian multilevel models of the vowel letters in nouns and adjectives (seven datasets) |
| `ch09_verbs` | 9 | Bayesian multilevel models of the vowel letters in seven verbal forms |
| `ch10_clustering` | 10 | Documents by vowel-letter profile (Ward's method, bootstrap support, direct group tests) |
| `ch11_isaiah` | 11 | Comparison of the manuscripts of Isaiah (Bayesian models and parallels) |
| `ch12_sequences` | 12 | Block spelling and rapid alternation (permutation tests and a model-based null) |
| `shared` | 8–12 | `config.R` and `functions.R` used by all models, and the Charis fonts of the figures |

Each folder has a README with its scripts, method and output. The analyses of chapters 8 and 9 have one
folder per dataset with `analysis.R` (the complete analysis), `REPORT.md` (results and modelling decisions)
and `figures/` (the tables as CSV files; the figures themselves are not in the repository).

## Running the scripts

Run every script from the **root of the repository**; the paths are set in `analysis/paths.R`:

    Rscript analysis/ch09_verbs/ptca_qal/analysis.R

Order:

1. The datasets in `data/` (in the repository; to rebuild them, see the main README).
2. `analysis/ch10_clustering/export_cleaned_data.R` writes the cleaned datasets of chapters 8 and 9 to
   `analysis/ch10_clustering/data/` (not in the repository). Chapters 10, 11 and 12 read them.
3. Chapters 8 and 9 (each dataset separately), 10, 11 and 12, in any order; chapter 12's model-based null
   reads the stored chapter 9 fits (`ch12_sequences/model_weights.R`). Chapter 7 is independent.

### Model fits

The fitted models of chapters 7, 8, 9 and 11 are not in the repository (about 100 GB). The scripts store them in
`analysis/models/` (ignored by git), or in the folder given by the environment variable `SPELLING_MODEL_DIR`,
with one subfolder per analysis (`analysis_nouns`, `analysis_verbs` (also chapter 7), `isaiah`):

    SPELLING_MODEL_DIR=D:/brms_models_spelling Rscript analysis/ch11_isaiah/isaiah_analysis.R

The scripts of chapters 8 and 9 have `ALLOW_FIT <- FALSE` near the top: they then only load stored fits and
stop when a fit is missing. Set `ALLOW_FIT <- TRUE` to fit the models. A complete run of one dataset fits
all candidate models, k-fold cross-validations and robustness checks, which takes hours to more than a day.
The scripts in `tools/` run approved refits from the command line. The chapter 7 and chapter 11 scripts fit
their models when they are missing.

Quick test runs: `CH10_B=20` (chapter 10, bootstrap replicates; default 1,000), `CH12_B=200` (chapter 12,
permutations; default 10,000), `ISA_ONLY_DATA=1` (chapter 11 without models).

### Data versions of the stored fits

The book uses data release v1.4.0 (see below; until 14 November 2026 v1.2.0, commit `37b4f01`). Release v1.2.0 corrected the suffix and ending coding of
some DSS forms after most models of chapters 8 and 9 had been fitted (on the data of 19 October 2026):

- refitted on v1.2.0: the qal passive participle (`ptcp_d3_*`), all models of chapter 11 (`isa_d2_*`; the
  checks of 2026-11-13, `isa_p25_*` and `isa_pair_*`, are also fitted on v1.2.0), and the cleaned datasets of
  chapters 10 and 12;
- fitted on v1.2.0: the three teaching models of chapter 7 (`ch07_teaching_*`);
- unchanged model data: the infinitives (datasets identical), the noun datasets `final_y`, `single_y`,
  `first_w` and `affix_types_mt`, and the final pe-yod model (no suffix term);
- fitted on the earlier data and kept: the nouns `final_w` (2 DSS forms with another `has_suffix`) and
  `single_w` (9), the qal active participle (24) and the triliteral hiphil (8). Their final models were
  refitted on v1.2.0 as a check (`ch08_nouns_adjectives/tools/refit_m6_newdata.R`,
  `ch09_verbs/tools/refit_verbs_newdata.R`; fits `*_data20261103`); no effect changed credibility.

Data release v1.4.0 (2026-11-14) removes one DSS form: XJLB in 4Q130 at Exod. 13.5, lemmatised as XLB=/
(heleb 'fat') but halab 'milk' (`AD_HOC_REMOVALS` in `preprocess_data/src/special_data.py`). It was the only full
form of XLB=/, so the variation filter now drops the lexeme (177 forms). Only the noun dataset `first_y` changes
(776 to 599 forms); everything else is identical to v1.2.0. Refitted or rerun on v1.4.0:

- chapter 8 `first_y`: all models and k-folds (`na_firsty_d4_*`); the final model is now M1 (see
  `ch08_nouns_adjectives/first_y/REPORT.md`);
- chapter 11 first_y (`isa_d4_first_y`, `isa_p25_d4_first_y`, `isa_pair_d4_first_y`);
- chapter 10: the cleaned datasets and the whole cluster analysis (nouns and combined change; verbs identical).

Chapters 7, 9 and 12 use no noun data affected by the change.

The descriptive tables in `figures/` are computed from the v1.2.0 data, those of `first_y` from v1.4.0.

### Choice of the final model (chapters 8 and 9)

The final models contain only credible effects (author's decision, 2026-10-10). Fuller models are described in
the REPORT files with the reason why they were not chosen; effects left out are reported as "no credible
effect" with their estimates from the comparison models. Comments and REPORT files call these the
credible-effects rules:

1. Credible = the 95% interval excludes 0 (pd ≥ 0.975), and the grouped k-fold cross-validation does not
   clearly prefer a fuller model.
2. Factors with several levels (e.g. the document group): the factor is kept if at least one level is
   credible, and all levels are reported with their intervals.
3. A credible effect goes into the final model, even without a gain in the k-fold, unless (i) it rests on
   one or a few lexemes (it disappears in the robustness check without them; it is then reported as a
   lexeme effect), or (ii) it is a proxy for another variable in the model (e.g. the prefix ו for the
   wayyiqtol).
4. If a credible effect in the final model brings no clear gain in the grouped k-fold, the REPORT discusses
   this: the effect is credible but does not predict new books better, why (small effect, few forms or
   books, large variation between books or lexemes), and what that means for the conclusion. For each final
   model, the k-fold comparison with the model without each of its effects is reported.

MT Pentateuch is the reference level of `corpus_group` in every model.

### Notes in the code

Comments and REPORT files refer to decisions of the author with dates, and sometimes to working notes
(`TODO.md`, `BOOK_CHANGES_*.md`, `KFOLD_ISSUE.md`) and earlier scripts (`*_cleaned.R`) that are
not in the repository. The decisions themselves are described in the comments and REPORT files.

## Software

R 4.5.1 with brms 2.23.0 and rstan 2.32.7 (StanHeaders 2.32.10) for the Bayesian models; the cluster
analysis uses `hclust` of the stats package. Other packages (versions used for the book):

| Package | Version | Package | Version | Package | Version |
|---|---|---|---|---|---|
| tidyverse | 2.0.0 | dplyr | 1.1.4 | ggplot2 | 4.0.0 |
| tidyr | 1.3.1 | readr | 2.1.5 | tibble | 3.3.0 |
| purrr | 1.1.0 | stringr | 1.5.2 | forcats | 1.0.0 |
| tidybayes | 3.0.7 | bayesplot | 1.14.0 | bayestestR | 0.17.0 |
| loo | 2.8.0 | posterior | 1.6.1 | binom | 1.1-1.1 |
| patchwork | 1.3.2 | ggpubr | 0.6.2 | ggeffects | 2.3.1 |
| ggtext | 0.2.0 | scales | 1.4.0 | ragg | 1.5.0 |
| systemfonts | 1.2.3 | lme4 | 1.1-37 | future | 1.67.0 |
| kableExtra | 1.4.0 | htmlTable | 2.4.3 | ggrepel | 0.9.6 |

The datasets were made with Python 3 and Text-Fabric 13.1.1 (`../requirements.txt`).
