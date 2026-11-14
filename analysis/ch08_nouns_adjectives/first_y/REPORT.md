# First syllable, optional yod (§8.4.3) — analysis report

*Script: `first_y/analysis.R`. Figures and tables: `first_y/figures/`. Data
release v1.4.0 (2026-11-14): XLB=/ is no longer in the data (see Data). All
models and k-folds refitted on 2026-11-14 with the prefix `na_firsty_d4_`;
fold-sensitivity k-folds and the M1 robustness and prior fits the same day.
Final model **M1** (author, 2026-11-14; before: M0, 2026-10-20).*

Intervals: median with 95% quantile interval (66% in the figures), logit
scale unless an odds ratio (OR) is given; pd = probability of direction;
credible = pd ≥ 0.975. Reference levels: MT Pentateuch (M2–M6) or the whole
MT (M1), no suffix, no prefix.

## Summary

- The optional yod in the first syllable is mostly **defective**: 35% full
  overall (210 of 599), 23–39% in the MT groups, 28% in non-QSP, 13% in QSP,
  but **63% in SP**.
- The **lexeme** decides most of the spelling: GBWR/, >TWN/ and <NQ/ are
  almost always defective, TJMN/, MJTR/ and XJYWN/ almost always full (SD
  between lexemes within books 6.1 on the logit scale, against 0.5 between
  books).
- **SP is fuller than the MT**, by a credible margin: M1 +4.60 [1.93, 7.57]
  (OR about 100), pd > 0.999. It rests largely on two lexemes, but in M1 it
  stays credible without either: without KTNT/ (SP כיתנות) +3.63 [0.94, 6.56],
  without GBWR/ (its only 2 full forms are in SP) +3.13 [0.58, 5.98].
- **The k-fold prefers the corpus models to M0** under three fold splits
  (M0 −9.7 to −13.7 elpd, 1.7–2.4 SE). M1 (four corpora) and M2 (seven corpus
  groups) tie; M1 is the final model (the simpler one with the same credible
  effect).
- Non-QSP and QSP are not credibly different from the MT; the MT groups do
  not differ from each other; suffix and prefix have no credible effect.
- **Change from the earlier analysis.** On the old data the k-fold clearly
  preferred M0 (M2 −31.5). That preference came from XLB=/ (heleb 'fat'): it
  alone gave −30.6 of the −31.5, mostly through SP Leviticus. Without it, the
  book's conclusion "no effect of the corpus" no longer holds for SP.

## Descriptive results

`table_firsty_groups.csv`, `_groups_all`, `_suffix`, `_prefix`,
`_qsp_isaiah`, `_lexemes`, `_book_lexemes`, `_parallel_passages`,
`_parallel_counts`:

| Corpus group | n | full | without / with suffix | without / with prefix |
|---|---|---|---|---|
| MT Pentateuch | 94 | 37 (39%) | 11/33 / 26/61 | 22/50 / 15/44 |
| MT Former Prophets | 116 | 36 (31%) | 12/34 / 24/82 | 10/51 / 26/65 |
| MT LBH | 72 | 16 (22%) | 5/21 / 11/51 | 6/41 / 10/31 |
| MT other books | 156 | 48 (31%) | 24/83 / 24/73 | 19/85 / 29/71 |
| SP | 93 | 59 (63%) | 16/33 / 43/60 | 34/50 / 25/43 |
| Non-QSP | 36 | 10 (28%) | 5/16 / 5/20 | 9/24 / 1/12 |
| QSP | 32 | 4 (13%) | 3/23 / 1/9 | 3/22 / 1/10 |

(Percentages are raw shares; the figures show the Bayesian binomial
estimate.)

- **Data.** 599 forms of 22 lexemes (MT 438, SP 93, DSS 68). Only lexemes
  written both full and defective. Data v1.4.0: the only full form of XLB=/,
  XJLB in 4Q130 at Exod. 13.5, is halab 'milk' (XLB/ in the MT), wrongly
  lemmatised in the DSS data. It is removed in the pipeline
  (`AD_HOC_REMOVALS`); without it XLB=/ has no variation and the variation
  filter drops all its 177 forms (before: 776 forms, 23 lexemes). 25 of the
  32 QSP forms are from 1QIsaa (4 full).
