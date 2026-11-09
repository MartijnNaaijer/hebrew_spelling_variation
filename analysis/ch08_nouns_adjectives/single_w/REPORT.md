# Monosyllabic stem, optional waw (§8.3.2) — analysis report

*Script: `single_w/analysis.R`. Figures and tables: `single_w/figures/`.
Fitting run approved by the author on 2026-10-22; fits and grouped k-folds
2026-10-23/25; k-fold over forms 2026-10-28; prior-sensitivity fits
2026-10-28. Final model **M6** (`corpus_group * has_suffix + corpus_group *
has_prefix`; author, 2026-10-28, option (a) of `../KFOLD_ISSUE.md`).*

Intervals: median with 95% quantile interval (66% in the figures), logit
scale unless an odds ratio (OR) is given; pd = probability of direction;
credible = pd ≥ 0.975. Reference levels: MT Pentateuch, no suffix, no prefix.

## Summary

- Of the 15,351 forms, 5,049 (33%) are full. QSP is mostly full (92%); the
  other groups lie between 22% and 36%. KL/ alone has 8,110 forms (53%), 94%
  of them defective.
- **QSP is the one large corpus effect** (logit +7.63 [5.39, 9.88]). Non-QSP
  is just credibly more defective than the MT Pentateuch (−1.86, pd 0.977),
  but not robust: without KL/ it changes sign, and with prior sd 4 it is not
  credible.
- **The suffix is the strongest affix effect.** It lowers fullness in every
  group except QSP: MT Pentateuch −4.72 [−5.60, −3.94], SP −4.58, MT Former
  Prophets −3.80, MT LBH −3.34, non-QSP −2.59, MT other books −2.53; QSP
  −1.05 (pd 0.96). The effect is weaker in MT other books, non-QSP and QSP
  (credible interactions).
- **The prefix lowers fullness a little in the MT** (Pentateuch −1.13, MT
  other books −0.66); not in SP, non-QSP and QSP (QSP × prefix credible).
- **The lexeme decides most of the rest** (SD between lexemes within books
  10.0, between books 0.44): KL/, <LH/, XQ/ and RB=/ almost always
  defective, QWL/, <WD/, VWB/, TWRH/, XWY/ and <WR=/ almost always full.
- **Model choice.** The grouped k-fold prefers M2 by about 880 elpd, but it
  cannot use the nested lexeme effects (`../KFOLD_ISSUE.md`). The k-fold over
  forms prefers M6 (M3 −8.7, SE 7.4; M2 −182.6, SE 20.7).
- Against the book: the book's model (has_suffix × law_phase3 + has_prefix ×
  law_phase3) gives the same pattern with the new data. QSP × prefix and
  non-QSP × suffix rest on KL/.

## Descriptive results

`table_singlew_groups.csv`, `_groups_all`, `_suffix`, `_prefix`,
`_qsp_isaiah`, `_lexemes`, `_book_lexemes`, `_book_parallels`,
`_parallel_passages`, `_parallel_counts`; figures with and without KL/
(Figs. 8.14, 8.16):

| Corpus group | n | full | without / with suffix | without / with prefix |
|---|---|---|---|---|
| MT Pentateuch | 2805 | 615 (22%) | 459/2114 (22%) / 156/691 (23%) | 324/1567 (21%) / 291/1238 (24%) |
| MT Former Prophets | 1999 | 515 (26%) | 317/1588 (20%) / 198/411 (48%) | 302/1085 (28%) / 213/914 (23%) |
| MT LBH | 1274 | 334 (26%) | 148/933 (16%) / 186/341 (55%) | 146/550 (27%) / 188/724 (26%) |
| MT other books | 4237 | 1530 (36%) | 968/3064 (32%) / 562/1173 (48%) | 1001/2716 (37%) / 529/1521 (35%) |
| SP | 2904 | 768 (26%) | 488/2193 (22%) / 280/711 (39%) | 396/1636 (24%) / 372/1268 (29%) |
| Non-QSP | 1161 | 398 (34%) | 275/839 (33%) / 123/322 (38%) | 249/703 (35%) / 149/458 (33%) |
| QSP | 971 | 889 (92%) | 626/667 (94%) / 263/304 (87%) | 576/624 (92%) / 313/347 (90%) |

