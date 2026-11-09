# Qal passive participle — analysis report

*2026-10-09. Script: `ptcp_qal/analysis.R`. Figures and tables:
`ptcp_qal/figures/`. Design approved by the author on 2026-10-09; models
fitted 2026-10-10; final model M7 (2026-10-11), chosen under the
credible-effects rules in `../CLAUDE.md`, and kept over S1x after the refit
(author, 2026-10-18). Sections reordered 2026-10-17 (harmonisation,
`../TODO.md` section 13); Bayes factors removed.*

*Refitted 2026-10-17/18 on the data of 2026-10-16 (`nme_type`: 8 MT fem. pl.
written -T, e.g. VL>T in Gen 30:35, are now counted as fem. pl.; 4 scroll
plural constructs, 1QIsaa Isa 28:1, 35:10, 51:11 and 4Q108 Song 3:8, are now
masc. pl.), with the MT Pentateuch as the reference level of `corpus_group`,
warmup 1000 / iter 3000 (8000 draws), files `ptcp_d2_*`. Effects: median,
66%/95% quantile intervals, pd.*

*Refitted 2026-11-04 on the data of 2026-11-03 (hebrew_spelling_variation
37b4f01, DSS segmentation fixes; `../TODO.md` section 24), files
`ptcp_d3_*`; all numbers below are from this refit. 49 scroll forms now have
the fem. sg. ending H, as in the BHSA (e.g. 1QIsaa NVWJH, Isa 5:25; before:
no ending); 4 forms dropped out and 2 came in (1,198 forms). The MT data and
`has_vowel_letter` are unchanged. FINAL_ID M7 confirmed by the author
(2026-11-04).*

## Summary

- Final model **M7**: corpus group + ending (5 levels) + long ending in QSP
  + ע-ע + ל-ה. M7 is also the best model in the grouped k-fold.
- The QSP scrolls differ from the MT only before a long ending (extra odds
  ratio about 31; 95% interval 3.1–320); without an ending every group is
  near 100% full. Without 1QIsaa the extra effect is not credible (9.9,
  0.33–330).
- Groups of books in the MT: only MT LBH is credibly fuller than the MT
  Pentateuch (odds ratio 12, 1.5–92, pd 0.991); the MT other books (2.9,
  pd 0.92) and the Former Prophets (1.6) are not. The differences show only
  before a long ending.
- The non-QSP scrolls are probably somewhat fuller than the MT Pentateuch
  (4.4, 0.97–22, pd 0.972; just not credible), and treat the long endings
  like the MT.
- Endings lower the chance of a full spelling very unequally: masc. pl.
  about 1/35, pronominal suffix 1/410, fem. pl. -WT/-T 1/910; fem. sg.
  hardly (0.55, not credible).
- ל-ה verbs: credible, but only just (4.7, 1.03–26, pd 0.977) and without
  a clear k-fold gain; corpus group likewise without a clear gain (rule 4).