- **Lexemes.** GBWR/ (191 forms, 2 full, both SP) is almost a third of the
  data. The lexeme facts of §8.4.3.4 (GBWR/, TJMN/, >JTN/, G>WT/, PLGC/,
  KTNT/) agree with the data.
- **SP and the suffix.** SP with a suffix is 72% full (43/60), without 48%
  (16/33). KTNT/ contributes 20 suffixed full forms; without KTNT/ SP is 39 of
  73 full (53%), still above every MT group.
- **Parallel passages** (scroll vs MT form):

  | Corpus | both defective | both full | MT fuller | scroll fuller |
  |---|---|---|---|---|
  | SP | 29 | 28 | 4 | 27 (20 KTNT/) |
  | Non-QSP | 21 | 7 | 3 | 3 |
  | QSP | 27 | 2 | 0 | 2 |

  Without KTNT/, SP is fuller in 7 parallels and the MT in 4. The DSS do not
  differ from the MT.

## Method

- Bernoulli (logit) models in brms with nested random intercepts
  `(1 | scr_book2/lex)`.
- `corpus` (M1): MT (reference), SP, non-QSP, QSP. `corpus_group` (M2–M6):
  MT Pentateuch (reference), MT Former Prophets, MT LBH, MT other books, SP,
  non-QSP, QSP.
- Priors: normal(0, 2.5) on the intercept and coefficients, exponential(1)
  on the SDs. The prior predictive check (`check_firsty_prior_predictive`)
  covers the whole range.
- Sampler: 4 chains, warmup 1000 / 3000 iterations (8000 draws); M1 with
  prior sd 4 2000 / 6000, as the M0 fit with sd 4 before.
- Grouped 5-fold k-fold: every scroll-book is left out as a whole (fold seed
  2026); fold sensitivity with seeds 1 and 2 for M0–M2. No Bayes factors.
- Final model chosen by the credible-effects rules (`analysis/README.md`).

## Model comparison

`table_firsty_kfold.csv`. All formulas include `(1 | scr_book2/lex)`.

