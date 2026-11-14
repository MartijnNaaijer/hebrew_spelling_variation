# Qal infinitive absolute — analysis report

*2026-10-10, refitted 2026-10-18 with the harmonised design (prior normal(0,
2.5), grouped 5-fold k-fold, `corpus_group` with the MT Pentateuch as
reference; files `infa2_*`, warmup 1000 / iter 3000). Script:
`infa_qal/analysis.R`. Figures and tables: `infa_qal/figures/`. Final model:
**M3** (corpus group + ע-ע), confirmed by the author on 2026-10-18.
History: M3 of the old model set (corpus + LBH + ע-ע) was accepted on
2026-10-08; under the credible-effects rule the author chose infa7 (QSP +
ע-ע) on 2026-10-10; with the harmonised corpus groups (`../TODO.md` section
13, item 8) the final model is M3 of the new model set.*

## Summary

- Final model **M3**: corpus group (MT Pentateuch, MT Former Prophets, MT
  LBH, MT other books, non-QSP, QSP) + ע-ע.
- The QSP scrolls spell the infinitive absolute more fully than the MT
  Pentateuch (odds ratio ≈ 8.7, 95% interval 2.0–55, pd 0.998). Without
  1QIsaa the effect is larger; 1QIsaa I spells like the MT Pentateuch.
- Within the MT, the LBH books are probably fuller than the Pentateuch (odds
  ratio ≈ 6.5, 0.8–50, pd 0.966): just not credible under the main prior,
  credible with prior sd 4 and without 1QIsaa. The other MT groups and the
  non-QSP scrolls do not differ credibly from the Pentateuch.
- ע-ע verbs are more often full (odds ratio ≈ 11, 1.6–130, pd 0.993). The
  effect is credible under every prior and without 1QIsaa, but it rests on
  10 forms.
- The prefix has no credible effect.
- Neither effect of M3 clearly improves the prediction of left-out books
  (rule 4), and no model is clearly better than another in the k-fold.

## Descriptive results

**Data.**
- **Dataset:** `infa_qal.csv`, 414 forms of the qal infinitive absolute.
  - 317 MT forms, 58 from non-QSP scrolls, 39 from QSP scrolls; no SP forms.
  - 131 lexemes in 77 scroll-books.
