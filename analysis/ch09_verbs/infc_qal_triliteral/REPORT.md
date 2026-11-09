# Qal infinitive construct of triliteral verbs — analysis report

*2026-10-09, harmonised 2026-10-17, refitted 2026-10-18. Script: `infc_qal_triliteral/analysis.R`. Figures and tables:
`infc_qal_triliteral/figures/`. **Status: reviewed and accepted by the author (2026-10-09); report
restructured and Bayes factors removed on 2026-10-17 (`TODO.md` section 13); refitted with the MT
Pentateuch as reference level (`infc2_*`, warmup 1000 / iter 3000) on 2026-10-18. The contrasts with
the MT Pentateuch shrank in the refit; the author accepted the refit as it is, with the prior
dependence as a caveat (2026-10-18).***

## Summary

- **QSP scrolls** spell the infinitive construct far more fully than every part of the MT: about
  4,300 times the odds of the MT Pentateuch (log-odds 8.4, 95% interval 6.2 to 10.5). Predicted:
  97.5% full for a typical book and lexeme.
- **Within the MT** the Pentateuch is the most defective (0.9% predicted) and LBH the fullest (19%;
  odds ratio 24 against the Pentateuch, 95% interval 2.1–230, pd 0.993). The Former Prophets
  (pd 0.77) and the other books (pd 0.92) are not credibly fuller than the Pentateuch.
- **Non-QSP scrolls** are probably fuller than the MT Pentateuch (odds ratio 4.7, 0.5–29, pd 0.92),
  but not credibly; they are credibly fuller without le'mor (pd 0.995) or with prior sd 4.
- **le'mor** (>MR[, half the data) needs no effect of its own: the nested random part reproduces it
  (almost always defective in the MT, always full in QSP).
- **Gutturals** and the book's split of the non-QSP scrolls by group of books bring nothing (k-fold
  −10.0 and −12.0).
- **The contrasts with the MT Pentateuch depend on the prior:** with prior sd 1.5 only QSP is
  credible, with sd 4 every group except the Former Prophets. QSP is robust in every variant.
  1QIsaa I is fuller than the Pentateuch only as a tendency (pd 0.93), 1QIsaa II credibly (pd 0.992).

## Descriptive results

- **Dataset:** `infc_qal_triliteral.csv` (data folder version of 2026-10-08), 2,186 forms of the qal infinitive construct of triliteral verbs.
  - 1,826 MT forms, 206 from non-QSP scrolls, 154 from QSP scrolls; no SP forms.
  - 197 lexemes in 138 scroll-books.
- **Outcome:** full (e.g. >MWR) vs defective (>MR) spelling. 16% of all forms are full.
- **le'mor (>MR[) is half the data:** 1,111 forms.
  - MT: 3 of 946 full.
  - Non-QSP scrolls: 21% full.
  - QSP scrolls: 51 of 51 full.

  By the author's decision it stays in the data as an ordinary lexeme, without a separate effect.
- **Prefix:** 95% of the forms have a prefix, mostly ל, so prefix was not modelled. A descriptive table is `table_infc_prefixes`.
- **Suffix:** suffixed infinitives are not in the dataset (3 forms with a suffix).

**Share of full spellings per group of books** (`fig_infc_groups`):

| Group of books | MT | Non-QSP | QSP |
|---|---|---|---|
| Pentateuch | 1% | 20% | 97% |
| Former Prophets | 5% | 43% | 100% (n = 2) |
| LBH | 27% | 0% (n = 2) | — |
| Other books | 13% | 21% | 86% |

In the MT the group of books matters; in the scrolls it hardly does.

**QSP and 1QIsaa** (`fig_infc_qsp_isaiah`): 1QIsaa I 74% full, 1QIsaa II 98%.

**Parallel passages** (`fig_infc_parallel_passages`):

| | Scroll fuller | MT fuller | Both full | Both defective |
|---|---|---|---|---|
| Non-QSP | 32 | 3 | 9 | 151 |
| QSP | 115 | 0 | 10 | 17 |