- Not in the model: the non-QSP long ending (not credible) and the prefix
  (rests on PQD[).
- The book's two-value `has_suffix` (S1x) predicts clearly worse than M7
  (−50.7 elpd, SE 8.4).

## Data

- **Dataset:** `ptcp_qal.csv` (data of 2026-11-03), 1,198 forms of the qal
  passive participle after leaving out the Samaritan Pentateuch forms
  (author's decision).
  - 940 MT forms, 114 from non-QSP scrolls, 144 from QSP scrolls.
  - 180 lexemes in 98 scroll-books.
  - Changes against the data of 2026-10-16: out 1Q8 B<WLH (Isa 54:1), 4Q74
    NVWJ (Ezek 1:22), 5Q6 HPWKH (Lam 4:6), Mur1 NVWJH (Exod 6:6); in 4Q84
    NVWJ (Ps 102:12), 4Q139 NVJH (Deut 5:15, defective). These come from the
    reconstruction filter, which now sees the right syllable.
- **Outcome:** full (`has_vowel_letter = 1`, e.g. KTWB) vs defective (KTB).
  79% of the forms are full (247 defective).
- **Unbalanced lexemes:** BRK[ (121 forms, 98% full), KTB[ (117, 92%), PQD[
  (88, 25%), >RR[ (48, 100%), NVH[ (45, 91%), BLL[ (40, 100%).
- **PQD[** supplies 66 of the 247 defective forms, mostly construct plurals in
  Numbers (PQDJ, PQDJHM: MT 14 of 71 full). It stays an ordinary lexeme in
  the model (author's decision); a robustness fit leaves it out.
- **Mostly single-form groups:** 449 of the 618 book×lexeme groups contain one
  form.

**Research questions.**
1. Do the QSP and non-QSP scrolls spell the participle more fully than the MT?
2. Within the MT: do the groups of books differ?
3. How does the ending affect the spelling, and do the scrolls differ from
   the MT in this?
4. Do ayin-ayin (ע-ע) and III-he (ל-ה) verbs behave differently?

## Descriptive results

**Endings** (`fig_ptcp_endings`, `table_ptcp_endings.csv`). The old variable
`has_suffix` lumped pronominal suffixes (70 forms) together with all nominal
endings. The endings behave very differently:

| MT | n | full |
|---|---|---|
| no ending (QTWL) | 411 | 94% |
| fem. sg. -H/-T | 171 | 90% |
| masc. pl. -JM/-J | 252 | 66% |
| fem. pl. -WT/-T | 44 | 25% (written -WT 5 of 36, written -T 6 of 8) |
| pronominal suffix | 62 | 13% (mostly PQD[; without it 7 of 12) |

The QSP scrolls keep the long endings full (masc. pl. 28/30, fem. pl. 6/7,
suffix 3/3); the non-QSP scrolls behave like the MT (masc. pl. 20/31, fem. pl.
1/6, suffix 2/5). With the data of 2026-11-03 the scrolls have fem. sg.
forms like the MT (non-QSP 22 of 22 full, QSP 28 of 31); before, almost all
of them were counted as forms without an ending (non-QSP 2, QSP 1 fem. sg.).

**Groups of books** (`fig_ptcp_groups`, `table_ptcp_groups.csv`). Without a
long ending (none or fem. sg.) every group is 89–97% full. The differences
come from the forms with a plural ending or suffix: MT Pentateuch 27% full
(34/127), MT Former Prophets 60%, MT other books 61%, MT LBH 83%, non-QSP
Pentateuch 19% (n = 16), non-QSP other books 74%, QSP 93%.

**Verb classes** (`fig_ptcp_explore_verb_classes`). ע-ע verbs are 96% full,
but >RR[ and BLL[ (88 of the 143 forms) are always full; without them 89%.
ל-ה verbs are 93% full (94% without NVH[). I-yod (22 forms, 68%) is not
modelled.

**Parallel passages** (`fig_ptcp_parallel_passages`). Unlike the
infinitives, the MT is fuller than the scroll more often (19 times: non-QSP
13, QSP 6) than the scroll than the MT (11: non-QSP 4, QSP 7); 160 parallels
are full in both, 11 defective in both (201 pairs; data of 2026-11-03: 4Q139
NVJH, Deut 5:15, added as MT fuller; three non-QSP pairs dropped out). Examples of a fuller MT: FPN/VMN in
Deut 33:19 (4Q35, Mas1c), NF> in 1QIsaa, CDPWT in Gen 41:6 (4Q3, 4Q5).
*(2026-10-10: computed with the corrected pairing `parallel_forms()` in
`functions.R`, which pairs the n-th scroll form with the n-th MT form of a
lexeme in a verse; for this verb form the 203 pairs are the same as with the
first version.)*

**Prefix** (`fig_ptcp_explore_prefix`). In the MT forms with a prefix (mostly
the article H or W) are less often full, almost only in the masc. pl. (43%
vs 75%); without PQD[ the raw difference remains (49% vs 73%). In the model,
however, the prefix effect shrinks without PQD[ and is no longer credible
(see "Effects not in the final model").

## Method

- **Model:** Bayesian logistic regression (brms, Bernoulli logit).
- **Random part:** nested, `(1 | scr_book2/lex)` (author's decision).
- **Priors:** normal(0, 2.5) on intercept and coefficients, exponential(1) on
  the standard deviations; sensitivity with sd 1.5 and 4.
- **Reference level:** MT Pentateuch, as in every verb form.
- **Sampler:** 4 chains, warmup 1000, iter 3000 (8000 draws).
- **Candidate models:**

| Model | Fixed effects |
|---|---|
| M0 | none (null model) |
| M1 | corpus (MT / non-QSP / QSP) |
| M2 | corpus group (MT Pentateuch / Former Prophets / LBH / other books, non-QSP, QSP) |
| M3 | M2 + ending (5 levels) |
| M4 | M3 + long ending in non-QSP / QSP (extra effect vs the MT) |
| M5 | M4 + ע-ע + ל-ה |
| M5a | M3 + ע-ע + ל-ה (M5 without the corpus × ending terms) |
| M6 | M5 + prefix (check) |
| m19 | has_suffix + ע-ע + ל-ה (the old final model, new priors) |
| **M7** | corpus group + ending + long ending in QSP + ע-ע + ל-ה (M5 without the non-QSP long-ending term; **final model**) |
| M7 without X | M7 without one of its five effects (drop-one comparison) |
| S1, S1x | corpus group + / × has_suffix (two values) + ע-ע + ל-ה (the book's variable; 2026-10-14) |

- **Final model rule** (author, 2026-10-10; `../CLAUDE.md`): the final model
  contains only credible effects (95% interval excludes 0, pd ≥ 0.975),
  unless the effect rests on one or a few lexemes or is a proxy for another
  variable. For a factor, one credible level suffices.
- **Model comparison:** grouped 5-fold cross-validation (whole scroll-books
  left out per fold). No Bayes factors (author, 2026-10-14): bridge sampling
  was unreliable for these nested models.
- **Effects:** logit scale, shown as odds ratios; median with 66% and 95%
  quantile intervals and pd.
- **Robustness:** M7 with prior sd 1.5 and 4; M5 without PQD[; M5 without
  1QIsaa; M6 (with prefix); M6 without PQD[. The two M5 fits serve for M7,
  because M5 equals M7 plus the non-QSP long-ending term, which is about 0.
- **Postponed:** the Isaiah manuscripts model, the MT Pentateuch books model
  and the crossed vs nested demonstration (author, 2026-10-09).

## Model comparison

Refitted 2026-11-04 (`ptcp_d3_*`). All 23 fits: max Rhat ≤ 1.007, no
divergent transitions. 13% of the forms have Pareto k > 0.7, so LOO is
unreliable; grouped k-fold is used.

**Grouped 5-fold cross-validation** (`table_ptcp_kfold.csv`; elpd = expected
log predictive density, higher is better):

| Model | elpd difference to best | SE |
|---|---|---|
| **M7** (final) | 0 | — |
| M5 (M7 + long ending in non-QSP) | −0.8 | 0.6 |
| M6 (M5 + prefix) | −1.7 | 2.6 |
| M7 without ל-ה | −2.1 | 1.8 |
| M7 without corpus group | −4.4 | 4.3 |
| M7 without long ending in QSP | −10.6 | 2.6 |
| M5a (without the corpus × long ending terms) | −11.0 | 2.6 |
| M7 without ע-ע | −16.1 | 3.2 |
| M4 (without verb classes) | −17.7 | 3.7 |
| M3 (without long ending × corpus) | −27.4 | 4.3 |
| S1x: corpus_group * has_suffix + ע-ע + ל-ה | −50.7 | 8.4 |
| S1: corpus_group + has_suffix + ע-ע + ל-ה | −51.8 | 8.3 |
| m19 (old final model) | −61.1 | 9.5 |
| M7 without ending | −113.3 | 11.7 |
| M2 (corpus group) | −137.7 | 12.3 |
| M1 (corpus) | −143.1 | 13.5 |
| M0 (null) | −145.8 | 14.2 |

On the data of 2026-10-16 M6 was ahead (M7 −0.5, SE 2.5); now M7 is the best
model.

**The book's two-value `has_suffix`** (S1, S1x; 2026-10-14, author). The
author finds `ending` + `qsp_long` too complicated and asked to test the
book's variable (1 = any nominal ending or pronominal suffix). Pointwise on
the same folds, against M7: S1x −50.7 (SE 8.4), S1 −51.8 (SE 8.3); S1x and
S1 hardly differ (+1.1, SE 3.2). Both predict clearly worse than M7, and
more so than on the old data (−21.3 and −28.4), because the scrolls now have
their fem. sg. forms (50 of 53 full), which `has_suffix` puts together with
the long endings. Reasons: `has_suffix` puts the fem. sg. (MT 90% full,
almost like no ending) with the long endings, and gives one effect to
endings of very different strength (masc. pl. about 1/35, suffix 1/410,
fem. pl. 1/910 in M7). Suffix effect per corpus group in S1x (odds ratio,
95% interval): MT Pentateuch 0.012 (0.002–0.056), Former Prophets 0.0026
(0.0002–0.026), LBH 0.027 (0.001–0.38), MT other books 0.047 (0.008–0.19),
non-QSP 0.040 (0.003–0.36), QSP 0.24 (0.016–2.9, not credible). Of the
interaction levels (against the MT Pentateuch) only QSP × suffix is credible
(+3.01 log-odds, 0.31 to 5.74, pd 0.985). The story is the same as in M7:
the QSP scrolls do not drop the vowel letter before an ending. ע-ע (16) and
ל-ה (9.3) are stable. No divergent transitions.

### Drop-one comparison for M7 (rule 4)

`table_ptcp_kfold_drop_one.csv`; elpd of the model without the effect minus
M7, so negative = the effect improves the predictions for new books:

| Effect dropped from M7 | elpd difference | SE | Reading |
|---|---|---|---|
| ending | −113.3 | 11.7 | very large gain |
| ע-ע verbs | −16.1 | 3.2 | clear gain |
| long ending in QSP | −10.6 | 2.6 | clear gain |
| corpus group | −4.4 | 4.3 | **no clear gain** |
| ל-ה verbs | −2.1 | 1.8 | **no clear gain** |

The same reading as with the data of 2026-10-16 (ending −96.3, ע-ע −14.8,
QSP long ending −7.7, corpus group −5.4, ל-ה −3.3).

## Final model M7

**Choice** (2026-10-11, credible-effects rules; confirmed 2026-10-18 and,
after the refit, 2026-11-04):
- **The non-QSP long-ending term of M5 is left out:** it is not credible
  (odds ratio 0.67, 95% interval 0.08–5.5, pd 0.64), and dropping it costs
  nothing in cross-validation (M5 vs M7: −0.8, SE 0.6).
- **The prefix of M6 is left out**, although it is credible in M6 (odds ratio
  0.37, 95% interval 0.17–0.74, pd 0.997). It rests largely on one lexeme:
  without PQD[ it shrinks (odds ratio 0.60, 95% interval 0.27–1.3, pd 0.90)
  and is no longer credible (rule 3(i)). It is reported as a PQD[ effect. In
  cross-validation the prefix brings no gain either (M6 vs M7: −1.7, SE 2.6).
- All other effects are credible and stay in.

### Effects

`fig_ptcp_effects`, `table_ptcp_effects.csv`. Odds ratios for full spelling,
median with 95% interval:

| Effect | Odds ratio | 95% interval | pd |
|---|---|---|---|
| MT Former Prophets vs MT Pentateuch | 1.6 | 0.27–8.6 | 0.70 |
| MT LBH vs MT Pentateuch | 12 | 1.5–92 | 0.991 |
| MT other books vs MT Pentateuch | 2.9 | 0.65–11 | 0.92 |
| Non-QSP scrolls vs MT Pentateuch | 4.4 | 0.97–22 | 0.972 |
| QSP scrolls vs MT Pentateuch | 2.7 | 0.33–19 | 0.83 |
| Fem. sg. -H/-T (vs no ending) | 0.55 | 0.18–1.7 | 0.87 |
| Masc. pl. -JM/-J | 0.028 (≈ 1/35) | 0.009–0.075 | 1.00 |
| Fem. pl. -WT/-T | 0.0011 (≈ 1/910) | 0.0002–0.006 | 1.00 |
| Pronominal suffix | 0.0024 (≈ 1/410) | 0.0004–0.011 | 1.00 |
| Long ending in QSP (extra, vs MT) | 31 | 3.1–320 | 0.998 |
| Ayin-ayin verbs | 17 | 3.4–110 | 0.999 |
| III-he verbs | 4.7 | 1.03–26 | 0.977 |

Corpus group and ending are factors: they stay in the model because at least
one level is credible (MT LBH vs MT Pentateuch; masc. pl., fem. pl., suffix);
all levels are reported.

### Predicted probability of full spelling

Predicted probability of full spelling (typical book and lexeme, not ע-ע or
ל-ה; 95% interval; all five endings in `table_ptcp_predicted.csv`):

| Group | no ending | masc. pl. | fem. pl. -WT/-T | suffix |
|---|---|---|---|---|
| MT Pentateuch | 97% (90–99.4) | 48% (22–77) | 3.5% (0.6–16) | 7% (2–28) |
| MT Former Prophets | 98% (92–99.7) | 59% (25–87) | 5% (1–27) | 11% (2–43) |
| MT LBH | 99.7% (98.3–100) | 92% (66–99) | 31% (5–78) | 50% (11–88) |
| MT other books | 99% (97–99.8) | 72% (48–89) | 9% (2–34) | 19% (5–48) |
| Non-QSP scrolls | 99.3% (97–99.9) | 81% (56–94) | 14% (2.6–48) | 26% (7–64) |
| QSP scrolls | 99% (93–99.9) | 99% (89–99.9) | 75% (21–97) | 87% (37–99) |

1. **Scrolls vs MT.** Without a long ending the scrolls spell like the MT
   (QSP vs MT Pentateuch odds ratio 2.7, non-QSP 4.4; neither credible). The
   QSP scrolls differ from the MT only in the forms with a long ending:
   there the odds of a full spelling are about 31 times higher than in the
   MT (95% interval 3.1–320), so that QSP plurals are practically always
   full. The non-QSP scrolls treat the long endings like the MT (no credible
   extra effect; see below).
2. **Groups of books in the MT.** Against the MT Pentateuch only LBH is
   credibly fuller (odds ratio 12, 1.5–92, pd 0.991); the other books (2.9,
   pd 0.92) and the Former Prophets (1.6) are not credibly different. The
   differences show only in the forms with a long ending, because without
   one every group is near 100%. *(On the data before 2026-10-16 the
   Pentateuch was also credibly less full than the MT other books, pd 0.99;
   since then this is a tendency, pd 0.92.)*
3. **Endings.** Every ending lowers the chance of a full spelling, but very
   unequally: fem. sg. hardly (0.55, not credible on its own), masc. pl.
   strongly (1/35), pronominal suffix and fem. pl. -WT/-T extremely (1/410
   and 1/910). With -WT the MT writes at most one of the two vowel letters.
   The fem. pl. effect is smaller than on the data before 2026-10-16
   (1/1800), because the 8 MT forms written -T (6 full) now count as fem.
   pl. The fem. sg. effect is weaker than in the fit of 2026-10-18 (0.42),
   because the scroll fem. sg. forms, nearly all full, are now counted as
   fem. sg.
4. **Verb classes.** Ayin-ayin (17) and III-he verbs (4.7) are more often
   full, with wide intervals (the classes are dominated by >RR[, BLL[ and
   NVH[). The III-he effect is credible only just (lower 95% limit 1.03;
   6.1, 1.3–38 in the fit of 2026-10-18) and does not clearly improve the
   out-of-sample predictions (see below).

### Credible but no gain in the k-fold (rule 4)

- **Corpus group: credible (MT LBH vs MT Pentateuch, pd 0.991), but no clear
  gain in cross-validation** (−4.4, SE 4.3). Why:
  - the only credible level is LBH (118 MT forms); the other levels are
    uncertain;
  - when whole books are left out, their book intercepts and the ending
    terms carry most of the prediction.
  - What it means for the conclusion: the factor answers research questions
    1–2 and stays (rule 2), but apart from LBH vs the Pentateuch the group
    differences are weak.
- **ל-ה verbs: credible, but no clear gain in cross-validation.** The effect
  is credible, but only just (odds ratio 4.7, 95% interval 1.03–26, pd
  0.977; the same pd with prior sd 1.5 and 4, 0.980 without PQD[, 0.989
  without 1QIsaa), and a model without it predicts new books almost as well
  (−2.1, SE 1.8). Why:
  - the ל-ה participles are few (NVH[ 45 forms, plus a handful of other
    lexemes), and they are nearly always full anyway (93%);
  - the effect is therefore estimated from few lexemes and its interval is
    wide; in a new book a ל-ה participle is predicted almost as well by the
    overall high share of full forms and the lexeme and book intercepts.
  - What it means for the conclusion: ל-ה participles are more often full
    than other participles, but this is a small, uncertain contribution; the
    conclusions on corpus, groups of books and endings do not depend on it.

## Effects not in the final model

No credible effect, or one that rests on a lexeme
(`fig_ptcp_effects_not_in_final_model`,
`table_ptcp_effects_not_in_final_model.csv`; odds ratio, median with 95%
interval):

| Effect | Model | Odds ratio | 95% interval | pd | Reason |
|---|---|---|---|---|---|
| Long ending in non-QSP (extra, vs MT) | M5 | 0.67 | 0.08–5.5 | 0.64 | not credible |
| Prefix (vs none) | M6 | 0.37 | 0.17–0.74 | 0.997 | rests on PQD[ |
| Prefix (vs none), without PQD[ | M6 without PQD[ | 0.60 | 0.27–1.3 | 0.90 | not credible |

**Suggested wording for the prefix:** "Forms with a prefix (mostly the
article or W) are less often spelled full, almost only in the masculine
plural. In the model this effect rests largely on PQD[ (construct plurals in
Numbers); without that lexeme it is much smaller and no longer credible (odds
ratio 0.60, 95% interval 0.27–1.3)."

## Robustness

`fig_ptcp_robustness`, `table_ptcp_robustness.csv`:
- **Without PQD[** the effects hardly change (MT LBH vs MT Pentateuch 11
  instead of 12; masc. pl. 1/48 instead of 1/35; QSP long ending 28 instead
  of 31; ל-ה 5.0, pd 0.980), except the pronominal suffix (1/14 instead of
  1/410): PQD[ supplies most defective suffixed forms.
- **Without 1QIsaa the extra QSP long-ending effect shrinks** (odds ratio
  9.9, 95% interval 0.33–330, pd 0.91) and is no longer credible: part of
  the QSP effect rests on 1QIsaa. This is a scroll, not a lexeme, so rule
  3(i) does not apply; the effect stays in the final model, but the text
  should mention the dependence on 1QIsaa.
- With the prefix (M6) all other effects stay the same.
- **Prior sensitivity** (M7 with prior sd 1.5 and 4): every credible effect
  stays credible (MT LBH pd 0.979 / 0.991 / 0.997 with sd 1.5 / 2.5 / 4; QSP
  long ending 0.996 / 0.998 / 1.000; ל-ה 0.977 in all three, lower 95% limit
  1.02–1.03). The sizes depend strongly on the prior, as expected with cells
  that are nearly all full or all defective: masc. pl. 1/14, 1/35, 1/88; QSP
  long ending 10, 31, 92. Non-QSP vs MT Pentateuch becomes credible only
  with sd 4 (pd 0.984).

## Model checks

`check_ptcp_*`: the posterior predictive shares match the observed shares per
group of books, per corpus × ending and per main lexeme (MT Pentateuch 64.9%
observed vs 65.2% predicted; MT fem. pl. 25.0% vs 27.3%; MT suffix 12.9% vs
15.6%; PQD[ 25.0% vs 25.2%; non-QSP fem. sg. 100% vs 95.2%). In-sample
classification: accuracy 0.95, sensitivity (full) 0.98, specificity
(defective) 0.86; Bayes R2 0.66 (0.60–0.72). Convergence of M7: max Rhat
1.005, no divergent transitions, min bulk ESS/draws 0.11.

## Comparison with the book

- The book's final model m19 (has_suffix + ע-ע + ל-ה, new priors) predicts
  clearly worse (−61.1, SE 9.5 vs M7): it has no corpus term and treats all
  endings alike.
- The book's two-value `has_suffix` with corpus group (S1, S1x) also predicts
  worse, but tells the same story (see Model comparison).
- The section-by-section check of the book text is still to do.

## Points for the author

- **Fem. pl. -WT.** In the MT the feminine plural is almost always defective
  (11 of 44 full; written -WT 5 of 36: QTLWT rather than QTWLWT; written -T 6
  of 8), which fits an avoidance of two vowel letters in one word. The QSP
  scrolls do write both (6 of 7).
- **The QSP scrolls and the endings.** The difference between QSP and MT lies
  almost entirely in the forms with a long ending; without an ending the MT
  is as full as the QSP scrolls (94% vs 93%).
- **Parallel passages.** For the participle the scrolls are not
  systematically fuller than the MT in the same passage.
- **Decided (2026-10-18, confirmed 2026-11-04 after the refit on the data of
  2026-11-03):** M7 stays the final model; S1x predicts clearly worse
  (now −50.7, SE 8.4), and in S1x only QSP × suffix is credible.
- **Confirm:** the QSP long-ending effect stays in the final model, although
  it is no longer credible without 1QIsaa (a scroll, not a lexeme, so rule
  3(i) does not apply); the text should mention the dependence.
- **Corpus group without clear k-fold gain** (−4.4, SE 4.3): accept the
  rule-4 wording above? Only LBH is credibly fuller than the Pentateuch; the
  old claim "MT Pentateuch less full than the other books" no longer holds
  (2.9, pd 0.92).
- **New (2026-11-04): ל-ה is credible only just** (4.7, 95% interval
  1.03–26, pd 0.977; 6.1, 1.3–38, pd 0.991 in the fit of 2026-10-18). The
  book text on III-he participles should be cautious: "more often full, but
  the effect is uncertain and does not improve the predictions for new
  books".