- **Data.** 15,351 forms of 106 lexemes (book text and stored old fit 15,334
  / 106).
- **The raw shares mislead.** Suffixed forms are fuller than unsuffixed ones
  in every group except QSP, yet within book × lexeme the suffix lowers
  fullness strongly. The raw difference comes from the lexeme mix (KL/,
  almost always defective, has 53% of the forms); not checked lexeme by
  lexeme here; see the figures without KL/.
- **1QIsaa** (`table_singlew_qsp_isaiah.csv`): 1QIsaa I 224/270 (83%),
  1QIsaa II 313/326 (96%), other QSP scrolls 352/375 (94%), MT Isaiah
  223/605 (37%).
- **Lexemes.** KL/ (MT, SP, non-QSP, QSP and the per-scroll counts), Table
  8.16 (QWL/), <LH/ (Table 8.17), <WR=/ and XWMH/ (Tables 8.18-8.19) agree
  with the data; XQ/ differs by one parallel (see the comparison with the
  book).
- **Parallel passages** (scroll vs MT form):

  | Corpus | both defective | both full | MT fuller | scroll fuller |
  |---|---|---|---|---|
  | SP | 2003 | 585 | 16 | 143 |
  | Non-QSP | 717 | 279 | 27 | 101 |
  | QSP | 70 | 310 | 6 | 526 |

  All three corpora are more often fuller than the MT than the other way
  round; QSP strongly (526 vs 6), SP (143 vs 16) and non-QSP (101 vs 27)
  moderately.

## Method

- Bernoulli (logit) models in brms with nested random intercepts
  `(1 | scr_book2/lex)`.
- `corpus_group`: MT Pentateuch (reference), MT Former Prophets, MT LBH, MT
  other books, SP, non-QSP, QSP. The book's model nB uses `law_phase3`
  (non-QSP split by group of books).
- Priors: normal(0, 2.5) on the intercept and coefficients, exponential(1)
  on the SDs. The prior predictive check (`check_singlew_prior_predictive`)
  covers the whole range.
- Sampler: 4 chains, warmup 1000 / 3000 iterations (8000 draws); M6 with
  prior sd 4 warmup 2000 / 6000 (16000 draws; author, 2026-10-28), as in
  first_w.
- Grouped 5-fold k-fold: every scroll-book is left out as a whole. As a check
  (`../KFOLD_ISSUE.md`, option (c)), an ordinary 5-fold over forms,
  stratified by scroll-book × lexeme, for M2, M3 and M6. No Bayes factors.
- Final model chosen by the credible-effects rules (`../CLAUDE.md`) and the
  author's decision of 2026-10-28.

## Model comparison

### Grouped k-fold (`table_singlew_kfold.csv`)

All formulas include `(1 | scr_book2/lex)`.

| Model | Fixed part | elpd diff | SE |
|---|---|---|---|
| M2 | corpus_group | 0 | – |
| M1 | corpus (MT / SP / non-QSP / QSP) | −11.5 | 4.0 |
| M5 | M3 + corpus_group × prefix | −703.1 | 15.6 |
| M3 | corpus_group + has_suffix + has_prefix | −737.6 | 15.6 |
| M0 | null | −776.3 | 18.1 |
| nB | has_suffix × law_phase3 + has_prefix × law_phase3 (book) | −817.6 | 18.2 |
| **M6** | M3 + both interactions | −877.5 | 18.4 |
| M4 | M3 + corpus_group × suffix | −930.5 | 18.6 |

Every model with affix terms is worse than the null model M0. This is not a
sign that the affix effects are absent: with sd(scr_book2:lex) about 10, a
held-out scroll-book gets new book × lexeme effects, so the grouped k-fold
scores only population-level predictions and cannot use the lexeme. Almost
every held-out form loses about 0.05 elpd; no fold or lexeme stands out
(`../KFOLD_ISSUE.md`, "Why the k-fold behaves like this";
`run/checks/kfold_pointwise.R`).