*Corrected 2026-10-09: when a verse contains several forms of the same lexeme, the n-th scroll form is now paired with the n-th MT form (previously all were paired with the first MT form). This changed one to three forms per corpus; the conclusions are unchanged.*

**Verb classes and gutturals** (`fig_infc_explore_verb_classes`, `fig_infc_explore_gutturals`): descriptive; gutturals were tested in M3.

## Method

- **Research questions:**
  1. Do the QSP and non-QSP scrolls spell the infinitive construct more fully than the MT?
  2. Within the MT: do the groups of books differ?
  3. How does le'mor behave?
- **Model:** Bayesian logistic regression (brms, Bernoulli logit).
- **Random part:** nested, `(1 | scr_book2/lex)`. This gives le'mor its own intercept in every scroll-book.
- **Priors:**
  - normal(0, 2.5) on intercept and coefficients;
  - exponential(1) on the standard deviations of the random intercepts.

  A prior predictive check shows that the prior covers the full range of 0–100% full spellings. Prior sensitivity: M2 refitted with sd 1.5 and 4.
- **Corpus group** (`corpus_group`, 6 levels): MT Pentateuch, MT Former Prophets, MT LBH, MT other books, non-QSP scrolls, QSP scrolls. The groups of books are split only within the MT, because in the scrolls they hardly matter (table above); non-QSP is one group.
- **Reference level:** MT Pentateuch (refit 2026-10-18), as in every verb form. Because the MT Pentateuch is almost always defective, the contrasts with it are large (4–11 log-odds), and the normal(0, 2.5) prior on the coefficients shrinks them noticeably (see Model comparison and Robustness).
- **Candidate models:**

| Model | Fixed effects |
|---|---|
| M0 | none (null model) |
| M1 | corpus (MT / non-QSP / QSP) |
| M2 | corpus group (6 levels) |
| M3 | corpus group + guttural or ר as 2nd or 3rd radical |
| n1 | `law_phase3`, the book's model; also splits the non-QSP scrolls by group of books |

- **Model comparison:** grouped 5-fold cross-validation, with whole scroll-books left out per fold. No Bayes factors (author, 2026-10-14; bridge sampling was unreliable for these models).
- **Effects:** median with 66% and 95% quantile intervals and pd (probability of direction: the posterior probability that the effect has the sign of its estimate), shown as odds ratios.
- **Robustness:**
  - 1QIsaa I, 1QIsaa II and the other QSP scrolls separately;
  - the model without 1QIsaa;
  - the model without le'mor;
  - prior sensitivity: M2 with prior sd 1.5 and 4.

## Model comparison

**Grouped 5-fold cross-validation** (elpd = expected log predictive density; higher is better):

| Model | elpd difference to best | SE |
|---|---|---|
| **M2** corpus group | 0 | — |
| M3 + guttural | −10.0 | 1.1 |
| n1 `law_phase3` | −12.0 | 1.9 |
| M1 corpus | −45.1 | 4.8 |
| M0 null | −325.3 | 17.2 |

**Final model: M2.** It predicts best:
- **Groups of books in the MT:** splitting them is essential. Without the split (M1) the predictions are much worse.
- **Groups of books in the scrolls:** splitting the non-QSP scrolls as well (n1) makes the predictions worse.
- **Gutturals** don't improve the model.

M2 has a single effect (corpus group); the model without it is M0 (−325.3), so the drop-one comparison of rule 4 is the M0 row: the effect brings a very large gain.

**The reference level changed the fit.** With the earlier reference level (MT other books) the same model M2 predicted clearly better: +51.6 elpd (SE 3.9), pointwise on the same folds; M3 likewise (+54.5, SE 4.0). M0, M1 and n1, which already had the MT Pentateuch as reference, are unchanged. With MT other books as reference the contrasts were small (−4 to +7) and the prior hardly constrained them; with the Pentateuch as reference they are 4–11 log-odds, and the prior sd 2.5 shrinks them. The order of the models does not change, but M2's lead over n1 and M1 shrinks (from 64 and 96 to 12 and 45 elpd). The author accepted these results with this caveat (2026-10-18).

