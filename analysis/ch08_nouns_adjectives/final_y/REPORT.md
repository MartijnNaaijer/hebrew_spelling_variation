# Final syllable, optional yod (§8.2.3) — analysis report

*Script: `final_y/analysis.R`. Figures and tables: `final_y/figures/`. Model
set approved by the author on 2026-10-20; fits and k-folds 2026-10-20/21;
prior-sensitivity fits 2026-10-21. Final model **nB** (`has_suffix`, the
book's model; author, 2026-10-21).*

Intervals: median with 95% quantile interval (66% in the figures), logit
scale unless an odds ratio (OR) is given; pd = probability of direction;
credible = pd ≥ 0.975. Reference levels: MT Pentateuch, no suffix, no prefix.

## Summary

- Of the 4,760 forms, 3,127 (66%) are full: 78% without a suffix and 52% with
  one.
- **The suffix is the one strong effect.** A suffix lowers fullness from 99%
  to 77% for a typical book and lexeme (logit −3.75 [−4.41, −3.13], OR about
  1/42). Without it, the k-fold loses 158 elpd (SE 12.2). The effect holds in
  every corpus group, without the main lexemes, without 1QIsaa and with every
  prior.
- **No corpus group is credibly different from the MT Pentateuch** (largest
  SP +1.97, pd 0.968 in M3). The prefix has no effect (−0.14, pd 0.72).
- **The lexeme decides most of the rest.** NBJ>/, YDJQ/, NFJ>/, TMJD/ and
  TMJM/ are almost always full, ZQN/, KS>/, JCR/, JLD/, QRC/ and KTP/ almost
  always defective (SD between lexemes within books 7.5, between books 1.2).
- **Non-QSP × suffix** is credible (in non-QSP the suffix lowers fullness
  more: interaction −3.14, pd 0.995) and robust, but the k-fold prefers the
  model without it (M4 vs M3 −6.8, SE 3.5). The author kept the book's model
  (2026-10-21); the effect is reported below as credible but not in the final
  model.
- The book's model and conclusion stand. The estimates hardly change against
  Table 8.15, although the new data have 12 more lexemes.

## Descriptive results

`table_finaly_groups.csv`, `_groups_all`, `_suffix`, `_prefix`,
`_qsp_isaiah`, `_lexemes`, `_book_lexemes`, `_book_parallels`,
`_parallel_passages`, `_parallel_counts`:

| Corpus group | n | full | without suffix | with suffix | without / with prefix |
|---|---|---|---|---|---|
| MT Pentateuch | 840 | 555 (66%) | 355/440 (81%) | 200/400 (50%) | 268/397 / 287/443 |
| MT Former Prophets | 541 | 270 (50%) | 165/279 (59%) | 105/262 (40%) | 102/236 / 168/305 |
| MT LBH | 373 | 246 (66%) | 166/220 (75%) | 80/153 (52%) | 84/124 / 162/249 |
| MT other books | 1546 | 1072 (69%) | 647/788 (82%) | 425/758 (56%) | 646/923 / 426/623 |
| SP | 856 | 606 (71%) | 371/442 (84%) | 235/414 (57%) | 271/387 / 335/469 |
| Non-QSP | 305 | 184 (60%) | 114/143 (80%) | 70/162 (43%) | 101/177 / 83/128 |
| QSP | 299 | 194 (65%) | 102/138 (74%) | 92/161 (57%) | 117/178 / 77/121 |

- **Data.** 4,760 forms of 136 lexemes (book text 4,695 / 134; stored old fit
  3,187 / 123, which lacks 12 lexemes: ZQN/, TMJD/, KS>/, TMJM/, JCR/, JLD/,
  F<JR/, QRC/, KTP/, C>RJT/, >XRJT/, >MRH/).
- **Former Prophets** (50% full) look more defective, but within lexemes they
  do not differ from the Pentateuch (M2 −0.53, pd 0.68): the lexeme mix.
- **1QIsaa** (`table_finaly_qsp_isaiah.csv`): 1QIsaa I 69/113 (61%), 1QIsaa
  II 67/83 (81%), MT Isaiah 141/208 (68%), other QSP scrolls 58/103 (56%).
- **Lexemes.** The book's lexeme facts of §8.2.3.4 agree with the data
  (NBJ>/, YDJQ/ Tables 8.12–8.13, NFJ>/, BRJX/, ZQN/), except for CLJCJ/ and
  GBJ</ (see the comparison with the book).
- **Parallel passages** (scroll vs MT form):

  | Corpus | both defective | both full | MT fuller | scroll fuller |
  |---|---|---|---|---|
  | SP | 208 | 513 | 32 | 68 |
  | Non-QSP | 99 | 171 | 20 | 10 |
  | QSP | 88 | 169 | 13 | 17 |

  *Recounted 2026-11-05: forms paired by their position in the raw text when the scroll and the MT have
  the same number of forms of the lexeme in the verse (`parallel_forms(occ = raw_occurrences(...))`).*

  SP is more often fuller than the MT than the other way round (68 vs 32),
  the non-QSP scrolls less often (10 vs 20). QSP does not differ from the MT.

## Method

- Bernoulli (logit) models in brms with nested random intercepts
  `(1 | scr_book2/lex)`.
- `corpus_group`: MT Pentateuch (reference), MT Former Prophets, MT LBH, MT
  other books, SP, non-QSP, QSP. The book's model nB has `has_suffix` only.
- Priors: normal(0, 2.5) on the intercept and coefficients, exponential(1)
  on the SDs. The prior predictive check (`check_finaly_prior_predictive`)
  covers the whole range.
- Sampler: 4 chains, warmup 1000 / 3000 iterations (8000 draws); nB and
  its two prior fits warmup 2000 / 6000 (16000 draws), for the ESS of
  sd(scr_book2).
- Grouped 5-fold k-fold: every scroll-book is left out as a whole. No Bayes
  factors.
- Final model chosen by the credible-effects rules (`../CLAUDE.md`) and the
  author's decision on non-QSP × suffix.

## Model comparison

`table_finaly_kfold.csv`. All formulas include `(1 | scr_book2/lex)`.

| Model | Fixed part | elpd diff | SE |
|---|---|---|---|
| M3 | corpus_group + has_suffix + has_prefix | 0 | – |
| **nB** | has_suffix (the book's model) | −6.0 | 6.1 |
| M4 | M3 + corpus_group × suffix | −6.8 | 3.5 |
| M5 | M3 + corpus_group × prefix | −13.1 | 2.4 |
| M6 | M3 + both interactions | −18.0 | 4.1 |
| M2 | corpus_group | −161.4 | 12.0 |
| M0 | null | −163.9 | 13.3 |
| M1 | corpus (MT / SP / non-QSP / QSP) | −173.9 | 12.3 |

- Convergence: no divergent transitions in any fit; max Rhat ≤ 1.008 except
  the comparison models M1 (1.011) and M2 (1.012), which were not refitted
  (author, 2026-10-21). The lowest bulk ESS is always for sd(scr_book2):
  552 or less in the comparison models, 678–761 in nB and its prior fits.
- The suffix carries nearly all the predictive information (M0 → nB about
  +158).
- M3 is ahead of nB by 6.0 (SE 6.1), about 1 SE, from corpus groups and
  prefix that are not credible.
- The interactions cost: M4 −6.8 (SE 3.5) and M5 −13.1 (SE 2.4) against M3.

### Drop-one comparison for nB (rule 4)

`table_finaly_kfold_drop_one.csv`: nB without the suffix is M0, −157.9
(SE 12.2).

## Final model nB

`has_vowel_letter ~ has_suffix + (1 | scr_book2/lex)`

Figures and tables: `fig_finaly_effects` / `table_finaly_effects.csv`,
`table_finaly_predicted.csv`, `table_finaly_fixed_effects.csv`.

| Parameter | Estimate [95%] |
|---|---|
| Intercept | 4.98 [4.17, 5.90] |
| Suffix | −3.75 [−4.41, −3.13] (OR 0.024) |
| sd(scr_book2) | 1.13 [0.11, 2.15] |
| sd(scr_book2:lex) | 7.52 [6.40, 8.82] |

- **Predicted probability of full spelling** (typical book and lexeme,
  `re_formula = NA`): without a suffix 99.3% [98.5, 99.7], with a suffix
  77.4% [63.5, 87.7].
- **Why this model.**
  - The suffix is credible and robust (rules 1, 3).
  - No corpus group is credible in M3 (rule 2: the factor is left out).
  - The prefix is not credible.
  - Non-QSP × suffix is credible and robust, but the k-fold prefers M3 to M4
    by 6.8 elpd (SE 3.5, 1.9 SE). The author chose the book's model
    (2026-10-21; option (a) in `../TODO.md` 5d). Because the k-fold does not
    clearly reject the interaction, the text should mention it (next
    section).

## Effects not in the final model

`fig_finaly_effects_not_in_final_model`,
`table_finaly_effects_not_in_final_model.csv` (corpus group from M2, prefix
from M3, per-group suffix and prefix effects from M6).

| Effect | Estimate [95%] | pd |
|---|---|---|
| SP vs MT Pentateuch (M2) | 1.92 [−0.17, 3.96] | 0.965 |
| MT LBH vs MT Pentateuch (M2) | 0.86 [−1.41, 3.02] | 0.77 |
| Non-QSP vs MT Pentateuch (M2) | −0.81 [−2.60, 0.92] | 0.83 |
| QSP vs MT Pentateuch (M2) | 0.52 [−1.61, 2.58] | 0.69 |
| MT other books vs MT Pentateuch (M2) | 0.41 [−1.23, 2.08] | 0.69 |
| MT Former Prophets vs MT Pentateuch (M2) | −0.53 [−2.75, 1.65] | 0.68 |
| Prefix, all groups (M3) | −0.14 [−0.59, 0.32] | 0.72 |
| Prefix in MT Pentateuch (M6) | −0.78 [−1.82, 0.27] | 0.93 |

**Suffix per corpus group** (M6 total effect; all credible):

| MT Pent. | MT Former Pr. | MT LBH | MT other | SP | Non-QSP | QSP |
|---|---|---|---|---|---|---|
| −3.56 | −4.79 | −3.57 | −3.87 | −3.49 | **−6.76** | −2.75 |

- **Non-QSP × suffix** (credible, not in the final model): the suffix lowers
  fullness more in the non-QSP scrolls than in the MT Pentateuch (M4
  interaction −3.14 [−5.65, −0.76], pd 0.995). Without NBJ>/ and ZQN/ −2.48
  (pd 0.979), without 1QIsaa −3.10 (pd 0.993).
  - Observed: non-QSP 80% full without and 43% with a suffix, a gap of 37
    points, against 17–31 points in the other groups (MT Pentateuch 81% vs
    50%).
  - The defective suffixed forms come from several lexemes (ZQN/ 14, >MRH/
    12, JCR/ 6, CLCJM/ 4, RB</ 4, …), so it is not a single-lexeme effect.
  - It does not improve the prediction of new books: M4 vs M3 −6.8 (SE 3.5).
    The non-QSP data are 305 forms in many small scroll-books, so when a
    scroll is left out, the group-specific term rests on few forms.
  - Suggested wording: the suffix effect is stronger in the non-QSP scrolls,
    but this does not generalise to new scrolls; the book's model is kept.
- The other interactions (MT Former Prophets × suffix −1.19, pd 0.88; QSP ×
  suffix +0.84, pd 0.76) are not credible.

## Robustness

`fig_finaly_robustness`, `table_finaly_robustness.csv`,
`table_finaly_1qisaa_split.csv`. Suffix effect (logit, pd):

| Variant | MT Pent. | MT Former Pr. | MT LBH | MT other | SP | Non-QSP | QSP |
|---|---|---|---|---|---|---|---|
| M6 | −3.56 1 | −4.79 1 | −3.57 1 | −3.87 1 | −3.49 1 | −6.76 1 | −2.75 .992 |
| no NBJ>/ ZQN/ | −3.46 1 | −5.56 1 | −3.01 .998 | −3.54 1 | −3.40 1 | −5.94 1 | −2.53 .989 |
| no 1QIsaa | −3.61 1 | −4.77 1 | −3.53 1 | −3.83 1 | −3.45 1 | −6.72 1 | −3.96 .989 |

- **The suffix** is credible in every group and variant.
- **1QIsaa split** (QSP without 1QIsaa, 1QIsaa I, 1QIsaa II as groups): the
  suffix is −3.98 (pd 0.989) in the other QSP scrolls, −2.80 (pd 0.974) in
  1QIsaa I and −2.04 (pd 0.87) in 1QIsaa II. No corpus difference: other QSP
  +0.35, 1QIsaa I −0.80, 1QIsaa II +1.04 (pd 0.58–0.72).
- **Prior sensitivity** (nB): the suffix is −3.61 [−4.26, −3.04] with sd
  1.5, −3.75 with sd 2.5 and −3.80 [−4.49, −3.17] with sd 4. The intercept
  is 4.78, 4.98 and 5.09.

## Model checks

- **Convergence.** nB (warmup 2000 / 6000 iterations): max Rhat 1.002, no
  divergent transitions (`check_finaly_trace`, `_dens`). Bulk ESS is 4119
  for the intercept and 9741 for the suffix. For sd(scr_book2) it is 761.
  The first fit (1000 / 3000) gave 321 there. The prior fits have Rhat 1.006
  and 1.008, ESS of sd(scr_book2) 727 and 678. The sd 4 fit has 2
  transitions at the maximum treedepth, which is harmless.
- **Posterior predictive checks** (`check_finaly_ppcheck_bars`, `_mean`):
  fine.
- **Groups** (`check_finaly_ppc_groups`): the observed share lies inside the
  95% predictive interval in all 14 corpus group × suffix cells. Non-QSP with
  a suffix: 43% observed, 45% [40, 51] predicted. The random intercepts of
  the book × lexeme groups absorb the non-QSP difference.
- **Lexemes** (`check_finaly_ppc_lexemes`): the two almost-always-defective
  lexemes ZQN/ (0.7% observed, 3.3% [1.1, 6.0] predicted) and KS>/ (0.6%,
  4.0% [1.3, 7.5]) lie **just below** the 95% interval. With 7.5 SD between
  lexemes, the random intercepts of lexemes with one full form in 160–270 are
  shrunk towards the mean. The other main lexemes are inside.
- **Bayes R2** 0.84 [0.83, 0.85].
- **LOO** (for completeness; the k-fold is used for comparison): elpd −1000.8
  (SE 33.1), 868 observations (18%) with Pareto k > 0.7, expected with many
  small book × lexeme groups.
- **In-sample classification**: accuracy 0.97, sensitivity 0.99, specificity
  0.94.

## Comparison with the book (§8.2.3, manuscript 2026-09-10)

- **Table 8.15 (nB, has_suffix).** The refit gives intercept 4.98 [4.17,
  5.90] (old fit 5.32 [4.49, 6.29]) and suffix −3.75 [−4.41, −3.13] (−3.66
  [−4.34, −3.04]). sd(book) 1.13 (1.13). sd(lex:book) is larger: 7.52
  (4.68), because the 12 lexemes missing from the old fit include seven that
  are almost always defective (ZQN/, KS>/, JCR/, JLD/, QRC/, KTP/, >MRH/). The
  conclusion does not change.
- **Model choice.** The book chose nB by Bayes factor. In the grouped k-fold
  nB is within 1 SE of the best model (M3), and the extra terms of M3 are not
  credible.
- **Non-QSP × suffix** is new: credible and robust, but not in the final
  model (see above). The text can mention it as a tendency that does not
  generalise.
- **Counts.** 4,760 forms of 136 lexemes (book 4,695 / 134).
- **CLJCJ/:** the book has "eight {'nine'?}" DSS parallels. The data have 9
  in the non-QSP scrolls (including 6Q1 at Gen 6:16), plus 2 in 1QIsaa (Isa
  19:24, 37:30, both full), which the text does not mention. CLJCJ/ has 122
  forms; the book has 113.
- **GBJ</ (Table 8.14), Exod 37:17:** the data have SP גבעיה against MT
  גביעיה; the book gives גביעיה for both and says the spelling never differs.
  The SP edition needs checking.

## Points for the author

1. **Final model nB** (agreed 2026-10-21). Check the wording on non-QSP ×
   suffix (credible, robust, no k-fold gain, not in the final model).
2. **ESS of sd(scr_book2) in nB: solved.** It was 321. After the refit with
   warmup 2000 / 6000 (approved 2026-10-21) it is 761, Rhat 1.002. The
   estimates hardly changed.
3. **ZQN/ and KS>/** lie just outside the posterior predictive interval
   (shrinkage of near-categorical lexemes); no consequence for the effects.
4. **Book corrections:** counts (4,760 / 136), CLJCJ/ parallels and form
   count, GBJ</ Exod 37:17 (check the SP edition).