- **Outcome:** full (`has_vowel_letter = 1`) vs defective spelling. 54% of the forms are full.
- **Data correction:** one form was recoded as full: tf_id 2086635, FRWPP in 11Q5 at 2 Sam 23:7. The correction is documented in section 1a of the script.
- **Unbalanced lexemes:** a few lexemes dominate:
  - HLK[ (57 forms, 74% full)
  - JD<[ (16 forms, 19% full)
- **Mostly single-form groups:** 246 of the 304 book×lexeme groups contain one form.

**Verb classes** (`fig_infa_explore_verb_classes`):

| Class | Full | Forms |
|---|---|---|
| ע-ע verbs | 9 of 10 (7 passages; only טפף defective) | 10 |
| Other verbs | 52% | 314 |
| HLK[ | 74% | 57 |
| I-yod verbs without HLK[ | 30% | 33 |

I-yod was not modelled as a class, because HLK[ and the other I-yod verbs go in opposite directions.

**Parallel passages** (`fig_infa_parallel_passages`): where a scroll and the MT contain the same form, the scroll is fuller more often than the MT:

| | Scroll fuller | MT fuller | Both full | Both defective |
|---|---|---|---|---|
| Non-QSP | 9 | 3 | 19 | 22 |
| QSP | 7 | 2 | 19 | 7 |

*Recounted 2026-11-05: forms paired by their position in the raw text when the scroll and the MT have
the same number of forms of the lexeme in the verse (`parallel_forms(occ = raw_occurrences(...))`).*

*Corrected 2026-10-09: when a verse contains several forms of the same lexeme, the n-th scroll form is now paired with the n-th MT form (previously all were paired with the first MT form). This changed one to three forms per corpus; the conclusions are unchanged.*

The non-QSP scrolls are fuller than the MT in 9 parallel forms and less full in 3, although the model finds no overall difference between them. These few pairs do not outweigh the 58 non-QSP forms as a whole.

## Method

**Research questions.**
1. Do the QSP and non-QSP scrolls spell the infinitive absolute more fully than the MT?
2. Do the groups of books in the MT differ (in particular the late books, LBH)?
3. Do ayin-ayin (ע-ע) verbs and forms with a prefix behave differently?

- **Model:** Bayesian logistic regression (brms, Bernoulli logit).
- **Random part:** always nested, `(1 | scr_book2/lex)`. This is the author's decision.
- **Priors:** normal(0, 2.5) on intercept and coefficients; exponential(1) on the standard deviations of the random intercepts, as in all verb forms (until 2026-10-10 infa used sd 1.5). Prior sensitivity: the final model refitted with sd 1.5 and 4. No Bayes factors (author, 2026-10-14).
- **Corpus coding:** `corpus_group` with six levels, the MT Pentateuch as reference; the non-QSP scrolls are one group.
- **Candidate models:**

| Model | Fixed effects |
|---|---|
| M0 | none (null model) |
| M1 | corpus (MT / non-QSP / QSP) |
| M2 | corpus group |
| **M3** | corpus group + ע-ע — **final model** |
| M4 | M3 + prefix |
| M3b | corpus + ע-ע |
| infa7 | QSP (vs MT and non-QSP together) + ע-ע (the book's final model) |
| Q1 | QSP |
| M3 without corpus group | ע-ע (drop-one model) |

- **Model comparison:** grouped 5-fold cross-validation (until 2026-10-10: 10 folds); whole scroll-books are left out per fold. LOO is unreliable because most groups contain one form.
- **Sampler:** warmup 1000, iter 3000 (8000 draws).
- **Effects:** logit scale, shown as odds ratios; median with 66% and 95% quantile intervals and pd (probability of direction: the posterior probability that the effect has the sign of its estimate).
- **Robustness of the final model:**
  - M3 without 1QIsaa;
  - 1QIsaa I, 1QIsaa II and the other QSP scrolls as separate groups;
  - prior sd 1.5 and 4.
- **Parallel passages:** the same form in the MT and in a scroll, compared descriptively. A passage effect in the model would break the nested structure.

## Model comparison

**Grouped 5-fold cross-validation** (`table_infa_kfold.csv`; elpd = expected log predictive density; higher is better):

| Model | elpd difference to best | SE |
|---|---|---|
| **M3** | 0 | — |
| infa7 | −0.7 | 2.5 |
| M4 | −1.1 | 0.8 |
| M3 without corpus group | −1.2 | 4.7 |
| M3b | −1.4 | 2.5 |
| M2 | −2.2 | 1.4 |
| Q1 | −2.6 | 2.8 |
| M1 | −3.5 | 2.8 |
| M0 | −3.7 | 4.9 |

**Direct comparisons** (pointwise differences on the same folds; positive = the first model predicts better; drop-one in `table_infa_kfold_drop_one.csv`):

| Question | Comparison | elpd difference (SE) |
|---|---|---|
| corpus group | M3 vs M3 without corpus group | 1.2 (4.7) |
| ע-ע | M3 vs M2 | 2.2 (1.4) |
| prefix | M4 vs M3 | −1.1 (0.8) |
| MT split | M2 vs M1 | 1.3 (2.5) |
| non-QSP merged with MT | infa7 vs M3b | 0.8 (0.6) |

No model is clearly better than another.

## Final model M3

**Choice** (corpus group + ע-ע):

- **Only credible effects:** the QSP scrolls vs the MT Pentateuch (pd 0.998) keep the corpus-group factor (rule 2), and all its levels are reported; ע-ע has pd 0.993.
- **Prefix left out:** no credible effect (M4: −0.27, −1.02 to 0.47, pd 0.77), and the k-fold is against it.
- **infa7 not chosen:** it predicts as well (−0.7, SE 2.5), but it merges the MT groups, and the MT LBH is borderline fuller than the Pentateuch (pd 0.966; credible with prior sd 4 and without 1QIsaa). The data do not clearly show "no difference" within the MT, so the harmonised corpus groups stay (`analysis/README.md`).

### Effects

`fig_infa_effects`, `table_infa_effects.csv` (log-odds, median with 95% interval):

| Effect | Log-odds (95% interval) | Odds ratio | pd |
|---|---|---|---|
| MT Former Prophets vs MT Pentateuch | 0.63 (−0.82 to 2.06) | ≈ 1.9 | 0.83 |
| MT LBH vs MT Pentateuch | 1.88 (−0.18 to 3.91) | ≈ 6.5 | 0.966 |
| MT other books vs MT Pentateuch | 0.65 (−0.49 to 1.86) | ≈ 1.9 | 0.88 |
| Non-QSP scrolls vs MT Pentateuch | 0.52 (−0.82 to 1.67) | ≈ 1.7 | 0.81 |
| **QSP scrolls vs MT Pentateuch** | 2.17 (0.68 to 4.01) | ≈ 8.7 | 0.998 |
| **ע-ע verbs vs other verbs** | 2.38 (0.44 to 4.84) | ≈ 11 | 0.993 |

The QSP effect is larger against the MT Pentateuch than against the MT as a whole (infa7: 1.66, odds ratio ≈ 5.3), because the Pentateuch is the least full MT group.

### Predicted probability of full spelling

`fig_infa_predicted`, `table_infa_predicted.csv` (typical book and lexeme):

| Condition | Median | 95% interval |
|---|---|---|
| MT Pentateuch | 41% | 23–66% |
| MT Former Prophets | 57% | 30–83% |
| MT LBH | 82% | 43–97% |
| MT other books | 57% | 40–77% |
| Non-QSP scrolls | 54% | 35–72% |
| QSP scrolls | 86% | 65–97% |
| MT Pentateuch, ע-ע verb | 89% | 48–99% |

### Credible effects without a clear gain in prediction (rule 4)

Neither effect of the final model clearly improves the prediction of left-out books:
- **Corpus group:** M3 vs M3 without corpus group gives 1.2 (SE 4.7);
- **ע-ע:** M3 vs M2 gives 2.2 (SE 1.4).

The reasons:
- **QSP:** the effect is large (odds ratio ≈ 8.7), but it rests on 39 forms. In a grouped k-fold every QSP scroll-book is left out in turn. 1QIsaa is the largest QSP book, and its first half spells like the MT Pentateuch, so leaving it out does not help predict the other books. The large SE (4.7) reflects this variation between QSP books.
- **ע-ע:** the effect rests on 10 forms (9 full) of a few lexemes. Ten forms can change the elpd of 414 forms only a little, whatever the effect size. Unlike in the old model set, it is credible under prior sd 1.5 (0.15 to 3.63) and 4, and without 1QIsaa (0.20 to 4.60).

What this means for the conclusion:
- The QSP scrolls spell the infinitive absolute more fully than the MT Pentateuch. This is a difference between the corpora, not a rule that predicts every QSP book, and it is clearest outside 1QIsaa I.
- The ע-ע effect is credible, but it is a small-sample finding. It should be presented as a tendency of the verb class (9 of 10 full), not as a firm rule.

## Effects not in the final model

No credible effect, or not in the final model's coding; estimates from the comparison models (`fig_infa_effects_not_in_final_model`, `table_infa_effects_not_in_final_model.csv`):

| Effect | Model | Log-odds (95% interval) | pd |
|---|---|---|---|
| With prefix vs without | M4 | −0.27 (−1.02 to 0.47) | 0.77 |
| Non-QSP scrolls vs MT | M3b | −0.04 (−1.13 to 0.89) | 0.53 |
| QSP scrolls vs MT | M3b | 1.69 (0.38 to 3.31) | 0.995 |
| QSP scrolls vs MT and non-QSP scrolls | infa7 | 1.66 (0.44 to 3.29) | 0.998 |

- **Non-QSP scrolls:** they spell like the MT as a whole (M3b) and do not differ credibly from the MT Pentateuch (M3).
- **LBH** is now a level of the final model's corpus group (see above): 15 MT forms, 80% full.

## Robustness

**Key effects of M3** (`fig_infa_robustness`, `table_infa_robustness.csv`; log-odds vs the MT Pentateuch, median with 95% interval, pd):

| Variant | QSP vs MT Pentateuch | MT LBH vs MT Pentateuch | ע-ע |
|---|---|---|---|
| M3 (final, prior sd 2.5) | 2.17 (0.68 to 4.01), 0.998 | 1.88 (−0.18 to 3.91), 0.966 | 2.38 (0.44 to 4.84), 0.993 |
| without 1QIsaa | 3.95 (1.53 to 7.12), 1.00 | 1.90 (0.11 to 3.90), 0.981 | 2.14 (0.20 to 4.60), 0.985 |
| 1QIsaa split (other QSP scrolls) | 3.93 (1.43 to 7.18), 1.00 | 1.86 (−0.08 to 3.74), 0.972 | 2.43 (0.53 to 4.85), 0.995 |
| prior sd 1.5 | 1.75 (0.48 to 3.17), 0.997 | 1.41 (−0.35 to 3.08), 0.946 | 1.76 (0.15 to 3.63), 0.985 |
| prior sd 4 | 2.43 (0.86 to 4.64), 0.999 | 2.20 (0.06 to 4.68), 0.976 | 2.81 (0.63 to 5.74), 0.995 |

In the 1QIsaa split, 1QIsaa I gives 0.30 (−1.63 to 2.13), pd 0.63, and 1QIsaa II 2.48 (0.07 to 5.14), pd 0.979.

- **Not an artefact of 1QIsaa:** without 1QIsaa the QSP effect is even larger.
- **1QIsaa I doesn't share it:** the first half of the scroll spells the infinitive absolute like the MT Pentateuch; 1QIsaa II is credibly fuller.
- **MT LBH** is borderline: pd 0.95–0.98 across the variants.
- The other levels of the corpus group stay not credible under every prior (pd ≤ 0.91).

## Model checks

Final model M3:
- **Convergence:** max Rhat 1.005, no divergent transitions, minimum bulk ESS / draws 0.12. All 14 fits: max Rhat ≤ 1.007, no divergences. Only the 1QIsaa-split fit has a tail ESS / draws below 0.1 (0.083, for one random intercept).
- **Fit per group of books:** the observed share of full spellings lies within the model's 95% predictive interval for every group (`check_infa_ppc_groups`): MT Pentateuch 42% observed vs 43% predicted, MT LBH 80% vs 78% (53–100%), QSP 77% vs 76%.
- **Bayes R²:** 0.30 (95% interval 0.15–0.44).
- **LOO:** 2 observations (0.5%) with Pareto k > 0.7, but model comparison uses the grouped k-fold.
- **In-sample classification:** not used as a quality measure, because the book×lexeme intercepts inflate it.

The diagnostic figures (`check_infa_*`) cover the prior predictive check, trace and density plots, posterior predictive checks and random intercepts.

## Comparison with the book

- The book's final model infa7 (QSP + ע-ע) predicts as well as M3 (−0.7, SE 2.5) and tells the same story about the QSP scrolls and the ע-ע verbs.
- M3 also shows the groups of books in the MT with the harmonised coding: the LBH books are probably fuller than the Pentateuch; the other groups don't differ credibly.
- New compared with the book: neither effect clearly improves the prediction of left-out books (rule 4); ע-ע is credible under every prior; 1QIsaa I spells like the MT, so the QSP effect is clearest outside it.

## Figures and tables

All figures are in `infa_qal/figures/`, as PNG at 600 dpi and as PDF.

| Book figure | Content |
|---|---|
| `fig_infa_groups` | full spelling per group of books (MT, non-QSP, QSP) |
| `fig_infa_explore_verb_classes` | other verbs, ע-ע, I-yod without HLK[, HLK[ |
| `fig_infa_explore_prefix` | with and without prefix per group of books |
| `fig_infa_parallel_passages` | the same form in the MT and a scroll |
| `fig_infa_predicted` | predicted probability of full spelling (final model) |
| `fig_infa_effects` | odds ratios (final model) |
| `fig_infa_robustness` | key effects without 1QIsaa, 1QIsaa split, prior sd 1.5 and 4 |
| `fig_infa_effects_not_in_final_model` | prefix (M4), non-QSP and QSP vs MT (M3b), QSP (infa7) |

| Table (CSV) | Content |
|---|---|
| `table_infa_fixed_effects` | fixed effects with pd |
| `table_infa_predicted` | predicted probabilities |
| `table_infa_effects` | odds ratios of the final model (log-odds), with pd |
| `table_infa_effects_not_in_final_model` | effects from the comparison models, with pd |
| `table_infa_robustness` | robustness and prior sensitivity, with pd |
| `table_infa_kfold` | k-fold model comparison |
| `table_infa_kfold_drop_one` | k-fold without each effect of the final model |
| `table_infa_parallel_passages` | all parallel forms |

## Points for the author

**Author's review.**
- 2026-10-08: M3 (old model set) accepted as the final model.
- 2026-10-10: final model infa7, under the credible-effects rule; the rule-4 discussion accepted.
- 2026-10-18: M3 of the harmonised model set (corpus group + ע-ע) confirmed as the final model.
- The ע-ע effect is a property of the verb class.
- The difference between 1QIsaa I (like the MT) and 1QIsaa II and the other QSP scrolls (fuller) fits the known difference between the two halves of the scroll.

**Prefix by group of books (remark for the text).** There is no overall
prefix effect (M4: −0.27, −1.02 to 0.47), but the descriptive shares differ
between the groups of books:
- In "MT Other", forms with a prefix are less often full (32%, n = 41) than forms without (58%, n = 103).
- In the other MT groups the prefix forms are fuller, but there are only 8–10 of them per group.

The author's decision (2026-10-11): mention this in the text as a descriptive
observation (`fig_infa_explore_prefix`); no prefix × group model is fitted.

**Still open.**
1. The MT LBH is borderline (pd 0.966): present it as "probably fuller", not as a credible difference?
2. Stale outputs of the old model set in `figures/` (no longer written by the script): `fig_infa_qsp_robustness`, `table_infa_qsp_robustness`, `table_infa_prior_sensitivity`, `table_infa_kfold_final_model`. They can be deleted.
