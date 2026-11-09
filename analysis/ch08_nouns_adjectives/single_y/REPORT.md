# Monosyllabic stems, optional yod (§8.3.3) — analysis report

*Script: `single_y/analysis.R`. Figures and tables: `single_y/figures/`.
Model set approved by the author on 2026-10-19; fits and k-folds 2026-10-20;
prior-sensitivity fits 2026-10-20. Final model **M0** (author, 2026-10-20).*

Intervals: median with 95% quantile interval (66% in the figures), logit
scale unless an odds ratio (OR) is given; pd = probability of direction;
credible = pd ≥ 0.975. Reference levels: MT Pentateuch, no suffix, no prefix.

## Summary

- Of the 1,197 forms, 576 (48%) are full. The corpus groups differ in their
  observed shares (MT Pentateuch 30%, MT other books 57%, QSP 53%), but these
  differences come from the mix of lexemes, not from the corpora.
- The **lexeme** decides the spelling: GR/, XMH/, NR/, NDH/ and MT/ are almost
  always defective, CJR/, QJR/, RJB/, >JPH/, XJQ/ and SJR/ almost always full.
  The SD between lexemes within books is 9.2 on the logit scale, against 0.48
  between books.
- **No effect is credible** in any model or robustness fit: not corpus or
  corpus group, not suffix or prefix, not their interactions.
- **The k-fold gives no reason to add effects.** M2 (corpus group) is as good
  as M0 (−0.5, SE 2.0); every larger model is worse (−1.5 to −5.1).
- Final model **M0** (intercept only), as in the book. The book's conclusion
  stands; the argument changes from Bayes factors to "no credible effect" and
  the k-fold.

## Descriptive results

`table_singley_groups.csv`, `_groups_all`, `_suffix`, `_prefix`,
`_qsp_isaiah`, `_lexemes`, `_book_lexemes`, `_book_parallels`,
`_parallel_passages`, `_parallel_counts`:

| Corpus group | n | full | without / with suffix | without / with prefix |
|---|---|---|---|---|
| MT Pentateuch | 188 | 57 (30%) | 19/81 / 38/107 | 31/91 / 26/97 |
| MT Former Prophets | 91 | 64 (70%) | 34/43 / 30/48 | 29/45 / 35/46 |
| MT LBH | 64 | 34 (53%) | 22/23 / 12/41 | 13/24 / 21/40 |
| MT other books | 468 | 266 (57%) | 135/169 / 131/299 | 146/280 / 120/188 |
| SP | 196 | 64 (33%) | 22/84 / 42/112 | 34/96 / 30/100 |
| Non-QSP | 96 | 41 (43%) | 19/43 / 22/53 | 26/50 / 15/46 |
| QSP | 94 | 50 (53%) | 26/40 / 24/54 | 31/59 / 19/35 |

- **Data.** 1,197 forms of 37 lexemes, the same counts as the book and the
  stored old fit. 56 of the 94 QSP forms are from 1QIsaa (33 full).
- **Lexemes.** GR/ (204 forms, 2 full) and XMH/ (159, 1 full) are 30% of the
  data. They are frequent in the MT Pentateuch and SP, which is why these two
  groups look most defective. The lexeme facts of §8.3.3.4 agree with the data
  (Tables 8.21–8.23, CJR/, XJL==/), with two exceptions (see the comparison
  with the book).
- **Suffix.** In several groups suffixed forms are less often full (MT LBH 96%
  without vs 29% with a suffix, MT other books 80% vs 44%). This is again the
  lexeme mix: all 159 XMH/ forms count as suffixed (`has_suffix = 1`, which
  includes the nominal ending) and 158 are defective; in MT LBH, 14 of the 41
  suffixed forms are XMH/ and 7 NR/. Within lexemes the suffix has no effect
  (M3 −0.18, pd 0.61).
- **Parallel passages** (scroll vs MT form):

  | Corpus | both defective | both full | MT fuller | scroll fuller |
  |---|---|---|---|---|
  | SP | 119 | 53 | 3 | 6 |
  | Non-QSP | 49 | 29 | 3 | 5 |
  | QSP | 36 | 43 | 6 | 7 |

  Where the scrolls and the MT have the same word, they nearly always spell
  it in the same way (95% in SP, 91% in non-QSP, 85% in QSP), and neither side
  is fuller.

