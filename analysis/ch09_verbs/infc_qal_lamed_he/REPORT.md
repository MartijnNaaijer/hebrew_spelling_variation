# Qal infinitive construct of III-he verbs — analysis report

*2026-10-09, harmonised 2026-10-17. Script: `infc_qal_lamed_he/analysis.R`.
Figures and tables: `infc_qal_lamed_he/figures/`. Design approved by the
author on 2026-10-09; models fitted 2026-10-09/12. Final model M4p (author,
2026-10-12): M3 plus a prefix effect in the MT Pentateuch only; M3 was the
final model before (see "Final model M4p").*

*2026-10-17/18 (harmonisation, `../TODO.md` section 13): Bayes factors
dropped; intervals are quantile intervals (median, 66% and 95%) with pd, as
in all verb forms; refitted with the MT Pentateuch as reference level of
`corpus_group` (`infc_lh2_*`, warmup 1000 / iter 3000); prior sensitivity of
M4p added.*

## Summary

- The ending -WT is the norm outside the MT Pentateuch: MT Former Prophets,
  MT other books and the non-QSP scrolls are 95–96% full, MT LBH 92%, QSP
  100%. The MT Pentateuch is 71% full.
- The defective forms of the Pentateuch sit in its forms with a prefix
  (odds ratio about 1/18 in M4p; 14 of 14 forms without suffix and prefix are
  full). With the prefix in the model, the other groups no longer differ
  credibly from the Pentateuch forms without a prefix, except QSP (odds
  ratio 29, 95% interval 2.1–770: all 59 QSP forms are full).
- A pronominal suffix strongly lowers the chance of a full ending (odds
  ratio about 1/49), above all the 3ms suffix (-TW).
