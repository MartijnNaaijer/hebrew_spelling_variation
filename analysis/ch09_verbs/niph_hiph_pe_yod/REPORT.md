# Niphal, hiphil and hophal of I-waw and I-yod verbs — analysis report

*2026-10-10, harmonised 2026-10-17 (layout and interval format as in the
other verb forms); refitted 2026-10-17/18 with the MT Pentateuch as reference
level (`pey2_*`, warmup 1000 / iter 3000), with the check models M1s (suffix)
and M1p (prefix). Script: `niph_hiph_pe_yod/analysis.R`. Figures and tables:
`niph_hiph_pe_yod/figures/`. **Status: final model M1 (tense only), chosen by
the author under the rule "final models contain only credible effects";
report accepted for now (2026-10-10).***

## Summary

- The first syllable of these forms is usually written full (86%). The
  **wayyiqtol** is the exception: 64% full, odds about 1/7 of the perfect;
  a typical book and lexeme gives 78% full in the wayyiqtol vs 96% in the
  perfect. The imperative is somewhat fuller than the perfect.
- The final model contains **tense only** (M1). Stem, original yod vs waw
  verb, prefix, corpus and the groups of books in the MT have no credible
  effect. The suffix or ending is credible in a check model (log-odds −0.73,
  95% −1.19 to −0.28), but it makes the cross-validation clearly worse
  (−9.6 elpd, SE 3.3) and is not visible in the raw shares (87% vs 86%); it
  stays out of the final model (author, 2026-10-18).