| Model | Fixed part | elpd diff | SE |
|---|---|---|---|
| M2 | corpus_group | 0 | – |
| M4 | M3 + corpus_group × suffix | −1.1 | 1.8 |
| M3 | M2 + has_suffix + has_prefix | −1.4 | 0.9 |
| M6 | M3 + corpus_group × suffix + corpus_group × prefix | −1.5 | 2.1 |
| **M1** | corpus (MT / SP / non-QSP / QSP) | −2.2 | 2.1 |
| M5 | M3 + corpus_group × prefix | −2.5 | 1.6 |
| M0 | null (the book's model) | −13.7 | 5.7 |

**Fold sensitivity** (`table_firsty_kfold_fold_seeds.csv`; elpd difference
from the best of the three, SE):

| Fold seed | M0 | M1 | M2 |
|---|---|---|---|
| 2026 | −13.7 (5.7) | −2.2 (2.1) | 0 |
| 1 | −9.7 (5.9) | −0.4 (1.6) | 0 |
| 2 | −10.9 (5.5) | 0 | −3.1 (1.7) |

- All fits converged: max Rhat ≤ 1.005, no divergent transitions (M1 with
  prior sd 1.5: one).
- M0 is the worst model under every split, by 1.7–2.4 SE. M1–M6 lie within
  about one SE of each other: the MT groups, the affixes and their
  interactions add nothing.
- The gain over M0 comes from a few lexemes (M2 − M0 per lexeme, three
  splits): GBWR/ +10 to +17, KTNT/ +8; against it >TWN/ −11 to −14 and <NQ/
  −6 to −7 (almost always defective, also in SP, so a corpus effect for SP
  predicts them too full).
- **Old data (with XLB=/).** M0 was best by a clear margin (M1 −16.0, M2
  −31.5). XLB=/ alone gave M2 − M0 = −30.6, of which SP Leviticus −22.6: SP
  writes heleb defectively, and a model with an SP effect predicts it full.
  The fold split also changed completely, because 11 scroll-books had only
  XLB=/ forms.

## Final model M1

`has_vowel_letter ~ corpus + (1 | scr_book2/lex)`

Tables: `table_firsty_fixed_effects.csv`, `table_firsty_effects.csv`,
`table_firsty_predicted.csv`, `table_firsty_random_book_lexeme.csv`; figure
`fig_firsty_effects`.

| Parameter | Median [95%] | pd |
|---|---|---|
| Intercept (MT) | −1.23 [−2.64, −0.02] | 0.98 |
| **SP vs MT** | **4.60 [1.93, 7.57]** | > 0.999 |
| Non-QSP vs MT | −1.83 [−4.69, 0.83] | 0.91 |
| QSP vs MT | −2.09 [−5.53, 1.27] | 0.89 |
| sd(scr_book2) | 0.47 [0.02, 1.95] | |
| sd(scr_book2:lex) | 6.06 [4.38, 8.53] | |

(`table_firsty_fixed_effects.csv` has posterior means: SP 4.64, sd(book)
0.62, sd(lex:book) 6.17. The book tables use medians,
`book_ch8/table_ch8_model_summaries.csv`.)

- **Predicted probability of full spelling** for a typical book and lexeme
  (`re_formula = NA`): MT 23% [7, 50], SP 97% [69, 100], non-QSP 4% [0, 37],
  QSP 4% [0, 48]. These are far from the raw shares, because the lexeme SD
  is large: for a lexeme of average spelling the corpus difference on the
  logit scale becomes a large difference in probability.
- **Why this model (rules 1–3).**
  - Rule 1: the SP effect is credible in every model with a corpus term
    (M1–M3, M6), and the k-fold does not prefer a fuller model (M2–M6 within
    about one SE of M1).
  - Rule 2: the corpus factor stays with all its levels; non-QSP and QSP are
    reported with their intervals (not credible).
  - Rule 3(i): the SP effect rests largely on GBWR/ and KTNT/, but it does not
    disappear without either of them in M1 (Robustness). It is therefore kept
    as a corpus effect, with the caveat that two lexemes carry much of it.
  - M1 rather than M2: they tie in the k-fold, and the MT groups and the
    finer split of the MT add no credible effect (from M2: all pd ≤ 0.91).
- **Drop-one** (`table_firsty_kfold_drop_one.csv`): M1 without corpus (= M0)
  −11.4 (SE 5.1).
- **Rule 4**: not needed; the effect brings a clear k-fold gain.

## Effects not in the final model

`fig_firsty_effects_not_in_final_model`, `table_firsty_effects_not_in_final_model.csv`
(MT groups from M2, common affix effect from M3, per-group affix effects from
M6; logit [95%], pd):

| Effect | Estimate | pd |
|---|---|---|
| MT Former Prophets vs MT Pentateuch (M2) | −1.25 [−4.19, 1.82] | 0.80 |
| MT LBH vs MT Pentateuch (M2) | −0.35 [−3.45, 2.86] | 0.58 |
| MT other books vs MT Pentateuch (M2) | −1.68 [−4.34, 0.84] | 0.90 |
| Suffix, all groups (M3) | −0.66 [−2.02, 0.58] | 0.84 |
| Prefix, all groups (M3) | 0.06 [−1.15, 1.23] | 0.53 |

- In M6 no affix effect is credible in any group (largest: prefix in
  non-QSP −2.29, pd 0.85, 1 of 12 prefixed forms full; suffix in MT Former
  Prophets −1.92, pd 0.94).

## Robustness

`fig_firsty_robustness`, `table_firsty_robustness.csv` (SP effect, logit
[95%], pd):

| Variant | SP vs MT (Pentateuch) |
|---|---|
| **M1 (final)** | **4.60 [1.93, 7.57]**, > 0.999 |
| M1 without KTNT/ (545 forms) | 3.63 [0.94, 6.56], 0.995 |
| M1 without GBWR/ (408 forms) | 3.13 [0.58, 5.98], 0.990 |
| M1, prior sd 1.5 | 3.04 [0.88, 5.24], 0.997 |
| M1, prior sd 4 | 5.87 [2.65, 9.69], > 0.999 |
| M2 | 4.09 [1.23, 7.22], 0.997 |
| M2 without KTNT/ | 3.00 [0.03, 6.24], 0.977 |
| M6 | 3.77 [0.34, 7.28], 0.985 |
| M6 without GBWR/ | 2.65 [−0.71, 6.07], 0.938 |
| M6 without 1QIsaa | 3.82 [0.28, 7.38], 0.983 |

- The SP effect stays credible in all M1 variants, but not in M6 without
  GBWR/, where the comparison is with the MT Pentateuch only and the model
  has the interactions. It is weaker without each of the two lexemes.
- Non-QSP vs MT is −1.83 (pd 0.91) in M1 and −0.88 (pd 0.73) without GBWR/:
  the tendency towards defective spelling in non-QSP comes from GBWR/, which
  is frequent there (15 of 36 forms).
- **Prior sensitivity** (`table_firsty_prior_sensitivity_intercept.csv`):
  intercept −1.07 [−2.26, 0.02] (sd 1.5), −1.23 [−2.64, −0.02] (sd 2.5),
  −1.36 [−2.93, −0.01] (sd 4). The size of the SP effect depends on the prior
  (3.0 to 5.9), as expected with few SP books; its direction and credibility
  do not.

## Model checks

- **Convergence.** M1: max Rhat 1.004, min bulk ESS / draws 0.22, no
  divergent transitions (`check_firsty_trace`, `_dens`). M1 without KTNT/
  1.003, without GBWR/ 1.003; prior sd 1.5 1.003 (1 divergent transition of
  8000), sd 4 1.001.
- **Posterior predictive checks** (`check_firsty_ppcheck_bars`, `_mean`):
  fine.
- **Groups** (`check_firsty_ppc_groups`): the observed share lies inside the
  95% predictive interval in every corpus group × suffix cell, including SP
  with a suffix (72% observed, 71% [65, 77] predicted).
- **Lexemes** (`check_firsty_ppc_lexemes`): all inside the 95% interval except
  TJMN/ at the upper edge (97.4% observed, 90% [79, 97]). The almost-always-
  defective lexemes are predicted slightly too full (GBWR/ 1.0% observed,
  3.6% [1.6, 6.8]): shrinkage.
- **Bayes R2** 0.81 [0.77, 0.84]: nearly all of it from the lexemes.
- **LOO** (for completeness; the k-fold is used for comparison): elpd
  −142.8 (SE 11.9), 106 observations (18%) with Pareto k > 0.7, expected with
  many book × lexeme groups of a few forms each.
- **In-sample classification**: accuracy 0.96, sensitivity 0.93,
  specificity 0.98.

## Comparison with the book (§8.4.3, manuscript 2026-09-10)

- **Model and conclusion.** The book has the intercept-only model (Table
  8.33), chosen by Bayes factor, and concludes that the corpus has no effect.
  On the clean data the k-fold prefers a corpus model, and SP is credibly
  fuller than the MT. The section must be rewritten: SP fuller (largely, but
  not only, through KTNT/ and GBWR/), no difference between the MT groups,
  the non-QSP and QSP scrolls not credibly different from the MT, no effect
  of suffix or prefix.
- **Table 8.33** becomes the table of M1 (fixed effects above). For
  reference, M0 on the new data: intercept −1.14 [−2.58, 0.13], sd(book)
  1.20, sd(lex:book) 6.70 (`table_firsty_book_model.csv`; book: −3.66,
  1.76, 9.16).
- **heleb.** The text should not count חלב 'fat' among the lexemes; the only
  "full" form was חלב 'milk' in 4Q130 (Exod. 13.5), a lemmatisation error
  removed in data v1.4.0. Sentences that name גבור and חלב as the always-
  defective lexemes behind the non-QSP tendency keep only גבור.
- **Counts.** 599 forms of 22 lexemes (book: 787, "23 {or 24?}").

## Points for the author

1. **Final model M1** (agreed 2026-11-14), with the caveat that the SP effect
   rests largely on GBWR/ and KTNT/.
2. **Fold sensitivity**: the M0–M2 ranking checked with three fold splits;
   only seed 2026 enters the main table.
3. **M1 with prior sd 4** uses 2000 / 6000 iterations, as the M0 fit with sd 4
   before; one divergent transition in the sd 1.5 fit (Rhat 1.003).
4. The noun helpers (`functions_nouns.R`) now accept a final model with
   `corpus` (effect `corpus_mt`, "Corpus (vs MT)"); the other datasets are
   unchanged.