- The prefix effect is credible but not robust (it rests on HJH[ and <FH[
  and on only 20 Pentateuch forms without a prefix) and improves the
  predictions for new books only slightly (+4.8 elpd over M3, SE 4.5); the
  author kept it (2026-10-12).

## Descriptive results

**Data.**
- **Dataset:** `infc_qal_lamed_he.csv`, 963 forms of the qal infinitive
  construct of III-he verbs.
  - 823 MT forms, 81 from non-QSP scrolls, 59 from QSP scrolls; no SP forms.
  - 46 lexemes in 97 scroll-books.
- **Outcome:** full ending -WT (`has_vowel_letter = 1`, e.g. <FWT) vs defective
  -T (<FT). 90% of the forms are full (99 defective).
- **Unbalanced lexemes:** <FH[ (358 forms, 91% full), HJH[ (173, 92%), R>H[
  (126, 84%). No lexeme behaves differently enough to need its own fixed
  effect.
- **Mostly single-form groups:** 177 of the 309 book×lexeme groups contain one
  form.

**Groups of books** (`fig_infc_lh_groups`, `table_infc_lh_groups.csv`):

| Group | n | full |
|---|---|---|
| MT Pentateuch | 210 | 71% |
| MT Former Prophets | 191 | 95% |
| MT LBH | 152 | 92% |
| MT other books | 270 | 96% |
| Non-QSP scrolls | 81 | 95% |
| QSP scrolls | 59 | 100% |

- The defective forms cluster in the MT Pentateuch, above all Exodus (21 of
  46 forms without suffix defective, in chapters 1–24 and 25–40 alike), then
  Leviticus and Genesis (`fig_infc_lh_explore_mt_books`).
- Without a suffix, MT Former Prophets (160/160) and MT other books (224/225)
  are practically always full.
- In the scrolls almost every form is full: QSP 59/59, non-QSP Former Prophets
  10/10 and other books 31/31. The groups of books are therefore split only
  within the MT.

**Parallel passages** (`fig_infc_lh_parallel_passages`): where the same form
occurs in the MT and in a scroll, the scroll is fuller 17 times (non-QSP 10,
QSP 7) and the MT never; 113 parallels are full in both, 4 (non-QSP) defective
in both. *(2026-10-09: the pairing of scroll and MT forms was corrected for
verses with several forms of the same lexeme (`parallel_forms()` in
`functions.R`); for this verb form the 134 pairs and their patterns are
unchanged.)*

**Suffix and prefix:** see "Points for the author" (the 3ms suffix; the
prefix and the prefix B).

## Method

**Research questions.**
1. Do the QSP and non-QSP scrolls spell the ending more fully than the MT?
2. Within the MT: do the groups of books differ (Pentateuch, Former Prophets,
   LBH, other books)?
3. Is the ending less often full before a pronominal suffix?

- **Model:** Bayesian logistic regression (brms, Bernoulli logit).
- **Random part:** nested, `(1 | scr_book2/lex)` (author's decision).
- **Priors:** normal(0, 2.5) on intercept and coefficients, exponential(1) on
  the standard deviations. As in the triliteral infinitive, a wide prior is
  needed: the groups range from 71% to 100% full, and several cells are
  (nearly) all full, so their coefficients rest partly on the prior.
- **Sampler:** 4 chains, warmup 1000, 3000 iterations (8000 draws),
  adapt_delta 0.99.
- **Reference level:** MT Pentateuch (refit 2026-10-18), as in every verb
  form.
- **Candidate models:**

| Model | Fixed effects |
|---|---|
| M0 | none (null model) |
| M1 | corpus (MT / non-QSP / QSP) |
| M2 | corpus group (MT Pentateuch / Former Prophets / LBH / other books, non-QSP, QSP) |
| M3 | M2 + pronominal suffix |
| M4 | M3 + prefix (check) |
| n1 | law_phase3 + suffix (also splits the non-QSP scrolls) |
| m11 | suffix + law_phase3 × prefix (the old final model, new priors) |
| M3 without corpus group | suffix only (drop-one comparison; M3 without the suffix is M2) |
| **M4p** | M3 + prefix in the MT Pentateuch (`pent_prefix` = 1 for MT Pentateuch forms with a prefix); **final model** |
| M4p without corpus group | suffix + prefix in the MT Pentateuch (drop-one) |
| M4p without suffix | corpus group + prefix in the MT Pentateuch (drop-one); M4p without `pent_prefix` is M3 |

- **Final model rule** (author, 2026-10-10; `../CLAUDE.md`): the final model
  contains only credible effects (95% interval excludes 0, pd ≥ 0.975),
  unless the effect rests on one or a few lexemes or is a proxy for another
  variable. For a factor, one credible level suffices.
- **Model comparison:** grouped 5-fold cross-validation (whole scroll-books
  left out per fold). No Bayes factors (author, 2026-10-14/17).
- **Effects:** logit scale, shown as odds ratios; median with 66% and 95%
  quantile intervals and pd.
- **Robustness:** M3 without 1QIsaa; M3 without <FH[; M4 without HJH[ and
  <FH[ (does the prefix effect rest on these two lexemes?); prior
  sensitivity of the final model M4p with sd 1.5 and 4.
- **Not included for now:** the comparison of the Isaiah manuscripts (all 42
  Isaiah forms in the scrolls are full); to be looked at later.

## Model comparison

**Grouped 5-fold cross-validation** (`table_infc_lh_kfold.csv`; elpd =
expected log predictive density, higher is better):

| Model | elpd difference to best | SE |
|---|---|---|
| M4p without corpus group (suffix + prefix in the MT Pentateuch) | 0 | — |
| **M4p** (M3 + prefix in the MT Pentateuch; final) | −4.1 | 5.0 |
| m11 (old final model) | −7.7 | 5.8 |
| M3 (corpus group + suffix) | −8.9 | 6.5 |
| M4 (M3 + prefix everywhere) | −13.2 | 6.5 |
| n1 (law_phase3 + suffix) | −13.2 | 7.5 |
| M3 without corpus group (suffix only) | −52.6 | 10.8 |
| M2 (corpus group) | −58.1 | 11.6 |
| M4p without suffix | −61.3 | 11.8 |
| M1 (corpus) | −91.4 | 12.4 |
| M0 (null) | −93.1 | 13.8 |

The differences among the first six models are within about two standard
errors. M4p predicts better than M4 (+9.2, SE 4.6) and somewhat better than
M3 (+4.8, SE 4.5). With the MT Pentateuch as reference, M3 and M4 predict
worse than in the earlier fits with MT other books as reference (−5.4 and
−6.9 elpd): the prior sd 2.5 on the coefficients now shrinks the large
contrast between the Pentateuch and the other groups. M4p is not affected,
because its Pentateuch level is that of its forms without a prefix, which
are nearly all full.

### Drop-one comparison for M4p (rule 4)

`table_infc_lh_kfold_drop_one.csv`; elpd of the model without the effect
minus M4p, negative = the effect improves the predictions for new books:

| Effect dropped from M4p | elpd difference | SE | Reading |
|---|---|---|---|
| pronominal suffix | −57.2 | 11.4 | very large gain |
| prefix in the MT Pentateuch | −4.8 | 4.5 | small gain, not clear |
| corpus group | +4.1 | 5.0 | no gain (the model without it is slightly better) |

## Final model M4p

**Final model: M4p** (author, 2026-10-12):

```r
has_vowel_letter ~ corpus_group + has_prs + pent_prefix + (1 | scr_book2/lex)
# pent_prefix = 1 for MT Pentateuch forms with a prefix, otherwise 0
```

Convergence: max Rhat 1.005, no divergent transitions, min bulk ESS/draws
0.16.

**History.**
1. M3 (corpus group + suffix) was chosen first (author, 2026-10-09): it
   predicted best, and M4's general prefix term did not improve the
   predictions (−2.8, SE 2.6).
2. Under the credible-effects rules (2026-10-11) M3 was confirmed, because
   the general prefix term of M4 is credible (pd 0.996) but shrinks to a
   third without HJH[ and <FH[ (rule 3(i)).
3. The author then decided to keep the prefix in the final model, even if
   it is not very robust, with a remark that it occurs in only part of the
   data (2026-10-12).

**Why a prefix effect for the MT Pentateuch only (M4p), and not a general
prefix term (M4) or an interaction?**
- **The data.** The prefix lowers fullness only in the MT Pentateuch:
  without suffix 14 of 14 forms without a prefix are full against 127 of
  165 with a prefix. In the other groups nearly every form is full with or
  without a prefix (e.g. MT other books 100% vs 99%, Former Prophets 100%
  vs 100%, QSP 100% vs 100%), so there the prefix has no room to make a
  difference. A general prefix term (M4) averages the Pentateuch effect
  over all groups and so says something the data do not show.
- **One parameter.** M4p adds a single dummy that states exactly this: a
  prefix effect in the MT Pentateuch, none elsewhere. It works like the
  `qsp_long` dummy in the participle analysis.
- **No interaction.** A full interaction (corpus or corpus group × prefix)
  adds five terms that rest on cells of 4–14 forms without a prefix, nearly
  all full, so they would mostly reflect the prior. A model of that kind,
  the old final model m11 (law_phase3 × prefix), is not supported (k-fold
  −7.7 against the best model; −3.7, SE 4.0, against M4p). With `corpus`
  instead of `corpus_group` the model would also lose the groups of books
  (the corpus-only model M1 is −91.4).
- **Prediction.** M4p predicts better than M4 (+9.2, SE 4.6) and somewhat
  better than M3 (+4.8, SE 4.5).

### Effects

`fig_infc_lh_effects`, `table_infc_lh_effects.csv`. Odds ratios for full
spelling, median with 95% interval. The groups are compared with the **MT
Pentateuch forms without a prefix** (in M4p the Pentateuch coefficient is
that of these 20 forms; the prefix dummy carries the rest):

| Effect | Odds ratio | 95% interval | pd |
|---|---|---|---|
| MT Former Prophets vs MT Pentateuch | 2.0 | 0.24–15 | 0.75 |
| MT LBH vs MT Pentateuch | 0.29 | 0.036–2.0 | 0.89 |
| MT other books vs MT Pentateuch | 2.5 | 0.41–15 | 0.84 |
| Non-QSP scrolls vs MT Pentateuch | 2.8 | 0.45–19 | 0.87 |
| QSP scrolls vs MT Pentateuch | 29 | 2.1–770 | 0.995 |
| Pronominal suffix (vs none) | 0.021 (≈ 1/49) | 0.009–0.043 | 1.00 |
| Prefix in the MT Pentateuch (vs none) | 0.056 (≈ 1/18) | 0.011–0.24 | 1.00 |

**What the prefix dummy does to the Pentateuch effect.** In M3 the
Pentateuch as a whole differs strongly from the other groups (MT other books
vs MT Pentateuch: odds ratio 15, 3.2–64). In M4p this is split into a
Pentateuch effect for the forms without a prefix (MT other books vs these
forms: 2.5, not credible) and the prefix effect (1/18, credible). Because 190
of the 210 Pentateuch forms have a prefix, the data cannot fully separate
"Pentateuch" from "prefix in the Pentateuch": the defectiveness of the
Pentateuch is concentrated in its prefixed forms, but the evidence for that
rests on only 20 Pentateuch forms without a prefix.

**Credible effects.**
- Prefix in the MT Pentateuch: credible (pd 1.00). Not robust: the general
  prefix term rests largely on HJH[ and <FH[ (see "Robustness"); kept by the
  author's decision.
- Corpus group: kept as a factor because a level is credible (rule 2). Against
  the MT Pentateuch forms without a prefix only QSP is credible (pd 0.995).
  *(With the old reference MT other books, MT LBH was also credible: odds
  ratio 0.12 vs MT other books, pd 0.99. The LBH result therefore concerns
  LBH against the other MT books, not against the Pentateuch.)*
- Suffix: credible (pd 1.00).

### Predicted probability of full spelling

`fig_infc_lh_predicted`, `table_infc_lh_predicted.csv` (typical book and
lexeme, median and 95% interval):

| Group | without suffix | with suffix |
|---|---|---|
| MT Pentateuch, no prefix | 98.9% (95–99.8) | 65% (31–90) |
| MT Pentateuch, with prefix | 84% (63–95) | 10% (3–29) |
| MT Former Prophets | 99.4% (97.5–99.9) | 79% (45–95) |
| MT LBH | 96% (86–99) | 35% (10–73) |
| MT other books | 99.6% (98.5–99.9) | 82% (61–95) |
| Non-QSP scrolls | 99.6% (98.5–99.9) | 84% (60–96) |
| QSP scrolls | 99.96% (99.6–100) | 98% (84–99.9) |

1. **Scrolls vs MT.** The QSP scrolls are the fullest group (odds ratio 29
   against the Pentateuch forms without a prefix, pd 0.995), but the interval
   is very wide: all 59 QSP forms are full, so the size of the effect depends
   partly on the prior. The non-QSP scrolls spell like the MT outside the
   Pentateuch.
2. **Groups of books in the MT.** The Pentateuch is much more often
   defective than the other MT books, and this sits in its forms with a
   prefix: with a prefix 84% full without suffix, against 99% without a
   prefix. LBH is somewhat more defective than the other MT books; the
   Former Prophets equal the other books. The ending -WT is thus the norm
   outside the Pentateuch, not a late feature.
3. **Suffix.** A pronominal suffix strongly lowers the chance of a full
   ending (odds ratio ≈ 1/49), in all corpora. The 3ms suffix is the most
   defective (see "Points for the author").
4. **Prefix.** The prefix lowers fullness only in the MT Pentateuch (odds
   ratio ≈ 1/18). This effect occurs in only part of the data: in the
   Pentateuch (above all Exodus), and it is carried mainly by a few
   lexemes (see "Robustness").

### Credible but no gain in the k-fold (rule 4)

- **Prefix in the MT Pentateuch.** The effect is credible, and the model
  without it (M3) predicts new books somewhat worse (−4.8, SE 4.5), but the
  gain is not clear. Why: M3
  already gives the MT Pentateuch as a whole a low share of full forms, and
  in a left-out Pentateuch book almost all forms have a prefix, so knowing
  the prefix adds little; the 20 forms without a prefix are too few to
  matter. What it means: the prefix effect describes where in the
  Pentateuch the defective forms are (in the prefixed forms), not a factor
  that predicts spelling in new books. It should be presented as a
  descriptive refinement of the Pentateuch result.
- **Corpus group.** Its credible level (QSP) is kept by rule 2, but once the
  prefix dummy carries the Pentateuch effect, the model without corpus group
  predicts slightly better (+4.1, SE 5.0; not
  a clear difference). Why: the remaining group differences are small (LBH)
  or rest on 59 QSP forms that are all full, and in grouped cross-validation
  whole books are left out, so their book intercepts can absorb these
  differences. What it means: the corpus group factor is needed to answer
  research questions 1 and 2, but apart from the Pentateuch the group
  differences are weak; the conclusions on the scrolls and on LBH should be
  worded with this in mind.

## Effects not in the final model

`fig_infc_lh_effects_not_in_final_model`,
`table_infc_lh_effects_not_in_final_model.csv` (odds ratio, median with 95%
interval). The general prefix term is replaced in the final model by the
prefix in the MT Pentateuch:

| Effect | Model | Odds ratio | 95% interval | pd |
|---|---|---|---|---|
| Prefix everywhere (vs none) | M4 | 0.31 | 0.12–0.78 | 0.994 |
| Prefix everywhere, without HJH[ and <FH[ | M4 without HJH[, <FH[ | 0.73 | 0.23–2.1 | 0.71 |

## Robustness

`fig_infc_lh_robustness`, `table_infc_lh_robustness.csv`. The robustness
fits are variants of M3 (and M4); they are compared with M3 itself. Groups
against the MT Pentateuch (in M3 all its forms; in M4 and M4p its forms
without a prefix):

- Without <FH[ (37% of the data) the group and suffix effects hardly change
  (suffix 0.054 instead of 0.031; MT LBH vs MT Pentateuch 4.3, pd 0.94, not
  credible).
- The QSP effect shrinks somewhat without 1QIsaa (odds ratio 54 instead of
  110 vs the Pentateuch) or without <FH[ (53), but stays credible. With all
  QSP forms full the evidence for the size of the QSP effect is weak.
- **Prefix.** A general prefix term (M4) leaves the corpus, group-of-books
  and suffix effects practically unchanged; the prefix itself has odds
  ratio 0.31 (95% interval 0.12–0.78). Without HJH[ and <FH[ it shrinks to
  0.73 (95% interval 0.23–2.1) and is no longer credible. That check model
  keeps 432 of the 963 forms (54 without a prefix), so its interval is also
  wider because of the smaller sample; but the point estimate moves most of
  the way to 1, in line with the descriptive check (the weighted prefix
  difference of −6.4 points becomes +1.3 points without HJH[ and <FH[).
- **Prior sensitivity (M4p).** With prior sd 1.5 and 4 all M4p effects keep
  their direction and credibility, and no other effect becomes credible.
  The QSP effect depends on the prior (odds ratio 9.0 with sd 1.5, 29 with
  2.5, 118 with 4; pd 0.987–0.997), as expected with all QSP forms full;
  the prefix in the Pentateuch (1/13, 1/18, 1/21) and the suffix (1/34,
  1/49, 1/59) much less.

## Model checks

`verify_model()` (`check_infc_lh_trace`, `_dens`, `_ppcheck_*`) and posterior
predictive checks per group of books (`check_infc_lh_ppc_groups`), per corpus
with/without suffix (`check_infc_lh_ppc_suffix`) and per main lexeme
(`check_infc_lh_ppc_lexemes`):

- Convergence fine (max Rhat 1.005, no divergences; all 17 refitted models
  ≤ 1.007). Bayes R2 0.40 (0.33–0.47). In-sample accuracy 0.925
  (sensitivity (full) 0.99, specificity (defective) 0.36; optimistic). LOO:
  all Pareto k < 0.7; LOO is not used for model choice.
- The observed shares lie within the 95% predictive intervals in all cells:
  per group of books (e.g. MT Pentateuch 71.0% observed vs 71.2% predicted;
  non-QSP LBH, 2 forms, 50% vs 71%), per corpus with/without suffix (MT with
  suffix 58.0% vs 59.2%; QSP with suffix 13/13 vs 95.8%) and per lexeme
  (<LH[ 78.8% vs 86.1%, near the lower edge of the interval; CTH[ 91.1% vs
  86.2%).

## Comparison with the book

- The old final model m11 (suffix + law_phase3 × prefix), refitted with the
  new priors, predicts worse than M4p (k-fold −7.7 vs −4.1 against the best
  model; −3.7, SE 4.0, against M4p) and rests on cells of 1–6 forms. Its prefix interactions are not
  supported; the prefix effect is confined to the MT Pentateuch (M4p).
- Splitting the non-QSP scrolls by group of books (n1) predicts worse
  (−13.2; −9.2, SE 6.2, against M4p): the scrolls are nearly always full, so the split cannot be
  estimated.
- The old recorded Bayes factors (not transitive, fitted on the old data and
  priors) are not used; model choice rests on the k-fold.

## Figures and tables

All in `infc_qal_lamed_he/figures/` (PNG and PDF). Book figures `fig_infc_lh_*`,
checks `check_infc_lh_*`, tables `table_infc_lh_*.csv`. Stale files no longer
written by the script: `table_infc_lh_bayes_factors.csv` and the old
`explore_infc_lam_he_*.png`.

## Points for the author

**Remarks for the text.**
- **The 3ms suffix.** Before a pronominal suffix the ending is far less often
  full in the MT (58%, against 94% without suffix). The 3ms suffix stands out:
  only 10 of 33 MT forms are spelled -WTW, the rest -TW, against 59 of 86 for
  the other suffixes (69%) (`fig_infc_lh_suffix_types`). In the scrolls the
  suffixed forms are nearly always full (QSP 13/13, non-QSP 14/17). The model
  uses a single suffix effect (author's decision); the 3ms difference is
  reported descriptively.
- **The prefix, and the prefix B.** At first sight a prefix makes no
  difference (MT 88.7% full without, 88.4% with a prefix). But forms without
  a prefix much more often carry a suffix (MT 30% vs 12%), and that hides a
  prefix effect. Within the same suffix category, the forms with a prefix are
  less often full: MT without suffix 67/68 (99%) without prefix vs 592/636
  (93%) with prefix; MT with suffix 19/29 (66%) vs 50/90 (56%). The difference
  sits in the Pentateuch (without suffix: 14/14 vs 127/165); in the other
  groups nearly all forms are full with or without a prefix, so there the
  prefix has no room to make a difference. Within the Pentateuch it is
  strongest in Exodus (18 of 39 prefixed forms without suffix full), and the
  defective prefixed forms come from several lexemes (<FH[ 11, HJH[ 10, R>H[
  6, CTH[ 4, <LH[ 4). The final model M4p therefore has a prefix effect for
  the MT Pentateuch only. The type of prefix also matters: in the MT forms
  with B are less often full (62 of 85, 73%) than forms with L (521 of 570,
  91%); K 86%, M 81% (`table_infc_lh_prefixes.csv`).
- **Suggested wording for the prefix:** "In the Pentateuch the infinitive is
  less often spelled full after a prefixed preposition (odds ratio about
  1/18; 95% interval 0.01–0.24): without a prefix the ending is practically
  always full there. In the other books, and in the scrolls, nearly all forms
  are full with or without a prefix. The effect is not robust: it rests on
  the few Pentateuch forms without a prefix (20); a general prefix effect
  disappears without the lexemes <FH[ and HJH[; and it improves the
  predictions for new books only slightly."

**New with the refit (2026-10-18):** against the Pentateuch forms without a
prefix only QSP is credible in M4p (also with prior sd 1.5); without <FH[
the LBH effect of M3 is no longer credible (pd 0.94). The text on LBH should
not claim a credible LBH difference.
