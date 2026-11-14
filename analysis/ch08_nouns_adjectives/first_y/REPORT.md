# First syllable, optional yod (§8.4.3) — analysis report

*Script: `first_y/analysis.R`. Figures and tables: `first_y/figures/`. Model
set approved by the author on 2026-10-19; fits and k-folds 2026-10-19;
prior-sensitivity fits and the check fit without KTNT/ 2026-10-20 (sd 4
refitted with 2000 / 6000 the same day). Final
model **M0** (author, 2026-10-20).*

Intervals: median with 95% quantile interval (66% in the figures), logit
scale unless an odds ratio (OR) is given; pd = probability of direction;
credible = pd ≥ 0.975. Reference levels: MT Pentateuch, no suffix, no prefix.

## Summary

- The optional yod in the first syllable is mostly **defective** everywhere:
  27% full overall, 21–29% in the MT groups, 23% in non-QSP, 10% in QSP and
  37% in SP.
- What decides the spelling is the **lexeme**, not the corpus: GBWR/, XLB=/,
  >TWN/ and <NQ/ are almost always defective, TJMN/, MJTR/ and TJKWN/
  almost always full (SD between lexemes within books 7.5 on the logit
  scale, against 1.0 between books).
- **The k-fold clearly prefers the intercept-only model M0** (the book's
  model). Every model with corpus, corpus group or affixes predicts new books
  worse (M1 −16.0, M2 −31.5, M3–M6 −32.5 to −35.1).
