# analysis_verbs

The complete analysis of the spelling of Hebrew verb forms, one folder per verb
form. It was started on 2026-10-08 from the `*_cleaned.R` scripts in the parent
folder. Those scripts and the originals stay as they are, for reference.

```
analysis_verbs/
  README.md
  CLAUDE.md             working rules for this folder
  TODO.md               open questions per verb form
  config.R              paths, book groups, factor levels (MODEL_FOLDER = new folder)
  functions.R           all helpers (../functions.R + ../functions_cleaned.R)
  <verb_form>/
    analysis.R          the complete analysis of this verb form
    REPORT.md           results and decisions (written when the verb form is finished)
    figures/            all figures and tables of this verb form
```

| Verb form | Dataset | Started from |
|---|---|---|
| `ptcp_qal` | `ptcp_qal.csv` | `script_ptcp_cleaned.R` |
| `ptca_qal` | `ptca_qal.csv` | `script_ptca_cleaned.R` |
| `infa_qal` | `infa_qal.csv` | `script_infa_cleaned.R` |
| `infc_qal_lamed_he` | `infc_qal_lamed_he.csv` | `infc_qal_lamed_he_cleaned.R` |
| `infc_qal_triliteral` | `infc_qal_triliteral.csv` | `trilit_infc_cleaned.R` |
| `hiphil_triliteral` | `hiphil_triliteral_with_hireq.csv` | `script_trilit_hif_cleaned.R` |
| `niph_hiph_pe_yod` | `niph_hiph_pe_yod.csv` | `script_ni_hi_pe_yod_cleaned.R` |

Every `analysis.R` has the same sections: 0 setup, 1 data import and
preparation, 2 exploratory analysis, 3 data modelling, 4 data visualisation,
5 model verification, and optionally 6 appendix.

## Outputs

- Figures and tables: `<verb_form>/figures/`.
- Model fits: `D:/brms_models_spelling/analysis_verbs` (`MODEL_FOLDER` in
  `config.R`). The folder starts empty, so the first full run of a script fits
  all of its models, which can take hours. The old fits in
  `D:/brms_models_spelling/models_rstanarm` are not used or changed.

## Status

| Verb form | Sections 0–2 run | Models fitted | Reviewed |
|---|---|---|---|
| `ptcp_qal` | yes (rebuilt 2026-10-09; rerun 2026-11-04) | refitted 2026-11-04 on the data of 2026-11-03 (`ptcp_d3_`; before `ptcp_d2_`, 2026-10-17/18) | final model M7, kept over S1x (author, 2026-10-18; confirmed 2026-11-04); `REPORT.md` updated 2026-11-04 |
| `ptca_qal` | yes (rebuilt 2026-10-16) | done 2026-10-17: final model M7, drop-one k-fold, prior sensitivity, sections 4-5, `REPORT.md` | exploratory figures to be checked; book section 9.2 checked (see `TODO.md` section 12) |
| `infa_qal` | yes | refitted 2026-10-18 with the harmonised design (`infa2_`) | final model M3 = corpus group + ע-ע (author, 2026-10-18); `REPORT.md` updated |
| `infc_qal_lamed_he` | yes (rebuilt 2026-10-09) | refitted 2026-10-18 (`infc_lh2_`, MT Pentateuch reference; prior fits of M4p) | final model M4p (author, 2026-10-12); `REPORT.md` updated |
| `infc_qal_triliteral` | yes | refitted 2026-10-18 (`infc2_`, MT Pentateuch reference) | final model M2; contrasts with the Pentateuch shrank, accepted with a caveat (author, 2026-10-18) |
| `hiphil_triliteral` | yes (rebuilt 2026-10-15) | all fits 2026-10-15/18 (model set, k-folds, robustness, drop-one and prior fits of M7) | final model M7 (author, 2026-10-18); `REPORT.md` written 2026-10-18; data of 2026-10-19 (one DSS lexeme corrected, no refit needed); exploratory figures to be checked |
| `niph_hiph_pe_yod` | yes | refitted 2026-10-17/18 (`pey2_`, MT Pentateuch reference; check models M1s, M1p) | final model M1, suffix left out (author, 2026-10-18); `REPORT.md` updated |

**Harmonisation (2026-10-17, `TODO.md` section 13):** all verb forms use the
same effect summaries (odds ratios, 66%/95% quantile intervals, pd; shared
helpers in `functions.R`), the same `REPORT.md` headings, no Bayes factors,
and report the corpus groups against the MT Pentateuch. Items 6-10 (refits
with MT Pentateuch as reference level, harmonised infa, warmup 1000 / iter
3000) were fitted on 2026-10-17/18, and the hiphil drop-one and prior fits
on 2026-10-18. All verb forms now have a final model and a `REPORT.md`.
