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

The book uses data release v1.2.0 (commit `37b4f01`). That release corrected the suffix and ending coding of
some DSS forms after most models of chapters 8 and 9 had been fitted (on the data of 19 October 2026):

- refitted on v1.2.0: the qal passive participle (`ptcp_d3_*`), all models of chapter 11 (`isa_d2_*`; the
  checks of 2026-11-13, `isa_p25_*` and `isa_pair_*`, are also fitted on v1.2.0), and the cleaned datasets of
  chapters 10 and 12;
- fitted on v1.2.0: the three teaching models of chapter 7 (`ch07_teaching_*`);
- unchanged model data: the infinitives (datasets identical), the five noun datasets other than `final_w`
  and `single_w`, and the final pe-yod model (no suffix term);
- fitted on the earlier data and kept: the nouns `final_w` (2 DSS forms with another `has_suffix`) and
  `single_w` (9), the qal active participle (24) and the triliteral hiphil (8). Their final models were
  refitted on v1.2.0 as a check (`ch08_nouns_adjectives/tools/refit_m6_newdata.R`,
  `ch09_verbs/tools/refit_verbs_newdata.R`; fits `*_data20261103`); no effect changed credibility.

The descriptive tables in `figures/` are computed from the v1.2.0 data.

### Notes in the code

Comments and REPORT files refer to decisions of the author with dates, and sometimes to working notes
(`TODO.md`, `CLAUDE.md`, `BOOK_CHANGES_*.md`, `KFOLD_ISSUE.md`) and earlier scripts (`*_cleaned.R`) that are
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
