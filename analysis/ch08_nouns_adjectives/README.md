# analysis_nouns

The analysis of the spelling of nouns and adjectives (chapter 8), one folder
per model, harmonised with the verb analyses (`../../verbs/analysis_verbs`).
Started on 2026-10-19 from `../nouns_adjectives.R` (the newest version; the
`_cleaned` file is older). The old scripts stay as they are, for reference.

```
analysis_nouns/
  README.md
  CLAUDE.md            working rules (differences from the verbs)
  TODO.md              open questions
  KFOLD_ISSUE.md       open decision first_w / single_w (2026-10-26)
  run/                 runner for approved fitting runs, logs, checks
  config.R             model folder, corpus groups, the six datasets
  functions_nouns.R    shared data preparation (read_nouns, noun_dataset)
  <id>/
    analysis.R         the complete analysis of this dataset
    REPORT.md          results and decisions
    figures/           figures and tables
```

| id | Book § | Dataset | Book's final model (Bayes factors) |
|---|---|---|---|
| `final_w` | 8.2.2 | final syllable, optional ו | `has_suffix*law_phase3 + has_prefix*law_phase3` |
| `final_y` | 8.2.3 | final syllable, optional י | `has_suffix` |
| `single_w` | 8.3.2 | monosyllabic stem, optional ו | `has_suffix*law_phase3 + has_prefix*law_phase3` |
| `single_y` | 8.3.3 | monosyllabic stem, optional י | intercept only |
| `first_w` | 8.4.2 | first syllable, optional ו | `has_prefix*law_phase3` |
| `first_y` | 8.4.3 | first syllable, optional י | intercept only |
| `affix_types_mt` | 8.5 | final syllable ו and י, MT only | `nme*law_phase3 + prs*… + has_hloc*… + prefix*…` |

All with `(1 | scr_book2/lex)`.

## Counts (data of 2026-10-19)

| id | forms | lexemes | book (text) | stored book fit |
|---|---|---|---|---|
| `final_w` | 19,651 | 376 | 19,639 / 376 | 19,588 / 373 |
| `final_y` | 4,760 | 136 | 4,695 / 134 | 3,187 / 123 |
| `single_w` | 15,351 | 106 | 15,334 / 106 | 15,334 / 106 |
| `single_y` | 1,197 | 37 | 1,197 / 37 | 1,197 / 37 |
| `first_w` | 9,752 | 149 | 9,741 / 148 | 9,718 / 147 |
| `first_y` | 776 | 23 | 787 / "23 or 24" | 802 / 23 |

The differences come from the updates of the noun data in
`hebrew_spelling_variation` (2025-12 to 2026-10, among them SP 7.2.4) and from
the tie rule for the vowel letter of a lexeme (`TODO.md` section 1).

## Status

| id | Sections 0-2 | Models fitted | Reviewed |
|---|---|---|---|
| `final_w` | yes (2026-10-19) | all fits (2026-10-29/11-01) | **done**: final model M6 (2026-11-01); `final_w/REPORT.md` |
| `final_y` | yes (2026-10-19) | all fits (2026-10-20/21) | **done**: final model nB (2026-10-21); `final_y/REPORT.md` |
| `single_w` | yes (2026-10-19) | all fits (2026-10-23/28) | **done**: final model M6 (2026-10-28); `single_w/REPORT.md` |
| `single_y` | yes (2026-10-19) | all fits (2026-10-20) | **done**: final model M0 (2026-10-20); `single_y/REPORT.md` |
| `first_w` | yes (2026-10-19) | all fits (2026-10-21/28) | **done**: final model M6 (2026-10-28); `first_w/REPORT.md` |
| `first_y` | yes (2026-10-19) | all fits (2026-10-19/20) | **done**: final model M0 (2026-10-20); `first_y/REPORT.md` |
| `affix_types_mt` | yes (2026-10-19) | all fits (2026-11-01/03) | **done**: final models waw A2, yod A3 (2026-11-02); `affix_types_mt/REPORT.md` |

State on 2026-11-04: all seven analyses done; the data update v1.2.0 (11 DSS forms with a
changed `has_suffix`) was checked with M6 refits and the present models are kept (`TODO.md` §1).
All chapter 8 book corrections of `TODO.md` are in the manuscript. Open points for the author: verbs
`TODO.md` §25.

Order of work (author, 2026-10-19): the smaller datasets first: `first_y`,
`single_y`, `final_y`, `first_w`, `single_w`, `final_w`; then `affix_types_mt`.

Model fits go to `D:/brms_models_spelling/analysis_nouns` (empty at the start).