## Final model M2

**Effects in the final model, against the MT Pentateuch** (`fig_infc_effects`, `table_infc_effects`, `table_infc_fixed_effects`; the coefficients of the model are these contrasts):

| Group | Log-odds (95% interval) | Odds ratio | pd |
|---|---|---|---|
| MT Former Prophets | 0.89 (−1.60 to 3.05) | ≈ 2.4 | 0.77 |
| MT LBH | 3.18 (0.73 to 5.43) | ≈ 24 | 0.993 |
| MT other books | 1.49 (−0.65 to 3.38) | ≈ 4.4 | 0.92 |
| Non-QSP scrolls | 1.55 (−0.67 to 3.37) | ≈ 4.7 | 0.92 |
| QSP scrolls | 8.36 (6.19 to 10.51) | ≈ 4,300 | 1.00 |

QSP and MT LBH are credibly fuller than the MT Pentateuch, which is almost always defective (1% observed). For the other groups the direction is the same, but not credible. The intercept (MT Pentateuch) is −4.65 log-odds (95% interval −6.30 to −2.90).

**Predicted probability of full spelling** for a *typical* book and lexeme (`fig_infc_predicted`):

| Group | Median | 95% interval |
|---|---|---|
| MT Pentateuch | 0.9% | 0.2–5.2% |
| MT Former Prophets | 2.2% | 0.3–13% |
| MT LBH | 19% | 3.5–56% |
| MT other books | 4.1% | 1.1–11% |
| Non-QSP scrolls | 4.2% | 1.3–10% |
| QSP scrolls | 97.5% | 90.5–99.6% |

These are lower than the observed shares (e.g. MT other books: 13% observed). The lexemes differ strongly (large lexeme variance), and a few frequent, fuller lexemes raise the average over all forms. The model reproduces the observed shares per group when the lexemes are included (see Model checks).

