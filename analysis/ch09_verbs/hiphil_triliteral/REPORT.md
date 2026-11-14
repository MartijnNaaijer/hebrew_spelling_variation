# Hiphil of triliteral verbs — analysis report

*Rebuilt 2026-10-15. Script: `hiphil_triliteral/analysis.R`. Figures and
tables: `hiphil_triliteral/figures/`. Model set approved by the author on
2026-10-15. Fits 2026-10-15; k-folds and robustness fits 2026-10-17/18;
drop-one and prior-sensitivity fits of M7 2026-10-18. Final model **M7**
(author, 2026-10-18).*

Intervals: median with 95% quantile interval (66% in the figures), logit
scale unless an odds ratio (OR) is given; pd = probability of direction;
credible = pd ≥ 0.975. Reference levels: MT Pentateuch, imperfect, no suffix.

## Summary

- The triliteral hiphil (forms with hireq) is mostly full everywhere: 88% in
  the MT and 88–93% in the scrolls. In the basic form (imperfect without a
  suffix) the corpus groups do not differ credibly (95–99% predicted).
- The defective spellings that remain are concentrated in two places: the
  **wayyiqtol** and **forms with a suffix**. Both are much more defective in
  the MT Pentateuch and the MT Former Prophets than elsewhere.
- **Wayyiqtol.**
  - Observed: MT Pentateuch 35% full, Former Prophets 40%, against LBH 90%
    and QSP 9/9.
  - The wayyiqtol is credibly more defective than the imperfect in the MT
    Pentateuch, Former Prophets and other books (OR 1/16, 1/28, 1/7), but not
    in MT LBH, non-QSP or QSP.
  - In the wayyiqtol, MT LBH (OR 36) and QSP (OR 54) are credibly fuller
    than the MT Pentateuch.
- **Suffix.**
  - A suffix lowers fullness strongly in the MT Pentateuch, Former Prophets
    and LBH (OR 1/10, 1/14, 1/8), less in the MT other books (1/3), and not
    credibly in the scrolls.
  - With a suffix, MT other books and non-QSP are credibly fuller than the
    MT Pentateuch (OR about 5). The QSP difference (pd 0.96) rests on
    1QIsaa.
- **Other tenses.** The perfect is fuller than the imperfect in all groups
  except QSP. The imperative and the inf. construct are fuller in some
  groups. The participle does not differ credibly from the imperfect.
- **The k-fold.** Tense (+121 elpd) and suffix (+45) carry most of the
  predictive information. The corpus groups give a moderate gain over the
  book's model without corpus (+12.0, SE 13.0, against M7). The interactions
  are credible and robust but do not predict new books better (rule 4).
- The book's conclusion of **no document-group effect has to be revised**
  (see the comparison with the book).

## Descriptive results

`table_hif_groups.csv`, `_tenses`, `_suffix`, `_suffix_types`, `_prefix`,
`_first_letter`, `_lexemes`, `_parallel_passages`:

| Corpus group | n | full | without / with suffix | wayyiqtol |
|---|---|---|---|---|
| MT Pentateuch | 585 | 86% | 92% / 69% | 19/54 (35%) |
| MT Former Prophets | 529 | 78% | 82% / 59% | 50/124 (40%) |
| MT LBH | 373 | 94% | 98% / 82% | 78/87 (90%) |
| MT other books | 1313 | 91% | 94% / 83% | 47/75 (63%) |
| Non-QSP | 319 | 88% | 89% / 85% | 18/26 (69%) |
| QSP | 318 | 93% | 94% / 89% | 9/9 |

- **Data.** 3437 forms with hireq (2800 MT, 319 non-QSP, 318 QSP), 398
  defective. The 602 forms without a hireq (mostly wayyiqtol, imperative and
  imperfect with sere) are only tabulated. 4Q82 Amos 8:5 נשבים is excluded
  (a completely different reading).