## Method

- Bernoulli (logit) models in brms with nested random intercepts
  `(1 | scr_book2/lex)`.
- `corpus_group`: MT Pentateuch (reference), MT Former Prophets, MT LBH, MT
  other books, SP, non-QSP, QSP.
- Priors: normal(0, 2.5) on the intercept and coefficients, exponential(1)
  on the SDs. The prior predictive check (`check_singley_prior_predictive`)
  covers the whole range.
- Sampler: 4 chains, warmup 1000 / 3000 iterations (8000 draws).
- Grouped 5-fold k-fold: every scroll-book is left out as a whole. No Bayes
  factors.
- Final model chosen by the credible-effects rules (`../CLAUDE.md`).

## Model comparison

`table_singley_kfold.csv`. All formulas include `(1 | scr_book2/lex)`.

| Model | Fixed part | elpd diff | SE |
|---|---|---|---|
| **M0** | null (the book's model) | 0 | – |
| M2 | corpus_group | −0.5 | 2.0 |
| M3 | M2 + has_suffix + has_prefix | −1.5 | 2.2 |
| M5 | M3 + corpus_group × prefix | −3.3 | 2.7 |
| M4 | M3 + corpus_group × suffix | −3.6 | 2.5 |
| M1 | corpus (MT / SP / non-QSP / QSP) | −4.4 | 1.6 |
| M6 | M3 + corpus_group × suffix + corpus_group × prefix | −5.1 | 2.8 |

- All fits converged: max Rhat ≤ 1.005, min bulk ESS 1576, no divergent
  transitions.
- M0, M2 and M3 are within 1 SE of each other; the interaction models and M1
  are worse by 1.2 to 2.8 SE.
- Unlike in first_y, the k-fold does not clearly reject the corpus groups,
  but they add nothing to the prediction either.

## Final model M0

`has_vowel_letter ~ 1 + (1 | scr_book2/lex)`

Tables: `table_singley_fixed_effects.csv`, `table_singley_predicted.csv`,
`table_singley_book_model.csv`, `table_singley_random_book_lexeme.csv`.

| Parameter | Estimate [95%] |
|---|---|
| Intercept | 0.81 [−0.25, 1.95] |
| sd(scr_book2) | 0.48 [0.02, 1.53] |
| sd(scr_book2:lex) | 9.18 [6.74, 12.35] |

- **Predicted probability of full spelling** for a typical book and lexeme
  (`re_formula = NA`): 69% [44, 88]. Because the lexemes differ so much, this
  "typical lexeme" stands for few real lexemes: most are either almost always
  full or almost always defective.
- **Why this model (rules 1–3).** No effect is credible in M1–M6 or in the
  robustness fits (see below). M2 predicts as well as M0 but has no credible
  effect (rule 1), so M0 is the final model.
- No drop-one comparison: M0 has no fixed effects.

## Effects not in the final model

`fig_singley_effects_not_in_final_model`,
`table_singley_effects_not_in_final_model.csv` (corpus group from M2, common
affix effect from M3, per-group affix effects from M6; logit [95%], pd):

| Effect | Estimate | pd |
|---|---|---|
| Non-QSP vs MT Pentateuch (M2) | −1.57 [−4.45, 1.17] | 0.87 |
| MT other books vs MT Pentateuch (M2) | 0.74 [−1.68, 3.33] | 0.72 |
| QSP vs MT Pentateuch (M2) | 0.58 [−2.42, 3.61] | 0.65 |
| MT Former Prophets vs MT Pentateuch (M2) | 0.55 [−2.88, 3.78] | 0.62 |
| MT LBH vs MT Pentateuch (M2) | −0.44 [−4.16, 3.28] | 0.59 |
| SP vs MT Pentateuch (M2) | 0.22 [−2.92, 3.37] | 0.55 |
| Suffix, all groups (M3) | −0.18 [−1.41, 1.09] | 0.61 |
| Prefix, all groups (M3) | −0.09 [−1.02, 0.85] | 0.57 |

- The largest per-group affix effect in M6 is the prefix in non-QSP (−2.33,
  pd 0.90; 15 of 46 prefixed forms full against 26 of 50 without).
- The difference between the MT Pentateuch (30% full) and the MT other books
  (57%) is +0.74 within lexemes (pd 0.72). The observed gap comes largely
  from GR/ and XMH/ (76 of the 188 Pentateuch forms, all defective); without
  them it is 51% vs 75%, and the rest is the mix of the other lexemes.

## Robustness

`fig_singley_robustness`, `table_singley_robustness.csv`: M6 on all data,
without GR/ and XMH/ (834 forms) and without 1QIsaa (1,141 forms).

- No total effect is credible in any of the three. The largest values:

  | Effect | M6 | no GR/ XMH/ | no 1QIsaa |
  |---|---|---|---|
  | Prefix in non-QSP | −2.33 .90 | | |
  | Suffix in SP | −1.19 .76 | −2.93 .96 | |
  | Suffix in non-QSP | 0.16 .54 | −2.81 .94 | |

  (Empty cells: pd < 0.90.)
- Without GR/ and XMH/ the SP and non-QSP suffix effects grow, but they stay
  below pd 0.975 and are not supported by the k-fold.
- **Prior sensitivity** (`table_singley_prior_sensitivity_intercept.csv`):
  the intercept of M0 is 0.73 [−0.30, 1.80] with sd 1.5, 0.80 [−0.25, 1.95]
  with sd 2.5 and 0.83 [−0.28, 2.04] with sd 4; sd(scr_book2:lex) 9.13, 9.18
  and 9.19. The prior does not matter.

## Model checks

- **Convergence.** M0: max Rhat 1.004, min bulk ESS/draws 0.197, no divergent
  transitions (`check_singley_trace`, `_dens`). M0 with sd 1.5: Rhat 1.003,
  bulk ESS 1545; with sd 4: Rhat 1.004, bulk ESS 1786; no divergences.
- **Posterior predictive checks** (`check_singley_ppcheck_bars`, `_mean`):
  fine.
- **Groups** (`check_singley_ppc_groups`): the observed share lies inside the
  95% predictive interval in all 14 corpus group × suffix cells, including the
  large differences (MT LBH 96% without vs 29% with a suffix, predicted 94%
  and 30%).
- **Lexemes** (`check_singley_ppc_lexemes`): all inside the 95% interval. The
  almost-always-defective lexemes are predicted slightly too full (GR/ 1.0%
  observed, 3.3% [1.0, 6.4] predicted): the random intercepts are shrunk.
- **Bayes R2** 0.88 [0.86, 0.90], nearly all from the lexemes.
- **LOO** (for completeness; the k-fold is used for comparison): elpd −237.5
  (SE 15.1), 252 observations (21%) with Pareto k > 0.7, expected with many
  small book × lexeme groups.
- **In-sample classification**: accuracy 0.98, sensitivity 0.99, specificity
  0.97.

## Comparison with the book (§8.3.3, manuscript 2026-09-10)

- **Table 8.24 (intercept-only model).** The book's model is M0. The refit
  gives intercept 0.81 [−0.25, 1.95] (book 1.03 [−0.30, 2.53]), sd(book) 0.48
  (0.74) and sd(lex:book) 9.18 (11.31). Same data (1,197 forms); the
  differences come from the priors. The conclusion does not change.
- **Model choice.** The book chose the intercept-only model by Bayes factor.
  Here no effect is credible and the k-fold does not prefer a larger model.
  The text can say that the corpora do not differ once the lexeme is taken
  into account, and that the observed differences between groups (e.g. MT
  Pentateuch 30% vs MT other books 57%) reflect which lexemes occur where.
- **GR/.** The book says it is consistently defective in the MT. The data
  have one full MT form, הגירים at 2 Chr 2:16 (BHSA הַגֵּירִים; checked 2026-11-03), besides 8Q3 Deut
  5:14.
- **NDH/.** 54 forms in the data, 53 in the book. The only full form (MT Lam
  1:8) agrees.

## Points for the author

1. **Final model M0** (agreed 2026-10-20).
2. **The suffix pattern in the observed shares** (e.g. MT LBH 96% vs 29%) is
   a lexeme effect (XMH/, NR/). If the book shows Fig. 8.21 (suffix), the caption
   or text should say so.
3. **GR/ and NDH/:** correct the book (2 Chr 2:16; 54 forms).