**The non-QSP scrolls.** They are about as full as the MT other books (predicted 4.2% vs 4.1%) and probably fuller than the MT Pentateuch (odds ratio 4.7, pd 0.92; credible without le'mor). Most non-QSP forms come from Pentateuch scrolls (106 of 206), which are far fuller than the MT Pentateuch (20% vs 1%). The parallel passages show the same: where a non-QSP scroll and the MT contain the same form, the scroll is fuller in 32 cases and the MT in 3. Whether the non-QSP scrolls count as "fuller than the MT" therefore depends on which part of the MT they are compared with.

## Effects not in the final model

No credible effect (`fig_infc_effects_not_in_final_model`, `table_infc_effects_not_in_final_model`; log-odds, 95% interval, pd):

| Effect (model) | Estimate | pd |
|---|---|---|
| Guttural or ר as 2nd/3rd radical (M3) | 0.16 (−0.53 to 0.87) | 0.67 |
| Non-QSP Pentateuch vs MT Pentateuch (n1) | 0.92 (−1.34 to 2.84) | 0.80 |
| Non-QSP Former Prophets vs MT Pentateuch (n1) | 1.60 (−1.53 to 4.33) | 0.86 |
| Non-QSP LBH vs MT Pentateuch (n1; 2 forms) | −0.66 (−5.18 to 3.55) | 0.61 |
| Non-QSP other books vs MT Pentateuch (n1) | 1.51 (−0.77 to 3.55) | 0.91 |

n1 now estimates the MT groups much like M2 (MT other books vs MT Pentateuch: 1.23 in n1, 1.49 in M2; Pentateuch level −4.46 vs −4.65) and predicts worse (k-fold −12.0, SE 1.9). Splitting the 206 non-QSP forms into four groups leaves each with few forms and books; none is credible on its own, and as one group (M2) the non-QSP scrolls are not credible either (pd 0.92).

## Robustness

Every corpus group against the MT Pentateuch in M2 and its variants (`fig_infc_robustness`, `table_infc_robustness`; log-odds, 95% interval):

| Variant | QSP | Non-QSP | MT LBH | MT other books |
|---|---|---|---|---|
| M2 (final) | 8.4 (6.2 to 10.5) | 1.6 (−0.7 to 3.4) | 3.2 (0.7 to 5.4) | 1.5 (−0.7 to 3.4) |
| without 1QIsaa | 8.6 (6.4 to 10.9) | 1.7 (−0.4 to 3.5) | 3.3 (1.0 to 5.5) | 1.7 (−0.4 to 3.5) |
| without le'mor | 6.7 (4.9 to 8.7) | 2.3 (0.5 to 3.9) | 3.4 (1.4 to 5.2) | 2.1 (0.4 to 3.6) |
| 1QIsaa split (other QSP) | 7.7 (5.3 to 10.1) | 0.3 (−1.9 to 2.3) | 2.2 (−0.5 to 4.6) | 0.4 (−1.9 to 2.4) |
| prior sd 1.5 | 6.0 (4.2 to 7.7) | 0.0 (−1.7 to 1.6) | 1.5 (−0.6 to 3.4) | 0.1 (−1.6 to 1.7) |
| prior sd 4 | 10.4 (7.8 to 13.2) | 3.0 (0.6 to 5.1) | 4.8 (2.2 to 7.5) | 3.0 (0.6 to 5.2) |

In the 1QIsaa split: 1QIsaa I 2.7 (−1.0 to 6.1), pd 0.93; 1QIsaa II 5.0 (0.9 to 8.8), pd 0.992; other QSP scrolls 7.7 (5.3 to 10.1). MT Former Prophets: 0.9 (−1.6 to 3.1) in M2, −0.1 with prior sd 1.5, 2.2 (pd 0.945) with sd 4: not credible in any variant. The split fit adds one more contrast with the Pentateuch and shifts every MT contrast down (LBH not credible there, pd 0.948): another sign that the Pentateuch level depends on the prior.

- **The QSP effect is very large and robust.** le'mor (51 of 51 full in QSP) makes it larger, but without le'mor it is still very large.
- **1QIsaa I** is probably fuller than the MT Pentateuch (pd 0.93), but clearly less full than 1QIsaa II and the other QSP scrolls (74% vs 98% observed).
- **Without le'mor** the non-QSP scrolls and the MT other books are credibly fuller than the MT Pentateuch (pd 0.995 and 0.990).
- **Prior sensitivity:** only the QSP effect is credible under all three priors. MT LBH is credible with sd 2.5 and 4, the MT other books and the non-QSP scrolls only with sd 4, the Former Prophets with none. The MT Pentateuch is almost always defective, so its contrasts are 4–11 log-odds and the prior on the coefficients shrinks them; the direction and the order of the groups do not change.

## Model checks

- **Convergence:** max Rhat 1.004, no divergent transitions, minimum bulk ESS / draws 0.21 (all 11 refitted models: max Rhat ≤ 1.004, no divergences).
- **Fit per group of books:** the observed share of full spellings lies within the model's predictive interval for all groups (`check_infc_ppc_groups`).
- **le'mor** (no fixed effect of its own): the model reproduces the share of full spellings for le'mor and for the other verbs in every corpus (`check_infc_ppc_lemor`):
  - MT le'mor: 0.3% observed, 1.0% predicted (95% interval 0.3–2.0%);
  - QSP le'mor: 100% observed, 97% predicted (90–100%).
- **Bayes R²:** 0.67 (95% interval 0.63–0.72).
- **LOO:** 100 observations with Pareto k > 0.7, so LOO is unreliable here; the model comparison uses the grouped k-fold.
- **In-sample classification:** not used as a quality measure (it is inflated by the book×lexeme intercepts).

## Comparison with the book

The book's model corresponds to n1 (`law_phase3`): it splits the non-QSP scrolls by group of books as well as the MT. M2 keeps the split within the MT but treats the non-QSP scrolls as one group, and predicts better (k-fold +12.0, SE 1.9). With the split, none of the non-QSP groups is credibly different from the MT Pentateuch; as one group they are probably fuller (pd 0.92), credibly so without le'mor. The book's statements on the non-QSP scrolls should therefore be based on the single non-QSP group, and worded as a tendency.

## Figures and tables

All figures are in `infc_qal_triliteral/figures/`, as PNG at 600 dpi and as PDF.

| Book figure | Content |
|---|---|
| `fig_infc_groups` | full spelling per group of books, le'mor vs other verbs |
| `fig_infc_qsp_isaiah` | MT Isaiah, 1QIsaa I and II, other QSP scrolls |
| `fig_infc_parallel_passages` | the same form in the MT and a scroll |
| `fig_infc_explore_verb_classes` | verb classes and gutturals |
| `fig_infc_explore_gutturals` | gutturals per corpus |
| `fig_infc_predicted` | predicted probability of full spelling (final model) |
| `fig_infc_effects` | odds ratios vs MT Pentateuch (final model) |
| `fig_infc_effects_not_in_final_model` | guttural (M3) and the non-QSP split (n1) |
| `fig_infc_robustness` | every corpus group vs MT Pentateuch under the robustness checks and prior sensitivity |

| Table (CSV) | Content |
|---|---|
| `table_infc_fixed_effects` | model coefficients (reference MT Pentateuch) with pd |
| `table_infc_effects` | effects vs MT Pentateuch (log-odds, quantile intervals, pd) |
| `table_infc_effects_not_in_final_model` | effects not in the final model |
| `table_infc_predicted` | predicted probabilities |
| `table_infc_kfold` | k-fold model comparison |
| `table_infc_robustness` | robustness checks and prior sensitivity |
| `table_infc_parallel_passages` | all parallel forms |
| `table_infc_prefixes` | prefixes |

The diagnostic figures (`check_infc_*`) cover the prior predictive check, trace and density plots, posterior predictive checks, the le'mor check and the random intercepts.

## Points for the author

- **The refit confirmed the warning of 2026-10-17: the contrasts with the MT Pentateuch shrank**
  (QSP 10.8 → 8.4, LBH 5.8 → 3.2, other books 4.2 → 1.5, non-QSP 4.0 → 1.6, Former Prophets
  3.4 → 0.9 log-odds); only QSP and LBH stay credible. The author accepted the refit as it is, with
  the prior dependence reported as a caveat (2026-10-18). Wording for the book: the QSP scrolls are
  far fuller than every part of the MT; within the MT the Pentateuch is the most defective and LBH
  the fullest; the non-QSP scrolls, the Former Prophets and the other books are probably fuller
  than the Pentateuch, but how much depends on the prior.
- **Author's review point 2 (below)** said that the non-QSP scrolls are fuller than the MT
  Pentateuch. In the refit this is a tendency (pd 0.92), credible only without le'mor or with prior
  sd 4. Should the text say "probably fuller"?
- The caption of `fig_infc_effects_not_in_final_model` still quotes the old values ("log-odds 1.2 in
  n1, 4.2 in M2"); the refit gives 1.23 and 1.49. It is fixed with the next run of section 4.

## Author's review (2026-10-09)

1. M2 is accepted as the final model.
2. Non-QSP scrolls: to be described as above. They are about as full as the MT
   other books, but fuller than the MT Pentateuch (from which most of their
   forms come) and in the parallel passages (32 scroll fuller vs 3 MT fuller).
3. 1QIsaa I being fuller than the MT but less full than 1QIsaa II is in line
   with expectations (for the infinitive absolute it spelled like the MT).
4. The result figures are approved (before the 2026-10-17 change to effects
   vs MT Pentateuch; `fig_infc_effects`, `fig_infc_robustness` and the new
   `fig_infc_effects_not_in_final_model` to be checked again).