- The original yod verbs look less full only because of JBC[ (HBJC). The
  model with tense x yod verb (the book's model 10) predicts best in the
  k-fold, but 16.5 of its 16.6 elpd gain come from JBC[ alone: a lexeme
  effect (rule 3(i)).
- The scrolls are not credibly fuller than the MT; at most a weak indication
  for the QSP scrolls (pd 0.94), mainly 1QIsaa II. The MT is already about
  90% full outside the wayyiqtol.

## Data

- **Dataset:** `niph_hiph_pe_yod.csv` (data folder version of 2026-10-08), 2,248 forms of the niphal, hiphil and hophal of original I-waw verbs (incl. HLK[) and original I-yod verbs.
  - 1,831 MT forms, 206 from non-QSP scrolls, 211 from QSP scrolls; no SP forms.
  - 47 lexemes in 131 scroll-books.
- **Outcome:** vowel letter in the first syllable: full (e.g. HWLJD, HJVJB) vs defective (HLJD, HVJB). 86% of the forms are full.
- **Exclusions:**
  - **One form, tf_id 1946114:** HLK[ imperative in 4Q13 (Exodus), a difficult reading of the first syllable. It is analysed in the triliteral hiphil dataset instead.
  - **II-tsade verbs** (JY<[, JYG[, JYQ[, JYR[, JYT[; 65 forms): the first radical assimilates to the tsade, so there is no vowel to spell in the first syllable.
- **JBC[ (note by the author's decision):** JBC[ stays in the data. Its hiphil perfect is mostly written HBJC (9 of 32 forms full, HWBJC). These forms could also be analysed as hiphil of BWC[ ("be ashamed"). JBC[ alone makes the original yod verbs look less full; see "Effects not in the final model".
- **Prefix:** not in the main models; tested only in the check model M1p. It is almost always the conjunction ו, which every wayyiqtol (283 of 283) and many weqatal forms have, so it mostly stands in for tense (rule 3(ii) below). Prefixes and suffixes are described in `table_pey_affixes`.

## Research questions

1. Which forms are spelled defectively: tense (especially the wayyiqtol), stem, original yod vs waw verbs?
2. Do the QSP and non-QSP scrolls spell the first syllable more fully than the MT? Do the groups of books in the MT differ?

## Descriptive results

**Tense** (`fig_pey_tenses`):
- The wayyiqtol is the least full tense: 64% (MT 64%).
- The other tenses are 83–97% full.

**The wayyiqtol and JSP[** (`fig_pey_wayyiqtol_jsp`):

| Forms | Full |
|---|---|
| Wayyiqtol of JSP[ (ויסף) | 33% |
| Wayyiqtol of the other verbs | 70% |
| JSP[ in the other tenses | 66% |
| Other verbs in the other tenses | 92% |

**Stem and original yod verbs** (`fig_pey_stems_yod`):
- niphal 95%, hophal 92%, hiphil 85%;
- original yod verbs (hiphil only) 80%, without JBC[ 90%;
- original waw verbs in the hiphil 85%.

**Groups of books** (`fig_pey_groups`): the MT Former Prophets are less full (75%) only because they contain many wayyiqtol forms. Without the wayyiqtol they are 87% full, like the other groups.

**Lexemes** (`fig_pey_lexemes`): most lexemes are 80–97% full. The exceptions:

| Lexeme | Full | Forms |
|---|---|---|
| JBC[ | 41% | 39 |
| JSP[ | 59% | 211 |
| JCB[ | 69% | 51 |

**Parallel passages** (`fig_pey_parallel_passages`):

| | Scroll fuller | MT fuller | Both full | Both defective |
|---|---|---|---|---|
| Non-QSP | 7 | 22 | 166 | 4 |
| QSP | 7 | 3 | 172 | 4 |

*Recounted 2026-11-05: forms paired by their position in the raw text when the scroll and the MT have
the same number of forms of the lexeme in the verse (`parallel_forms(occ = raw_occurrences(...))`).*

Unlike the infinitives, the MT is here more often fuller than the non-QSP scroll.

## Method

- **Model:** Bayesian logistic regression (brms, Bernoulli logit).
- **Random part:** nested, `(1 | scr_book2/lex)`.
- **Priors:** normal(0, 2.5) on intercept and coefficients; exponential(1) on the standard deviations. Prior sensitivity: the final model was refitted with sd 1.5 and 4. No Bayes factors (they are unreliable for models with many random intercepts).
- **Effect summaries:** log-odds (odds ratios in the figures), median with 66% and 95% quantile intervals and pd, as in all verb forms. Predicted probabilities for a typical book and lexeme (population level).
- **Candidate models:**

| Model | Fixed effects |
|---|---|
| M0 | none |
| M1 | tense |
| M2 | tense + stem |
| M3 | M2 + original yod verb |
| M4a | M3 + corpus (MT / non-QSP / QSP) |
| M4b | M3 + corpus group (MT split by group of books; non-QSP; QSP) |
| M5 | M4b + tense × original yod verb |
| n10 | tense × original yod verb (old final model) |
| M1s | M1 + suffix or ending (`has_suffix`; check model) |
| M1p | M1 + prefix (`has_prefix`; check model) |

- **Model comparison:** grouped 5-fold cross-validation, with whole scroll-books left out per fold.
- **Rules for the final model** (author, 2026-10-10; `analysis/README.md`):
  1. Credible effect = 95% interval excludes 0.
  2. A factor stays in if at least one level is credible.
  3. A credible effect goes in, unless (i) it rests on one or a few lexemes, or (ii) it is a proxy for another variable.
  4. If a credible effect brings no gain in the cross-validation, the report discusses it.

## Model comparison

**Grouped 5-fold cross-validation** (elpd = expected log predictive density; higher is better):

| Model | elpd difference to best | SE |
|---|---|---|
| n10 | 0 | — |
| M5 | −0.2 | 5.6 |
| M4a | −8.9 | 4.9 |
| M4b | −11.8 | 6.3 |
| M3 | −13.8 | 3.4 |
| M1p | −15.3 | 5.5 |
| M2 | −16.3 | 4.9 |
| **M1** | −16.6 | 5.2 |
| M1s | −26.2 | 6.7 |
| M0 | −80.1 | 11.1 |

**Final model: M1 (tense only).** How the rules apply to each effect:

| Effect | Assessment | Direct comparison (elpd, SE) |
|---|---|---|
| Tense | credible, clear gain in prediction | M1 vs M0: +63.5 (10.3) |
| Stem | not credible, no gain | M2 vs M1: +0.3 (1.6) |
| Corpus | not credible, no clear gain | M4a vs M3: +4.9 (3.7) |
| Groups of books in the MT | not credible; worse than corpus alone | M4b vs M4a: −2.9 (3.6) |
| Original yod verb | credible in M4a, but excluded under rule 3(i) | — |
| Prefix | not credible, no clear gain; proxy for the wayyiqtol | M1p vs M1: +1.3 (1.7) |
| Suffix or ending | credible, but a clear loss in prediction | M1s vs M1: −9.6 (3.3) |

**Why the original yod verb is left out.** The cross-validation clearly prefers n10 (tense × original yod verb) over M1: +16.6 elpd (SE 5.2). Splitting that gain by lexeme shows where it comes from:

| Source | elpd gain |
|---|---|
| JBC[ (39 forms) | 16.5 |
| the other yod verbs | −0.5 |
| the waw verbs | +0.6 |

So the fuller model predicts better only because it handles JBC[ better. It is a lexeme effect, not a rule for the original yod verbs: without JSP[ and JBC[ the yod-verb effect is not credible (−0.56, −1.44 to 0.41). In the nested random part JBC[ has its own intercept in every book, but that can't carry over to a left-out book. That's why a fixed term for "yod verb" improves the cross-validation.

## Final model M1

**Predicted probability of full spelling** for a typical book and lexeme (`fig_pey_predicted`):

| Tense | Median | 95% interval |
|---|---|---|
| Perfect | 96.1% | 93.4–97.9% |
| Imperfect | 95.0% | 91.9–97.1% |
| **Wayyiqtol** | **77.7%** | **67.2–86.3%** |
| Imperative | 98.9% | 97.2–99.6% |
| Infinitive construct | 93.7% | 87.9–96.9% |
| Infinitive absolute | 98.6% | 93.0–99.9% |
| Participle | 97.9% | 95.9–99.1% |

**Effects vs the perfect** (log-odds, median and 95% interval, pd;
`fig_pey_effects`, `table_pey_effects`):

| Effect | Estimate | pd | Assessment |
|---|---|---|---|
| Wayyiqtol | −1.95 (−2.53 to −1.44) | 1.00 | clearly less full |
| Imperative | 1.29 (0.35 to 2.34) | 0.997 | fuller |
| Participle | 0.65 (−0.03 to 1.37) | 0.97 | probably fuller, just not credible |
| Imperfect | −0.27 (−0.80 to 0.25) | 0.84 | no difference |
| Infinitive construct | −0.51 (−1.24 to 0.23) | 0.92 | no difference |
| Infinitive absolute | 1.05 (−0.69 to 3.49) | 0.88 | no difference |

Tense brings a clear gain in the k-fold (M1 vs M0 +63.5, SE 10.3), so rule 4
does not apply.

## Effects not in the final model

`fig_pey_effects_not_in_final_model`, `table_pey_effects_not_in_final_model`; log-odds, median with 95% interval, and pd (the posterior probability that the effect has the sign of its estimate). Since the refit (2026-10-17) the **MT Pentateuch** is the reference level of M4b, as in all verb forms, so its corpus groups are the coefficients themselves.

| Effect | Estimate | pd | Model |
|---|---|---|---|
| Niphal vs hiphil | 0.46 (−0.35 to 1.31) | 0.86 | M4a |
| Hophal vs hiphil | 0.42 (−0.85 to 1.88) | 0.73 | M4a |
| Original yod verb vs waw verb | −0.94 (−1.77 to −0.10) | 0.985 | M4a |
| Original yod verb, without JSP[ and JBC[ | −0.56 (−1.44 to 0.41) | 0.88 | robustness fit of M4b |
| Non-QSP scrolls vs MT | 0.10 (−0.71 to 0.96) | 0.60 | M4a |
| QSP scrolls vs MT | 0.91 (−0.23 to 2.12) | 0.94 | M4a |
| MT Former Prophets vs MT Pentateuch | −0.78 (−2.13 to 0.61) | 0.87 | M4b |
| MT LBH vs MT Pentateuch | −0.79 (−2.27 to 0.67) | 0.86 | M4b |
| MT other books vs MT Pentateuch | −0.16 (−1.25 to 1.00) | 0.61 | M4b |
| Non-QSP scrolls vs MT Pentateuch | −0.21 (−1.31 to 0.99) | 0.64 | M4b |
| QSP scrolls vs MT Pentateuch | 0.63 (−0.77 to 2.05) | 0.81 | M4b |
| 1QIsaa I vs MT Pentateuch | −0.20 (−2.31 to 1.90) | 0.58 | M4b, 1QIsaa split |
| 1QIsaa II vs MT Pentateuch | 1.99 (−0.37 to 4.67) | 0.95 | M4b, 1QIsaa split |
| Other QSP scrolls vs MT Pentateuch | 0.38 (−1.21 to 2.13) | 0.68 | M4b, 1QIsaa split |
| Suffix or ending (vs none) | −0.73 (−1.19 to −0.28) | 1.00 | M1s |
| Prefix (vs none) | −0.38 (−0.85 to 0.10) | 0.94 | M1p |

- **Stem:** no credible difference. The higher share of full spellings in the niphal (95%) comes from its tenses: the niphal occurs only as perfect and participle.
- **Original yod verb:** credible in M4a, but it rests on JBC[; see Model comparison.
- **Corpus:** no credible effect. There is at most a weak, uncertain indication that the QSP scrolls are somewhat fuller (pd 0.94), and among them 1QIsaa II. The MT is already 85% full (about 90% without the wayyiqtol), so there is little room for the scrolls to be fuller.
- **Groups of books in the MT:** no credible difference from the MT Pentateuch once tense is taken into account (M4b; all pd ≤ 0.87).
- **Prefix:** not credible (pd 0.94) and no clear k-fold gain (+1.3, SE 1.7). The prefix ו is also a proxy for the wayyiqtol (rule 3(ii)).
- **Suffix or ending:** credible in M1s (odds ratio 0.48), but M1s predicts new books clearly worse than M1 (−9.6 elpd, SE 3.3); it is the second-worst model. The raw shares show no difference (with suffix 87%, n 626; without 86%, n 1,622). Within lexemes the suffixed forms are on average about 3 points less full, mostly JDH[ (80% vs 97%), JRH[, JKX[ and JR>[. The effect is a contrast within book×lexeme groups that does not carry over to new books, so it is no general rule for these verbs. The author kept M1 (2026-10-18): rule 1 also asks that the cross-validation does not argue against an effect, and here it clearly does.

## Robustness

Prior sensitivity and robustness of the tense effects (`fig_pey_robustness`,
`table_pey_sensitivity_robustness`):
- **The tense effects hardly change** with prior sd 1.5, 2.5 or 4: wayyiqtol −1.92, −1.95, −1.97; imperative 1.21, 1.29, 1.32.
- **Without JSP[ and JBC[** the wayyiqtol effect is −2.13 (−2.72 to −1.56), so the low fullness of the wayyiqtol isn't due to ויסף alone.
- The imperative stays credible without JSP[ and JBC[: 1.12 (0.19 to 2.16).
- Robustness of the effects not in the final model (yod verb without JSP[ and JBC[; the halves of 1QIsaa): see the previous section.

## Model checks (final model M1)

- **Convergence:** max Rhat 1.003, no divergent transitions, minimum bulk ESS / draws 0.12. All 16 refitted models: max Rhat ≤ 1.006, no divergences.
- **LOO** (not used for model choice): 1 observation with Pareto k > 0.7.
- **Fit:** the observed share of full spellings lies within the model's predictive interval for all groups of books, all tenses, and for JSP[ and JBC[ (`check_pey_ppc_groups`, `check_pey_ppc_tenses`, `check_pey_ppc_lexemes`). JBC[: 41% observed, 53% predicted (95% interval 38–67%).
- **Bayes R²:** 0.40 (95% interval 0.35–0.44).

## Comparison with the book

- The book's final model (model 10) is tense x original yod verb; it is
  refitted here as n10 with the nested random part and the priors of the
  other verb forms.
- n10 predicts best in the k-fold (+16.6 elpd over M1, SE 5.2), but the gain
  comes from JBC[ (16.5), so the yod-verb effect and its interaction with
  tense are treated as a lexeme effect and left out (rule 3(i)). The book's
  statement about the original yod verbs should be revised accordingly
  (see Points for the author, 1).
- The wayyiqtol effect is the same in both models.
- The refitted n10 has not been compared coefficient by coefficient with the
  table in the book.

## Figures and tables

All figures are in `niph_hiph_pe_yod/figures/`, as PNG at 600 dpi and as PDF.

| Book figure | Content |
|---|---|
| `fig_pey_tenses` | full spelling per tense, per corpus |
| `fig_pey_wayyiqtol_jsp` | wayyiqtol of JSP[ vs other verbs |
| `fig_pey_stems_yod` | stems, original yod vs waw verbs |
| `fig_pey_lexemes` | lexemes with 20 forms or more |
| `fig_pey_groups` | groups of books, with and without the wayyiqtol |
| `fig_pey_parallel_passages` | the same form in the MT and a scroll |
| `fig_pey_predicted` | predicted probability per tense (final model) |
| `fig_pey_effects` | tense effects as odds ratios (final model) |
| `fig_pey_robustness` | prior sensitivity and robustness of the tense effects |
| `fig_pey_effects_not_in_final_model` | stem, yod verb, corpus, suffix and prefix from the comparison models |

| Table (CSV) | Content |
|---|---|
| `table_pey_fixed_effects` | fixed effects of M1 with pd |
| `table_pey_effects` | tense effects |
| `table_pey_predicted` | predicted probabilities |
| `table_pey_kfold` | k-fold model comparison |
| `table_pey_sensitivity_robustness` | prior sensitivity and robustness |
| `table_pey_effects_not_in_final_model` | effects not in the final model |
| `table_pey_lexemes` | shares per lexeme |
| `table_pey_affixes` | prefixes and suffixes |
| `table_pey_parallel_passages` | all parallel forms |

## Points for the author

1. **Original yod verbs:** do you agree with leaving them out of the final model and presenting them as a JBC[ effect, given the possible analysis of HBJC as BWC[?
2. **Non-QSP scrolls:** in the parallel passages they are less often full than the MT (22 vs 7), unlike the infinitives. Is this worth a remark?
3. Please check the figures `fig_pey_predicted`, `fig_pey_effects`, `fig_pey_robustness` and `fig_pey_effects_not_in_final_model`.