### k-fold over forms (`table_singlew_kfold_forms.csv`)

| Model | elpd diff | SE |
|---|---|---|
| **M6** | 0 | – |
| M3 | −8.7 | 7.4 |
| M2 | −182.6 | 20.7 |

A held-out form keeps its known book × lexeme effect. The affix effects
clearly improve the prediction of new forms (M2 → M3 +173.9); the
interactions add little (M3 → M6 +8.7, 1.2 SE).

### Drop-one comparison for M6 (rule 4)

`table_singlew_kfold_drop_one.csv` (grouped k-fold):

| Effect dropped | Model | elpd diff | SE |
|---|---|---|---|
| corpus_group × suffix | M5 | +174.4 | 6.4 |
| corpus_group × prefix | M4 | −53.0 | 3.1 |

In the grouped k-fold the model without the suffix interaction is better,
the model without the prefix interaction worse. Both follow the pattern of
the grouped k-fold described above (more terms estimated within lexemes,
worse population-level prediction); the k-fold over forms has no M4 or M5.

## Final model M6

`has_vowel_letter ~ corpus_group * has_suffix + corpus_group * has_prefix +
(1 | scr_book2/lex)`

Figures and tables: `fig_singlew_effects` / `table_singlew_effects.csv`,
`table_singlew_predicted.csv`, `table_singlew_fixed_effects.csv`.

| Parameter | Estimate [95%] | pd |
|---|---|---|
| Intercept | 1.58 [0.15, 3.02] | 0.984 |
| Non-QSP | −1.86 [−3.66, −0.04] | 0.977 |
| QSP | 7.64 [5.39, 9.88] | 1 |
| Suffix (MT Pentateuch) | −4.74 [−5.60, −3.94] | 1 |
| Prefix (MT Pentateuch) | −1.13 [−1.80, −0.47] | 1 |
| MT other books × suffix | 2.20 [1.13, 3.28] | 1 |
| Non-QSP × suffix | 2.14 [0.52, 3.71] | 0.99 |
| QSP × suffix | 3.69 [2.33, 5.10] | 1 |
| QSP × prefix | 1.25 [0.17, 2.39] | 0.99 |
| sd(scr_book2) | 0.44 [0.02, 1.34] | |
| sd(scr_book2:lex) | 9.98 [8.78, 11.29] | |

The other corpus groups and interactions are not credible (SP × prefix 1.06
[−0.13, 2.28], non-QSP × prefix 1.08 [−0.04, 2.23]).

**Total effects per corpus group** (main effect + interaction; logit, pd;
credible in bold):

| Effect | MT Pent. | MT Former Pr. | MT LBH | MT other | SP | Non-QSP | QSP |
|---|---|---|---|---|---|---|---|
| Corpus (vs MT Pent.) | – | −0.28 .590 | 0.32 .602 | −0.31 .636 | 1.05 .815 | **−1.86 .977** | **7.63 1** |
| Suffix | **−4.72 1** | **−3.80 1** | **−3.34 1** | **−2.53 1** | **−4.58 1** | **−2.59 1** | −1.05 .959 |
| Prefix | **−1.13 1** | −0.82 .961 | −0.24 .675 | **−0.66 .995** | −0.07 .559 | −0.04 .534 | 0.12 .599 |

- **Predicted probability of full spelling** (typical book and lexeme,
  `re_formula = NA`): MT Pentateuch without affix 83% [54, 95], with a suffix
  4.1% [0.9, 15.9]; QSP above 99.8% in all cells. With an SD of 10 between
  lexemes these numbers describe a lexeme of average fullness only; the odds
  ratios are the better summary.
- **Why this model** (option (a), author 2026-10-28).
  - QSP, suffix, prefix and four interactions are credible (rule 1).
  - The grouped k-fold cannot judge effects within lexemes (rule 4; see
    above); the k-fold over forms prefers M6 to M3 (1.2 SE) and M2.
  - QSP × prefix, non-QSP × suffix and the non-QSP main effect rest on KL/
    (rule 3(i); next section).

## Robustness