- **The only credible effect, SP fuller than the MT Pentateuch** (M2 +3.65,
  OR 38, pd 0.992), is a lexeme effect of **KTNT/** (rule 3(i)): SP writes
  כיתנות, the MT and the scrolls כתנות (SP vocalisation kittånǝt, §8.4.3.4).
  Without KTNT/ the SP effect is no longer credible (+2.65, pd 0.96).
- Suffix and prefix have no credible effect, in any group.
- The book's conclusion (no effect of corpus, suffix or prefix) stands. The
  argument changes from Bayes factors to the k-fold, and the text should name
  KTNT/ as the source of the SP difference.

## Descriptive results

`table_firsty_groups.csv`, `_groups_all`, `_suffix`, `_prefix`,
`_qsp_isaiah`, `_lexemes`, `_book_lexemes`, `_parallel_passages`,
`_parallel_counts`:

| Corpus group | n | full | without / with suffix | without / with prefix |
|---|---|---|---|---|
| MT Pentateuch | 159 | 37 (23%) | 11/78 / 26/81 | 22/78 / 15/81 |
| MT Former Prophets | 123 | 36 (29%) | 12/39 / 24/84 | 10/53 / 26/70 |
| MT LBH | 76 | 16 (21%) | 5/21 / 11/55 | 6/42 / 10/34 |
| MT other books | 172 | 48 (28%) | 24/97 / 24/75 | 19/91 / 29/81 |
| SP | 158 | 59 (37%) | 16/78 / 43/80 | 34/76 / 25/82 |
| Non-QSP | 48 | 11 (23%) | 6/27 / 5/21 | 10/28 / 1/20 |
| QSP | 40 | 4 (10%) | 3/29 / 1/11 | 3/24 / 1/16 |

- **Data.** 776 forms of 23 lexemes (book: 787 forms, "23 {or 24?}"
  lexemes; stored old fit 802). Only lexemes written both full and defective.
  30 of the 40 QSP forms are from 1QIsaa (4 full).
- **Lexemes.** GBWR/ (191 forms, 2 full, both SP) and XLB=/ (177, 1 full)
  are almost half of the data. The lexeme facts of §8.4.3.4 (GBWR/, TJMN/,
  >JTN/, G>WT/, PLGC/, KTNT/) agree with the data.
- **SP and the suffix.** SP with a suffix is 54% full, against 21% without.
  The difference is KTNT/: all 20 SP forms are suffixed and full. Without
  KTNT/, SP is 39 of 138 full (28%).
- **Parallel passages** (scroll vs MT form):

  | Corpus | both defective | both full | MT fuller | scroll fuller |
  |---|---|---|---|---|
  | SP | 93 | 28 | 4 | 27 (20 KTNT/) |
  | Non-QSP | 32 | 7 | 3 | 3 |
  | QSP | 35 | 2 | 0 | 2 |

  Without KTNT/, SP is fuller in 7 parallels and the MT in 4. The DSS do not
  differ from the MT.

## Method

- Bernoulli (logit) models in brms with nested random intercepts
  `(1 | scr_book2/lex)`.
- `corpus_group`: MT Pentateuch (reference), MT Former Prophets, MT LBH, MT
  other books, SP, non-QSP, QSP.
- Priors: normal(0, 2.5) on the intercept and coefficients, exponential(1)
  on the SDs. The prior predictive check (`check_firsty_prior_predictive`)
  covers the whole range.
- Sampler: 4 chains, warmup 1000 / 3000 iterations (8000 draws).
- Grouped 5-fold k-fold: every scroll-book is left out as a whole. No Bayes
  factors.
- Final model chosen by the credible-effects rules (`analysis/README.md`).

## Model comparison

`table_firsty_kfold.csv`. All formulas include `(1 | scr_book2/lex)`.

| Model | Fixed part | elpd diff | SE |
|---|---|---|---|
| **M0** | null (the book's model) | 0 | – |
| M1 | corpus (MT / SP / non-QSP / QSP) | −16.0 | 5.8 |
| M2 | corpus_group | −31.5 | 6.2 |
| M3 | M2 + has_suffix + has_prefix | −32.5 | 6.2 |
| M6 | M3 + corpus_group × suffix + corpus_group × prefix | −33.4 | 7.0 |
| M5 | M3 + corpus_group × prefix | −33.8 | 6.6 |
| M4 | M3 + corpus_group × suffix | −35.1 | 6.8 |

- All fits converged: max Rhat ≤ 1.006 (model set), no divergent transitions.
- Each step away from M0 makes the prediction of new books worse, by 3 to 5
  SE. The corpus groups cost most (M0 → M2, −31.5). Adding the affixes and
  their interactions costs little more.
- Why: the lexemes differ strongly (SD 7.5) and each book has its own mix of
  lexemes. A corpus-group coefficient learned from some books does not carry
  over to a left-out book with other lexemes.

## Final model M0

`has_vowel_letter ~ 1 + (1 | scr_book2/lex)`

Tables: `table_firsty_fixed_effects.csv`, `table_firsty_predicted.csv`,
`table_firsty_book_model.csv`, `table_firsty_random_book_lexeme.csv`.

| Parameter | Estimate [95%] |
|---|---|
| Intercept | −2.37 [−3.89, −1.10] |
| sd(scr_book2) | 1.04 [0.04, 2.93] |
| sd(scr_book2:lex) | 7.52 [5.26, 10.50] |

- **Predicted probability of full spelling** for a typical book and lexeme
  (`re_formula = NA`): 9% [2, 25]. The observed 27% is higher, because a few
  frequent lexemes are almost always full (TJMN/, MJTR/, TJKWN/, XJYWN/).
- **Why this model (rules 1–3).** No effect is both credible and robust:
  - **SP vs MT Pentateuch** is credible in M1–M3 (M2 +3.65 [0.70, 6.75],
    pd 0.992). It rests on KTNT/ (rule 3(i)): without KTNT/ it is +2.65
    [−0.42, 5.78], pd 0.959; in M6 +3.17, pd 0.967.
  - Even with the SP effect, the k-fold clearly prefers M0 (M2 −31.5, SE 6.2).
  - Suffix and prefix are not credible in M3 (−0.35, pd 0.71; −0.09, pd
    0.56) or in any group in M6 (largest: prefix in non-QSP −3.35, pd 0.94,
    1 of 20 prefixed forms full).
- No drop-one comparison: M0 has no fixed effects.

## Effects not in the final model

`fig_firsty_effects_not_in_final_model`, `table_firsty_effects_not_in_final_model.csv`
(corpus group from M2, common affix effect from M3, per-group affix effects
from M6; logit [95%], pd):

| Effect | Estimate | pd |
|---|---|---|
| SP vs MT Pentateuch (M2) | **3.65 [0.70, 6.75]** | 0.992 |
| Non-QSP vs MT Pentateuch (M2) | −2.69 [−5.68, 0.14] | 0.968 |
| QSP vs MT Pentateuch (M2) | −2.73 [−6.29, 0.88] | 0.934 |
| MT other books vs MT Pentateuch (M2) | −1.19 [−3.90, 1.51] | 0.81 |
| MT Former Prophets vs MT Pentateuch (M2) | −0.83 [−3.88, 2.33] | 0.70 |
| MT LBH vs MT Pentateuch (M2) | 0.17 [−3.22, 3.62] | 0.54 |
| Suffix, all groups (M3) | −0.35 [−1.71, 0.93] | 0.71 |
| Prefix, all groups (M3) | −0.09 [−1.26, 1.09] | 0.56 |

- Non-QSP and QSP tend to be more defective than the MT Pentateuch (pd 0.97
  and 0.93), but not credibly. These cells are small (48 and 40 forms), and
  the parallel passages show no difference from the MT.
- SP is the one credible difference and is a KTNT/ effect (see above).

## Robustness

`fig_firsty_robustness`, `table_firsty_robustness.csv` (logit, pd):

| Effect | M2 | M2 no KTNT/ | M6 | M6 no GBWR/ XLB=/ | M6 no 1QIsaa |
|---|---|---|---|---|---|
| SP vs MT Pent. | 3.65 .992 | 2.65 .959 | 3.17 .967 | 2.65 .938 | 3.22 .971 |
| Non-QSP vs MT Pent. | −2.69 .968 | −2.64 .962 | −2.05 .887 | −0.56 .62 | −2.04 .877 |
| QSP vs MT Pent. | −2.73 .934 | −2.80 .943 | −2.33 .886 | −1.92 .841 | −2.49 .864 |
| Prefix in non-QSP | – | – | −3.35 .942 | −3.09 .919 | −3.23 .938 |
| Suffix in MT Former Prophets | – | – | −1.81 .917 | −2.09 .947 | −1.80 .916 |

- No effect becomes credible in any variant. The SP effect is credible only
  with KTNT/ and only in the models without interactions (M1–M3).
- **Without GBWR/ and XLB=/** (368 forms, 47% of the data) the non-QSP
  difference disappears (−0.56): it comes from these two always-defective
  lexemes, which are relatively frequent in the non-QSP scrolls.
- **Prior sensitivity** (`table_firsty_prior_sensitivity_intercept.csv`):
  the intercept of M0 is −2.02 [−3.32, −0.90] with sd 1.5, −2.33 [−3.89,
  −1.10] with sd 2.5 and −2.41 [−4.18, −1.10] with sd 4. sd(scr_book2:lex)
  is 7.3, 7.5 and 7.5. The prior does not change the conclusion.

## Model checks

- **Convergence.** M0: max Rhat 1.004, min bulk ESS 834 (0.104 × draws, for
  sd(scr_book2)), no divergent transitions (`check_firsty_trace`, `_dens`).
  M0 with sd 1.5: Rhat 1.003. M2 without KTNT/: Rhat 1.003. M0 with sd 4:
  max Rhat 1.012 with 1000 / 3000, so refitted with warmup 2000 / 6000
  iterations (author, 2026-10-20): max Rhat 1.002, min bulk ESS 1629.
- **Posterior predictive checks** (`check_firsty_ppcheck_bars`, `_mean`):
  fine.
- **Groups** (`check_firsty_ppc_groups`): the observed share lies inside the
  95% predictive interval in every corpus group × suffix cell, including SP
  with a suffix (54% observed, 52% [46, 58] predicted) and QSP (9–10%).
- **Lexemes** (`check_firsty_ppc_lexemes`): all inside the 95% interval.
  The almost-always-defective lexemes are predicted slightly too full
  (GBWR/ 1.0% observed, 3.0% [1.0, 5.8] predicted; XLB=/ 0.6%, 2.2%): the
  random intercepts are shrunk towards the mean.
- **Bayes R2** 0.83 [0.79, 0.86]: nearly all of it from the lexemes.
- **LOO** (for completeness; the k-fold is used for comparison): elpd
  −150.2 (SE 12.5), 118 observations (15%) with Pareto k > 0.7, expected with
  226 book × lexeme groups of a few forms each.
- **In-sample classification**: accuracy 0.97, sensitivity 0.93,
  specificity 0.99.

## Comparison with the book (§8.4.3, manuscript 2026-09-10)

- **Table 8.33 (intercept-only model).** The book's model is M0. The refit
  gives intercept −2.37 [−3.89, −1.10] (book −3.66 [−6.05, −1.90]),
  sd(book) 1.04 (1.76) and sd(lex:book) 7.52 (9.16). The differences come
  from the priors (the old fit used normal(mean, 5) and student-t) and the
  data (776 forms; the old fit 802). The conclusion does not change.
- **Model choice.** The book chose the intercept-only model by Bayes factor.
  The grouped k-fold gives the same choice, by a clear margin (−16 to −35
  elpd against every other model).
- **SP.** The text should say that SP looks fuller only because of KTNT/
  (SP כיתנות, 20 of the 27 SP-fuller parallels), as §8.4.3.4 already notes
  for the vocalisation.
- ~~**§8.4.3.7** quotes corpus-group contrasts (QSP 11.89 etc.) for an
  intercept-only model.~~ Wrong (checked 2026-11-03): 11.89 is the QSP
  contrast of the first_w model (Table 8.32, §8.4.2). §8.4.3 quotes no group
  contrasts.
- **Counts.** 776 forms instead of 787 (data of 2026-10-19); 23 lexemes
  (the book's "{or 24?}" can go).

## Points for the author

1. **Final model M0** (agreed 2026-10-20). The SP effect is reported as a
   KTNT/ effect.
2. **M0 with prior sd 4** uses 2000 / 6000 iterations (the other fits
   1000 / 3000) because of Rhat 1.012 in the first fit.
3. **Non-QSP vs MT Pentateuch** (pd 0.97 in M2) disappears without GBWR/
   and XLB=/: a lexeme-mix effect, not a corpus effect.
4. ~~**§8.4.3.7** must drop or replace its corpus-group contrasts.~~ Not
   needed (see the comparison with the book).