- **Exclusion fixed (2026-10-19).** Until 2026-10-19 the script excluded the
  form by an outdated `tf_id`, which now belongs to 4Q82 Amos 4:7 אמטיר (full).
  So Amos 4:7 was left out and Amos 8:5 (defective) was in. The descriptive
  tables now use the correct selection. The stored fits (M0–M7, n9v2, the
  robustness and prior fits, all k-folds) still have the old selection; they
  were not refitted (author, 2026-10-19): two of 3437 forms, one QSP scroll.
- **Data version.** The descriptive tables use the data of 2026-10-19
  (preprocessing commit `1297334`), in which 1QIsaa Isa 38:16 תחלימני has
  the lexeme XLM=[ (be healthy) instead of XLM[ (dream), as in the BHSA. The
  models were fitted on the earlier data and not refitted: this form is the
  only one of either lexeme in 1QIsaa, so its book × lexeme group only
  changes its label. The correction makes the form match its MT parallel
  (QSP both full 282 → 283).
- **Suffix types.**
  - MT pronominal suffix 78% full (553 forms), masc. pl. -JM 51% (57,
    participles), paragogic nun 59% (22). The other nominal endings are
    nearly always full.
  - Paragogic nun: 34 forms, 22 MT and 12 in the scrolls (7 of 12 full).
    In the scroll data the paragogic nun has `has_prs = 1`; before
    2026-10-19 the suffix-type table counted these 12 forms as pronominal
    suffixes ("22, all MT" was wrong). `has_suffix` was always 1 for them.
  - `has_suffix` includes the paragogic nun, as in the book.
- **Prefix.** Outside the wayyiqtol there is no difference in the MT and
  non-QSP. QSP is lower with a prefix (86% vs 96%), mainly W + imperfect; 11
  of the 14 defective forms are from 1QIsaa. The MT W + imperfect is also
  lower (78%), probably short (jussive) forms. Not modelled: the prefix is a
  proxy for the wayyiqtol (rule 3(ii)).
- **First letter.** MT imperfect J- 85% vs T- 91%. Not modelled (proxy for
  person and tense).
- **Verb classes.** I-nun 90% vs 88% for the others. There are no ayin-ayin
  or III-he verbs, and I-yod is one lexeme. Not modelled.
- **Parallel passages.** Paired by `mt_match`, the MT form matched in the
  preprocessing (`parallel_forms_matched()`, 2026-10-19). The positional
  pairing used before misaligned 4Q76 and 4Q81 at Jon 1:7 and Mur88 at Mic
  2:6. The scrolls are not fuller than the MT: non-QSP 19 MT-fuller vs 18
  scroll-fuller (262 both full, 20 both defective; as the book's Table
  9.54); QSP 13 vs 13 (284 both full, 8 both defective). The new
  scroll-fuller QSP case is 1QIsaa Isa 37:10 (ישייכה, MT ישאך).
- **Lexemes.** No single lexeme dominates: NGD[ 280, NYL[ 196, QRB[ 162
  forms, all 90–95% full.

## Method

- Bernoulli (logit) models in brms with nested random intercepts
  `(1 | scr_book2/lex)`.
- `corpus_group`: MT Pentateuch (reference), MT Former Prophets, MT LBH, MT
  other books, non-QSP, QSP.
- `vt` has the imperfect as reference. `has_suffix` follows the book
  (pronominal suffix, nominal ending, paragogic nun).
- Priors: normal(0, 2.5) on the intercept and coefficients, exponential(1)
  on the SDs. The prior predictive check (`check_hif_prior_predictive`)
  covers the whole range.
- Sampler: 4 chains, adapt_delta 0.99. The model set (fitted 2026-10-15)
  uses warmup 2000 / 6000 iterations (16000 draws). The robustness,
  drop-one and prior fits use 1000 / 3000 (8000 draws). Under TODO 13.10
  the old fits were not refitted for this alone.
- Grouped 5-fold k-fold: every scroll-book is left out as a whole. No Bayes
  factors.
- Final model chosen by the credible-effects rules (`analysis/README.md`).

## Model comparison

`table_hif_kfold.csv`. All formulas include `(1 | scr_book2/lex)`.

| Model | Fixed part | elpd diff | SE |
|---|---|---|---|
| **M4** | corpus_group + vt + has_suffix | 0 | – |
| M5 | M4 + corpus_group × has_suffix | −1.5 | 5.0 |
| **M7** | corpus_group × vt + corpus_group × has_suffix | −1.7 | 7.9 |
| M6 | M4 + corpus_group × vt | −2.8 | 6.6 |
| n9v2 | vt + has_suffix (the book's model) | −13.7 | 9.7 |
| M3 | corpus_group + vt | −41.6 | 9.1 |
| M7_no_suffix | corpus_group × vt | −46.5 | 11.5 |
| M7_no_vt | corpus_group × has_suffix | −123.0 | 16.0 |
| M2 | corpus_group | −178.0 | 17.3 |
| M0 | null | −193.9 | 21.9 |
| M1 | corpus (MT / non-QSP / QSP) | −200.6 | 21.5 |

- All fits converged: max Rhat ≤ 1.005, bulk ESS ≥ 0.14 × draws, no
  divergent transitions.
- Most of the gain comes from the tense (M2 → M3, +136) and the suffix
  (M3 → M4, +42).
- The corpus groups give a moderate gain over the book's n9v2 (M4 vs n9v2
  +13.7, SE 9.7). The three-level corpus (M1) gives none: the MT groups
  differ more from each other than the scrolls differ from the MT.
- The interactions (M5–M7) bring no gain: M4, M5, M6 and M7 are within
  0.4 SE of each other.

### Drop-one comparison for M7 (rule 4)

`table_hif_kfold_drop_one.csv` (reduced model minus M7):

| Effect dropped | Model | elpd diff | SE |
|---|---|---|---|
| corpus group × suffix | M6 | −1.1 | 4.8 |
| corpus group × tense | M5 | +0.2 | 6.2 |
| corpus group (with its interactions) | n9v2 | −12.0 | 13.0 |
| tense (with corpus group × tense) | M7_no_vt | −121.2 | 16.9 |
| suffix (with corpus group × suffix) | M7_no_suffix | −44.8 | 9.4 |

Tense and suffix are clearly needed. Corpus group gives a gain of about
1 SE. The two interactions give none (see rule 4 below).

## Final model M7

`has_vowel_letter ~ corpus_group * vt + corpus_group * has_suffix + (1 | scr_book2/lex)`

Figures and tables: `fig_hif_effects` / `table_hif_effects.csv` (total
effects per corpus group), `fig_hif_predicted` / `table_hif_predicted.csv`,
`table_hif_fixed_effects.csv` (coefficients).

**Why this model (rules 1–3).**

- Both interactions have credible levels in M7: MT other books × suffix
  +1.13 [0.20, 2.07], non-QSP × suffix +1.75 [0.44, 3.06] and QSP ×
  wayyiqtol +3.75 [0.89, 7.09].
- All three survive without 1QIsaa, without NGD[ and with prior sd 1.5 and
  4 (see Robustness), so they are not lexeme effects (rule 3(i)).
- They are not proxies for another variable in the model (rule 3(ii)).
- M5 would leave out QSP × wayyiqtol and M6 the suffix interactions; M4
  would leave out both. All of them drop robust credible effects.

**Total effects in M7** (main effect + interaction; logit [95%], pd for
non-credible values; credible values in bold):

| Effect | MT Pent. | MT Former Pr. | MT LBH | MT other | Non-QSP | QSP |
|---|---|---|---|---|---|---|
| Group vs MT Pent., imperfect, no suffix | – | 0.18 [−1.36, 1.72] | 1.66 [−0.28, 3.68] .954 | 0.49 [−0.67, 1.72] | −0.15 [−1.39, 1.13] | 0.30 [−1.15, 1.83] |
| Group vs MT Pent., with suffix | – | −0.17 [−1.87, 1.57] | 1.84 [−0.27, 4.02] .955 | **1.62 [0.31, 2.98]** | **1.60 [0.10, 3.15]** | 1.50 [−0.19, 3.26] .960 |
| Group vs MT Pent., wayyiqtol | – | −0.38 [−2.02, 1.22] | **3.58 [1.68, 5.56]** | 1.33 [−0.14, 2.85] .962 | 1.38 [−0.37, 3.22] .938 | **3.98 [0.97, 7.57]** |
| Suffix within group | **−2.27** | **−2.61** | **−2.08** | **−1.15** | −0.53 .83 | −1.07 .95 |
| Wayyiqtol vs imperfect | **−2.78** | **−3.34** | −0.85 .83 | **−1.94** | −1.25 .95 | 0.87 .72 |
| Perfect vs imperfect | **1.63** | **1.61** | **3.41** | **2.09** | **2.10** | 0.89 .87 |
| Imperative vs imperfect | 1.51 .974 | 0.84 .85 | 0.21 .55 | **1.78** | 1.01 .84 | 2.04 .974 |
| Inf. constr. vs imperfect | 0.86 .93 | **1.56** | **3.03** | 0.83 .96 | 0.48 .73 | −0.73 .80 |
| Participle vs imperfect | 0.33 .73 | 0.03 .52 | −1.00 .86 | 0.72 .96 | 0.47 .74 | 0.96 .86 |

**Predicted probability of full spelling** (typical book and lexeme,
`re_formula = NA`; median [95%]):

| Group | impf | impf + suffix | wayq | wayq + suffix |
|---|---|---|---|---|
| MT Pentateuch | 95% [89, 98] | 68% [42, 86] | 56% [29, 81] | 12% [4, 32] |
| MT Former Prophets | 96% [88, 99] | 64% [31, 88] | 46% [21, 74] | 6% [2, 20] |
| MT LBH | 99% [95, 100] | 93% [67, 99] | 98% [91, 100] | 85% [56, 97] |
| MT other books | 97% [94, 99] | 91% [82, 96] | 83% [65, 93] | 61% [37, 81] |
| Non-QSP | 95% [88, 98] | 91% [78, 97] | 84% [56, 96] | 75% [42, 93] |
| QSP | 97% [89, 99] | 91% [72, 98] | 99% [80, 100] | 96% [61, 100] |

- **Corpus groups.**
  - In the imperfect without a suffix, no group differs credibly from the MT
    Pentateuch. MT LBH is the largest difference (+1.66, pd 0.95).
  - The differences lie in the wayyiqtol (MT LBH and QSP credible; MT other
    books and non-QSP pd 0.94–0.96) and in forms with a suffix (MT other
    books and non-QSP credible; QSP and MT LBH pd 0.96).
  - MT Former Prophets does not differ from the Pentateuch anywhere.
- **Wayyiqtol.** Strongly more defective than the imperfect in the older MT
  books and the other books. Predicted wayyiqtol without a suffix: 56% in
  the Pentateuch and 46% in the Former Prophets, against 98% in LBH and 99%
  in QSP.
- **Suffix.** Predicted imperfect with a suffix: 68% in the Pentateuch and
  64% in the Former Prophets, against 91–93% elsewhere.
- **Other tenses.** The perfect is fuller than the imperfect in every group
  except QSP (+1.6 to +3.4). The inf. construct is credibly fuller in the MT
  Former Prophets and LBH, the imperative in the MT other books. The MT LBH
  perfect and inf. construct cells are 100% full, so their interaction terms
  rest partly on the prior.

**The QSP wayyiqtol cell is small:** 9 forms, all full, from 6 lexemes
(<MD[ 3, NGD[ 2) and 6 scroll-books; 5 are left without 1QIsaa. The
interval is wide, so the size of the effect rests on the prior (see
Robustness). Its direction does not: it is not one lexeme or one scroll. The
MT LBH wayyiqtol (87 forms, 78 full, 37 lexemes) is the better-supported
part of the same pattern.

### Credible but no gain in the k-fold (rule 4)

M7 predicts new books as well as the additive M4 (−1.7, SE 7.9). Dropping
either interaction changes the k-fold by less than 1 SE (−1.1 and +0.2).
Corpus group as a whole brings +12.0 (SE 13.0). Reasons:

- **Few forms behind the group-specific terms.** QSP has 9 wayyiqtol forms
  and non-QSP 26. The suffixed forms in the scrolls (95 + 76) are 85–89%
  full, so a QSP or non-QSP form is already well predicted by its group's
  intercept.
- **Whole books are left out.** The MT LBH wayyiqtol comes from 5 books.
  When one is left out, the group-specific term rests on the other four.
- **Large variation between lexemes within books** (SD 1.73, against 0.92
  between books): much of what a new book does is not predictable from the
  fixed effects.

What this means for the conclusion: the interactions describe where the
corpora differ. The older MT books (Pentateuch, Former Prophets) keep
defective spellings in the wayyiqtol and in suffixed forms, while LBH and
the scrolls write the yod there as well. These are real differences in the
data, but the main effects (tense, suffix, corpus group) carry the
predictive information.

## Effects not in the final model

- All modelled effects are in M7. Levels without a credible effect are
  shown with their intervals in `fig_hif_effects` (rule 2), so no
  `fig_hif_effects_not_in_final_model` is made.
- Not modelled (descriptive only): the prefix (proxy for the wayyiqtol,
  rule 3(ii)), the first letter, the verb classes and the suffix types.
- **QSP × suffix** is not credible in M7 (+1.20 [−0.23, 2.64], pd 0.95).
  It is credible in M5 (+1.66), but without 1QIsaa it drops to +0.68 (pd
  0.71): it is a 1QIsaa effect. Of the 76 QSP suffixed forms, 55 are from
  1QIsaa (51 full).

## Robustness

`fig_hif_robustness`, `table_hif_robustness.csv`: M7, M5, M7 without
1QIsaa, M7 without NGD[, and M7 with prior sd 1.5 and 4. Total effects
(logit, pd):

| Effect | M7 | M5 | no 1QIsaa | no NGD[ | sd 1.5 | sd 4 |
|---|---|---|---|---|---|---|
| MT other books vs Pent., with suffix | 1.62 .992 | 1.87 .998 | 1.61 .990 | 1.62 .992 | 1.35 .990 | 1.77 .991 |
| Non-QSP vs Pent., with suffix | 1.60 .982 | 1.86 .997 | 1.55 .979 | 1.56 .980 | 1.34 .977 | 1.74 .980 |
| QSP vs Pent., with suffix | 1.50 .960 | 1.86 .990 | 1.06 .833 | 1.43 .955 | 1.31 .961 | 1.58 .952 |
| MT LBH vs Pent., wayyiqtol | 3.58 1.000 | (2.46)* | 3.53 1.000 | 3.65 1.000 | 3.01 1.000 | 3.95 1.000 |
| QSP vs Pent., wayyiqtol | 3.98 .995 | (0.20)* | 4.05 .986 | 3.83 .993 | 2.54 .985 | 5.59 .999 |
| Suffix in MT other books | −1.15 1.000 | −1.12 1.000 | −1.14 1.000 | −1.03 1.000 | −1.14 1.000 | −1.14 1.000 |
| Suffix in QSP | −1.07 .950 | −0.58 .82 | −1.59 .904 | −0.97 .935 | −1.02 .952 | −1.13 .952 |
| Wayyiqtol in MT Pentateuch | −2.78 1.000 | – | −2.75 1.000 | −2.64 1.000 | −2.44 1.000 | −3.01 1.000 |

\* M5 has no corpus group × tense term; its value is the corpus effect
without a suffix.

- **Without 1QIsaa** (252 of the 318 QSP forms left out): the MT other
  books and non-QSP suffix effects are unchanged. QSP in the wayyiqtol (5
  forms left) is still credible. The QSP suffix difference disappears.
- **Without NGD[** (280 forms): all credible effects stay.
- **Prior sensitivity.** Every credible effect stays credible with sd 1.5
  and 4. The sizes of the effects in thin or all-full cells depend on the
  prior: QSP in the wayyiqtol is +2.5 with sd 1.5 and +5.6 with sd 4 (OR 13
  to 270). The suffix effects in MT other books and non-QSP move little
  (1.3–1.8).
- **Reference level.** Unlike in infc_qal_triliteral, the MT Pentateuch is
  not nearly all defective here (86% full), so the prior on the contrasts
  does not shrink large effects in the basic form.

## Model checks

- **Convergence.** M7: max Rhat 1.002, min bulk ESS/draws 0.166, no
  divergent transitions (`check_hif_trace`, `check_hif_dens`). The drop-one
  fits: max Rhat 1.004, no divergences.
- **Posterior predictive checks** (`check_hif_ppcheck_bars`, `_mean`):
  fine.
- **Groups** (`check_hif_ppc_groups`, `_tenses`, `_lexemes`): the observed
  share lies inside the 95% predictive interval in every corpus group ×
  suffix cell (e.g. MT Pentateuch with suffix 69% observed, 70% predicted),
  in every corpus group × tense cell, including the wayyiqtol gradient and
  the 100% cells (MT LBH perfect and inf. construct, QSP wayyiqtol), and for
  the largest lexemes (NBV[ 100% observed, 96% [91, 100] predicted).
- **Bayes R2** 0.43 [0.37, 0.48].
- **LOO** (for completeness; the k-fold is used for comparison): elpd
  −922.0 (SE 37.2), 9 observations with Pareto k > 0.7 (0.3%).
- **In-sample classification** (full = positive class): accuracy 0.931,
  sensitivity 0.991, specificity 0.469. Defective forms are hard to predict
  because they are rare (12%).
- Book random intercepts: `check_hif_random_books`.

## Comparison with the book (section 9.7, manuscript 2026-09-10)

- **Table 9.57 (9v2: vt + has_suffix).** The refitted n9v2
  (`table_hif_n9v2_fixed_effects.csv`) gives nearly the same values:
  intercept 3.44 (book 3.53), imperative 1.35 (1.42), inf. construct 0.93
  (0.96), perfect 1.78 (1.82), participle 0.28 (0.31), wayyiqtol −2.16
  (−2.20), suffix −1.54 (−1.58). The small differences come from the new
  data (3437 rows; the book has 3431) and the priors.
- **"No credible document-group effect".** This has to be revised:
  - The book chose 9v2 by Bayes factor. In the grouped k-fold the model with
    corpus groups predicts better than 9v2 (M4 +13.7, SE 9.7; M7 +12.0, SE
    13.0), though not by much.
  - In the additive M4, MT LBH (+2.06) and MT other books (+1.10,
    borderline) are credibly fuller than the MT Pentateuch.
  - In M7 the groups differ in the wayyiqtol and with a suffix, not in the
    basic imperfect.
  - The book's statement that the Former Prophets are not credibly more
    defective holds: they never differ from the Pentateuch.
- **The wayyiqtol "archaism".** The book's interpretation (Andersen and
  Forbes: the defective hiphil as an archaism, kept longest in the
  wayyiqtol) is supported and sharpened. The wayyiqtol is defective in the
  MT Pentateuch, Former Prophets and other books, but not in LBH or the QSP
  scrolls.
- **Counts.** The book counts 33 paragogic nun cases (with the query
  "29?"); the current data have 34 (new: Mur88 Mic 2:8). The book's totals
  3431 / 2800 / 319 / 312 differ from the current 3437 / 2800 / 319 / 318
  (six new QSP forms, all full).
- **Parallel passages.** The book's Table 9.54 is correct (19 MT-fuller, 18
  scroll-fuller); its summary text has the two numbers the wrong way round.
  QSP: 13 vs 13 (book 13 vs 12; new: 1QIsaa Isa 37:10). See
  `BOOK_CHANGES_9.7.md`.

## Points for the author

1. **Rule 4 wording:** check the paragraph on why the credible interactions
   bring no k-fold gain.
2. **QSP in the wayyiqtol** (9 forms, all full) is credible in every
   variant, but its size depends on the prior (OR 13–270). Report the
   direction, not the size.
3. **QSP × suffix** rests on 1QIsaa; report it as a 1QIsaa effect.
4. **The book's conclusion** of no document-group effect must change (see
   the comparison with the book), as must the counts and the parallel
   passages.
5. **Mixed sampler settings:** the model set uses 2000/6000, the later
   fits 1000/3000 (acceptable under TODO 13.10).
6. **Still open from TODO section 11:** check the exploratory book figures;
   the Isaiah manuscripts model and the verb frequency model are postponed.