`fig_singlew_robustness`, `table_singlew_robustness.csv`,
`table_singlew_1qisaa_split.csv`. Total effects (logit, pd):

| Effect | M6 | no KL/ | no 1QIsaa | prior sd 1.5 | prior sd 4 |
|---|---|---|---|---|---|
| Non-QSP | −1.86 .977 | **+2.39 .992** | −2.01 .982 | −1.80 .993 | −1.84 .951 |
| QSP | 7.63 1 | 5.08 1 | 9.00 1 | 6.01 1 | 8.58 1 |
| Suffix, MT Pent. | −4.72 1 | −4.85 1 | −4.83 1 | −4.23 1 | −5.01 1 |
| Suffix, MT Former Pr. | −3.80 1 | −3.70 1 | −3.88 1 | −3.80 1 | −3.82 1 |
| Suffix, MT LBH | −3.34 1 | −3.38 1 | −3.43 1 | −3.36 1 | −3.31 1 |
| Suffix, MT other | −2.53 1 | −2.70 1 | −2.57 1 | −2.56 1 | −2.54 1 |
| Suffix, SP | −4.58 1 | −4.53 1 | −4.68 1 | −4.37 1 | −4.69 1 |
| Suffix, non-QSP | −2.59 1 | −5.94 1 | −2.65 1 | −2.77 1 | −2.47 1 |
| Suffix, QSP | −1.05 .959 | −0.12 .549 | −1.81 .932 | −1.07 .971 | −1.06 .961 |
| Prefix, MT Pent. | −1.13 1 | −1.16 1 | −1.15 1 | −0.96 1 | −1.22 1 |
| Prefix, MT Former Pr. | −0.82 .961 | −0.88 .971 | −0.82 .962 | −0.83 .975 | −0.79 .955 |
| Prefix, MT other | −0.66 .995 | −0.68 .998 | −0.66 .996 | −0.66 .997 | −0.66 .995 |
| Prefix, QSP | 0.12 .599 | −0.11 .561 | 0.99 .835 | 0.17 .650 | 0.10 .587 |

- **QSP** and the **suffix in all six non-QSP groups** are credible in every
  variant; the **prefix** in the MT Pentateuch and MT other books too.
