# Chapter 9: verbs

Bayesian multilevel logistic regression (brms) of the use of vowel letters in seven verbal forms in MT and
the biblical DSS. One folder per verbal form:

| Folder | Book § | Dataset | Final model |
|---|---|---|---|
| `ptca_qal` | 9.2 | `ptca_qal.csv` | M7 |
| `ptcp_qal` | 9.3 | `ptcp_qal.csv` | M7 |
| `infc_qal_triliteral` | 9.4 | `infc_qal_triliteral.csv` | M2 |
| `infc_qal_lamed_he` | 9.5 | `infc_qal_lamed_he.csv` | M4p |
| `infa_qal` | 9.6 | `infa_qal.csv` | M3 |
| `hiphil_triliteral` | 9.7 | `hiphil_triliteral_with_hireq.csv` | M7 |
| `niph_hiph_pe_yod` | 9.8 | `niph_hiph_pe_yod.csv` | M1 |

The corpus groups are compared with MT Pentateuch. All verbal forms use the same effect summaries
(odds ratios, 66% and 95% quantile intervals, probability of direction); Bayes factors are not used. The
formulas, the model comparison (grouped k-fold cross-validation), the checks and the results are in each
folder's `REPORT.md`.

## Files

```
<verb_form>/
  analysis.R          the complete analysis of the verbal form
  REPORT.md           results and decisions
  figures/            tables (CSV); the figures are written here too, but are not in the repository
medians/              ch9_medians.R, ch9_medians_pey.R: posterior summaries of the final models for
                      Tables 9.39, 9.46, 9.54 and 9.73
tools/                run_verb_refit.R (fitting run of one verbal form), refit_verbs_newdata.R
                      (check of data release v1.2.0)
```

Every `analysis.R` has the same sections: 0 setup, 1 data import and preparation, 2 exploratory analysis,
3 data modelling, 4 data visualisation, 5 model verification, and sometimes 6 appendix. The configuration
and helpers are in `../shared/`.

## Running

From the repository root, e.g. `Rscript analysis/ch09_verbs/ptca_qal/analysis.R`. The model fits are read
from `analysis_verbs` in the model folder (see `../README.md`). With `ALLOW_FIT <- FALSE` (the default) the
script only loads stored fits.

## Data

- `ptcp_qal` was refitted completely on data release v1.2.0 (model files `ptcp_d3_*`).
- `ptca_qal` and `hiphil_triliteral` were fitted on the data of 19 October 2026. Release v1.2.0 changed
  `has_suffix` of 24 and 8 DSS forms; M7 was refitted on v1.2.0 as a check (`tools/refit_verbs_newdata.R`):
  no coefficient changed credibility, and the stored models were kept.
- The infinitive datasets did not change in v1.2.0, and the final pe-yod model has no suffix term, so their
  model data are the same.

The descriptive tables in `figures/` are computed from the v1.2.0 data.