- **Without KL/** (7,241 forms left; `../KFOLD_ISSUE.md`): the non-QSP main
  effect changes sign (+2.39), the suffix in non-QSP becomes much stronger
  (−5.94; non-QSP × suffix no longer credible) and QSP × prefix is no longer
  credible. These three rest on KL/ (rule 3(i)): KL/ is defective in 94% of
  the forms but full in many QSP forms (410 of 433) and in a part of the
  non-QSP forms (69 of 614).
- **Non-QSP main effect** (−1.86) is credible only just (pd 0.977), not with
  prior sd 4 (0.951), and has the opposite sign without KL/. Not robust.
- **1QIsaa split** (other QSP, 1QIsaa I, 1QIsaa II as groups): against the MT
  Pentateuch, the other QSP scrolls +8.33 [5.74, 11.13], 1QIsaa II +4.82
  [1.33, 8.24], 1QIsaa I +2.30 [−0.71, 5.27] (pd 0.93, not credible).
  1QIsaa I is less full than the other QSP texts (83% vs 94-96% observed).
  No affix effect is credible in the three groups.
- **Prior sensitivity**: the intercept is 1.82, 1.58 and 1.41 with sd 1.5,
  2.5 and 4; QSP 6.01, 7.63 and 8.58 (the QSP forms are nearly all full, so
  the prior limits this effect). The affix effects hardly change.

## Model checks

- **Convergence.** M6 (1000 / 3000): max Rhat 1.007, no divergent
  transitions, 1 transition at the maximum treedepth (`check_singlew_trace`,
  `_dens`). The lowest bulk ESS is for sd(scr_book2): 474 (ratio 0.059).
  Prior sd 1.5: max Rhat 1.007, ESS of sd(scr_book2) 428. Prior sd 4 (2000
  / 6000): max Rhat 1.010, ESS 815, 7 transitions at the maximum treedepth
  (harmless).
- **Posterior predictive checks** (`check_singlew_ppcheck_bars`, `_mean`):
  fine.
- **Groups** (`check_singlew_ppc_groups`): the observed share lies inside the
  95% predictive interval in all 14 corpus group × suffix cells.
- **Lexemes** (`check_singlew_ppc_lexemes`): all eight main lexemes (KL/,
  QWL/, <WD/, VWB/, <LH/, TWRH/, DWR/, XWY/) and the other lexemes lie inside
  the 95% interval; TWRH/ (99.4% observed) at its upper limit.
- **Bayes R2** 0.92 [0.91, 0.92].
- **LOO** (for completeness; the k-fold is used for comparison): elpd −1468.7
  (SE 48.8), 1,024 observations (6.7%) with Pareto k > 0.7, expected with
  many small book × lexeme groups.
- **In-sample classification**: accuracy 0.98, sensitivity 0.98, specificity
  0.99.

## Comparison with the book (§8.3.2, manuscript 2026-09-10)

`table_singlew_book_model.csv`: the book's model nB refitted with the new
priors and data, against the stored old fit (15,334 forms).

| Parameter | nB (new) | old fit |
|---|---|---|
| Intercept | 1.45 [0.07, 2.80] | 1.22 [−0.68, 3.04] |
| Suffix (MT Pentateuch) | −4.69 [−5.56, −3.91] | −5.14 [−6.16, −4.21] |
| Prefix (MT Pentateuch) | −1.08 [−1.74, −0.42] | −1.23 [−1.98, −0.50] |
| Non-QSP Pentateuch | −2.60 [−4.86, −0.32] | −3.23 [−6.22, −0.36] |
| QSP | 7.80 [5.47, 10.19] | 9.61 [6.75, 12.67] |
| MT other × suffix | 2.14 [1.05, 3.23] | 2.58 [1.36, 3.83] |
| Non-QSP Pentateuch × suffix | 3.92 [1.55, 6.34] | 5.33 [2.48, 8.27] |
| QSP × suffix | 3.66 [2.31, 5.07] | 4.12 [2.63, 5.68] |
| QSP × prefix | 1.21 [0.09, 2.34] | 1.33 [0.16, 2.55] |
| sd(scr_book2) | 0.42 | 0.68 |
| sd(scr_book2:lex) | 10.06 | 11.01 |

- **The book's model.** The new fit gives the same credible terms as the old
  one; the estimates are somewhat smaller (narrower priors: sd 2.5). The
  conclusions of §8.3.2 stand.
- **M6 and nB** agree: M6 replaces the non-QSP split by book group with one
  non-QSP group; the same terms are credible. The non-QSP effects (main and
  × suffix) and QSP × prefix rest on KL/, which the text should say.
- **Model choice.** The book chose nB by Bayes factor. The grouped k-fold
  prefers M2 (nB −817.6, M6 −877.5), but it cannot use the lexeme effects;
  the k-fold over forms prefers M6.
- **Counts.** 15,351 forms of 106 lexemes (book 15,334 / 106).
- **XQ/:** 19 parallels with the non-QSP scrolls in the data (3 full in the
  scroll), 20 in the book.

## Points for the author

1. **Final model M6** (agreed 2026-10-28). Wording: QSP × prefix, non-QSP ×
   suffix and the non-QSP main effect rest on KL/ (rule 3(i)); the non-QSP
   main effect is not robust (sign change without KL/, pd 0.951 with prior
   sd 4).
2. **The grouped k-fold** puts every affix model below the null model; the
   report explains this as a limit of the grouped k-fold with nested lexeme
   effects. The book text should not quote the grouped k-fold for single_w
   without that explanation.
3. **ESS of sd(scr_book2)** is 474 in M6 and 428 with prior sd 1.5 (> 400,
   ratio below 0.1); prior sd 4 (2000 / 6000) has max Rhat 1.010, ESS 815.
   A longer refit of M6 is optional.
4. **Book corrections:** counts (15,351 forms), XQ/ parallels (19 vs 20),
   and the model-choice text of §8.3.2 (Bayes factors).
