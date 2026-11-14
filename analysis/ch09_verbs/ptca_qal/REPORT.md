# Qal active participle — analysis report

*Started 2026-10-16. Script: `ptca_qal/analysis.R`. Figures and tables:
`ptca_qal/figures/`. Design and model set approved by the author on
2026-10-16; models fitted 2026-10-16/17; final model M7 (author,
2026-10-17). Harmonised 2026-10-17 (`../TODO.md` section 13): quantile
intervals instead of HDI.*

## Summary

- The QSP scrolls spell the participle fully almost always (86%), the MT
  Pentateuch rarely (7%). The MT LBH, the other MT books and the non-QSP
  scrolls lie in between (25-32%) and do not differ much from each other;
  the MT Former Prophets are close to the Pentateuch. The MT LBH vs
  Pentateuch difference is borderline (pd 0.975) and depends on the prior.
- A suffix or ending makes the spelling more defective (odds about 1/6 to
  1/10) in the MT and in the non-QSP scrolls, but not in the QSP scrolls.
- A prefix (mostly the article) makes the spelling more defective only in the
  MT Pentateuch (odds about 1/4); elsewhere it has no clear effect.
- I-yod verbs (I-waw verbs and HLK[) are much fuller (odds about 10-30) in
  the MT and in the non-QSP scrolls, but not in the QSP scrolls. Ayin-ayin
  verbs are fuller everywhere (odds 8). I-nun verbs show no credible
  difference. III-he verbs are slightly fuller in a check model (odds about
  1.6), but they do not improve the k-fold.
- These interactions are credible and robust, but they do not predict new
  books better in the grouped k-fold; the verb classes do (ayin-ayin above
  all). See "Credible but no gain in the k-fold".

## Data

- **Dataset:** `ptca_qal.csv`, 5716 qal active participles in the MT and the
  biblical Dead Sea Scrolls (the Samaritan Pentateuch is left out; ML>[, JR>[
  and >SP[ are excluded because their participle has no o-vowel in the MT).
  - 4551 MT forms, 525 from non-QSP scrolls, 640 from QSP scrolls.
  - 410 lexemes.
- **Outcome:** full (`has_vowel_letter = 1`, e.g. QWVL) vs defective (QVL)
  spelling of the o-vowel in the first syllable.

### Suffix or ending: what counts as an ending (important for the book)

The book's predictor `has_suffix` is 1 when the participle has a pronominal
suffix or a nominal ending. Two decisions about what counts as an ending
(author, 2026-10-16) change the data with respect to the version used in
the manuscript of 2026-09-10:

1. **A feminine singular whose "ending" is only the last root letter has no
   ending.** In these forms nothing is added to the masculine: the letters,
   the number of syllables and the place of the stress are the same; only
   the vowel differs. The feminine gender is kept in the data (`gn = f`).
   - **III-he verbs:** רֹעָה has the same letters as the masculine רֹעֶה (both
     R<H). 73 MT forms of 16 lexemes (ZNH[ "harlot" 29, <LH[ 9, <FH[ 6, ...)
     were counted as forms with an ending before; now they have none, like
     the masculine.
   - **Qoh 10:5 יֹּצָא** (JY>[): BHSA analyses it as a feminine singular with
     ending H (`nme = H`), written with the aleph (`g_nme = /@>`), so the
     aleph, the third radical, was counted as the ending. The form has the
     letters of the masculine יֹצֵא; it is the feminine participle written
     with aleph for the regular יֹצֵאת. Now: no ending, aleph part of the stem.
   - Not affected: feminine singulars that add a syllable (יֹלְדָה, אֹכְלָה), and
     the III-he passive participles (נְטוּיָה adds a syllable to נָטוּי; see
     ptcp_qal).
   - Why it matters: `has_suffix` is meant to capture a longer word, in which
     the first syllable is further from the stress (Andersen and Forbes).
     These forms are not longer. In the old data they were also striking
     exceptions: 40 of the 73 III-he feminine singulars are full (55%), while
     MT participles with an ending are 12-30% full. This rests largely on
     ZNH[ (26 of 29 full); without it 14 of 44 (32%).

2. **Plural construct in the scrolls.** In five scroll forms (1QIsaa Isa 9:8,
   30:18, 49:25, 57:5; Xjudges Judg 1:11, e.g. JWCBJ) the yod of the plural
   construct was not recognised as an ending in the preprocessing. They now
   have an ending, as the same forms in the MT.

In addition, the data now have a column `nme_type` (none / fem. sg. / masc.
pl. / fem. pl.) for the grammatical ending. The written ending (`nme`) could
not distinguish a feminine plural without waw (שֹּׁאֲבֹת, 28 MT forms, written
-T) from a feminine singular; this only affected the finer coding `ending`,
not `has_suffix`.

These corrections were made in the preprocessing
(`hebrew_spelling_variation/preprocess_data`, README section "Nominal endings
of the participles"); the counts in the book (e.g. forms with and without a
suffix per group, Figure 9.2) change accordingly.

## Descriptive results

Shares of full spelling (tables `table_ptca_groups.csv`, `_suffix`,
`_prefix`, `_prefix_types`, `_verb_classes_groups`, `_hlk_prefix`):

| Corpus group | n | full | without / with suffix or ending | without / with prefix |
|---|---|---|---|---|
| MT Pentateuch | 819 | 7% | 9% / 2% | 8% / 4% |
| MT Former Prophets | 802 | 12% | 18% / 7% | 12% / 13% |
| MT LBH | 459 | 26% | 42% / 18% | 25% / 28% |
| MT other books | 2471 | 25% | 33% / 16% | 27% / 21% |
| Non-QSP | 525 | 32% | 40% / 20% | 34% / 28% |
| QSP | 640 | 86% | 86% / 86% | 86% / 86% |

- **Prefix in the MT Pentateuch:** with the article 6 of 207 full (3%), with
  the conjunction W 1 of 41, with a preposition 3 of 25; without prefix 8%.
  HLK[ with the article is never full (0 of 16; without prefix 10 of 17).
- **I-yod:** MT Pentateuch 21% (162 forms) vs 3% for the other verbs; in the
  QSP scrolls 87% vs 85%.
- **Ayin-ayin:** fuller in every group, but with few forms (7 to 35 per group,
  121 in the MT other books).

## Method

- Bernoulli (logit) models in brms with the nested random intercepts
  `(1 | scr_book2/lex)` (scroll-book, and lexeme within scroll-book).
- `corpus_group`: MT Pentateuch (reference), MT Former Prophets, MT LBH,
  MT other books, non-QSP, QSP.
- Priors normal(0, 2.5) on the intercept and coefficients, exponential(1) on
  the SDs; prior sensitivity with sd 1.5 and 4. The prior predictive check
  (`check_ptca_prior_predictive`) covers the whole range of shares.
- 4 chains, warmup 1000, 3000 iterations (8000 draws), adapt_delta 0.99.
- Model comparison by grouped 5-fold k-fold: every scroll-book is left out as
  a whole, so the k-fold asks how well a model predicts the spelling in a
  book it has not seen. No Bayes factors.
- Final model by the credible-effects rules (`analysis/README.md`).

## Model comparison

| Model | Formula (all + `(1 \| scr_book2/lex)`) | elpd diff | SE |
|---|---|---|---|
| M3e | corpus_group + ending + prefix + I-yod + ayin-ayin | 0 | – |
| M3 | corpus_group + suffix + prefix + I-yod + ayin-ayin | -4.5 | 3.9 |
| M3n | M3 + I-nun | -5.7 | 4.1 |
| M7_no_suffix_x | M7 without corpus_group x suffix | -6.9 | 8.3 |
| M4 | M3 + corpus_group x suffix | -9.6 | 6.3 |
| M7_no_prefix_x | M7 without corpus_group x prefix | -9.9 | 9.4 |
| M5 | M4 + corpus_group x prefix | -11.9 | 6.9 |
| **M7** | **M5 + corpus_group x I-yod (final)** | **-12.2** | **9.9** |
| M7_iii_h | M7 + III-he (check model, 2026-10-19) | -13.8 | 10.3 |
| M6 | M7 + corpus_group x ayin-ayin | -13.9 | 10.1 |
| n3 | the book's model (law_phase3 x suffix, prefix, ayin-ayin, I-yod) | -41.5 | 10.7 |
| M7_no_ay_ay | M7 without ayin-ayin | -48.5 | 12.4 |
| M2 | corpus_group | -250.9 | 21.0 |
| M1 | corpus (MT, non-QSP, QSP) | -334.1 | 22.0 |
| M0 | null | -943.6 | 31.5 |

(`table_ptca_kfold.csv`.) All models converged: Rhat <= 1.006, bulk ESS >=
1100, no divergent transitions.

- Most of the gain comes from the corpus groups (M0 to M2) and from the verb
  features (M2 to M3: +246).
- The finer `ending` (M3e) predicts slightly better than `has_suffix` (+4.5,
  SE 3.9: about one SE, not a clear gain). The final model uses
  `has_suffix`, as in the book (author, 2026-10-17); the endings are reported
  as an alternative coding (below).
- The interactions (M4 to M7) do not improve the prediction; M7 is 7.7
  below M3, within the uncertainty.
- The book's model n3 predicts clearly worse than M3 and M7: its split of the
  non-QSP scrolls into four groups and its 40 interaction terms (several on
  empty or tiny cells) add parameters without information.

### Drop-one comparison for M7 (rule 4)

Reduced model minus M7 (positive: the reduced model predicts better;
`table_ptca_kfold_drop_one.csv`):

| Effect dropped | elpd diff | SE |
|---|---|---|
| corpus group x suffix | +5.3 | 4.9 |
| corpus group x prefix | +2.3 | 3.0 |
| corpus group x I-yod (= M5) | +0.3 | 6.5 |
| ayin-ayin | -36.3 | 7.5 |

## Final model M7

`has_vowel_letter ~ corpus_group * has_suffix + corpus_group * has_prefix +
corpus_group * i_yod + ay_ay + (1 | scr_book2/lex)`

Why this model (credible-effects rules, author's decision 2026-10-17):

- M6 (all interactions) has credible levels in the interactions of the
  corpus group with suffix (QSP), prefix (all groups) and I-yod (QSP), and
  none in the interaction with ayin-ayin (all pd < 0.85). M7 is M6 without
  that interaction (rules 1 and 2).
- The credible effects survive without JCB[ (588 forms, half of the I-yod
  forms), without HLK[ and without 1QIsaa (rule 3(i); "Robustness").
- I-nun is not credible (M3n: -0.34, 95% interval -0.82 to 0.15, pd 0.92).

### Effects per corpus group

With interactions a coefficient is the effect in the MT Pentateuch only, so
`fig_ptca_effects` / `table_ptca_effects.csv` show the total effect in each
group (logit scale, median and 95% quantile interval; odds ratio in
brackets where credible):

| Effect | MT Pent. | MT Former Pr. | MT LBH | MT other | Non-QSP | QSP |
|---|---|---|---|---|---|---|
| Group vs MT Pentateuch | – | 0.11 [-1.52, 1.62] | 1.62 [-0.00, 3.12] (5.1, borderline) | 1.81 [0.54, 3.02] (6.1) | 1.89 [0.56, 3.06] (6.6) | 5.76 [4.35, 7.12] (318) |
| Suffix or ending | -2.34 [-3.33, -1.47] (1/10) | -1.75 [-2.43, -1.12] (1/6) | -2.25 [-3.02, -1.51] (1/9) | -1.73 [-2.07, -1.41] (1/6) | -2.20 [-2.96, -1.46] (1/9) | -0.08 [-0.71, 0.55] |
| Prefix | -1.48 [-2.36, -0.67] (1/4) | 0.18 [-0.51, 0.87] | -0.06 [-0.78, 0.66] | -0.33 [-0.64, -0.02] (0.7) | -0.22 [-0.93, 0.48] | 0.18 [-0.46, 0.85] |
| I-yod | 2.72 [1.67, 3.82] (15) | 2.52 [1.41, 3.68] (12) | 3.49 [2.23, 4.78] (33) | 2.31 [1.73, 2.93] (10) | 2.17 [1.31, 3.05] (9) | -0.41 [-1.49, 0.70] |
| Ayin-ayin (all groups) | 2.08 [1.43, 2.77] (8) | | | | | |

- **Corpus groups.** QSP is far fuller than everything else. MT LBH, MT other
  books and non-QSP are fuller than the MT Pentateuch, with odds ratios of
  5-7, and are close to each other. The MT Former Prophets do not differ from
  the Pentateuch. MT LBH is borderline: its 95% interval just touches 0
  (pd 0.9748, just under the 0.975 of rule 1; with the HDI used before
  2026-10-17 it was 0.12 to 3.23). The corpus factor stays (rule 2), but the
  text should call the LBH difference likely rather than certain.
- **Suffix or ending.** In the MT and the non-QSP scrolls a longer word is
  spelled more defectively, in all groups about equally (odds 1/6 to 1/10).
  In the QSP scrolls the suffix has no effect: they write the waw also in the
  longer forms.
- **Prefix.** Only in the MT Pentateuch (odds 1/4), and weakly in the MT
  other books (0.7, just credible). In the Pentateuch this is mostly the
  article (3% full). It is not the HLK[ forms alone (without HLK[: -1.0,
  still credible).
- **I-yod.** Fuller in all MT groups and in the non-QSP scrolls (odds 9 to
  33), not in the QSP scrolls, which are full anyway.
- **Ayin-ayin.** Fuller in all groups (odds 8); the k-fold clearly prefers
  the model with it.

### Predicted probability of full spelling

Typical book and lexeme, not I-yod or ayin-ayin (`fig_ptca_predicted`,
`table_ptca_predicted.csv`; median):

| Corpus group | no suffix, no prefix | suffix or ending | prefix, no suffix |
|---|---|---|---|
| MT Pentateuch | 3.3% | 0.3% | 0.8% |
| MT Former Prophets | 3.8% | 0.7% | 4.5% |
| MT LBH | 15% | 1.8% | 14% |
| MT other books | 18% | 3.6% | 13% |
| Non-QSP | 19% | 2.5% | 16% |
| QSP | 92% | 91% | 93% |

An I-yod verb in the MT Pentateuch without suffix or prefix: 35%. These
predictions are for a typical lexeme and are lower than the raw shares,
because the raw shares include the frequent fuller lexemes (JCB[, HLK[,
JY>[).

### Credible but no gain in the k-fold (rule 4)

The three interactions are credible, robust and stable under the prior, but
the model without each of them predicts new books as well or slightly better
(drop-one: +0.3 to +5.3, all within about one SE). Reasons:

- **Two of them concern only the QSP scrolls** (QSP x suffix, QSP x I-yod),
  which are few books and nearly always full (86%). A QSP form is predicted
  well by the QSP intercept alone; the interaction changes the predicted
  probability in QSP by a few percentage points (92% vs 91% with a suffix).
- **The prefix effect is confined to the MT Pentateuch** (5 books, 273 forms
  with a prefix, 10 full). When a Pentateuch book is left out, the others
  carry the estimate, but the gain on predicted probabilities of 1-4% is
  small.
- **The variation between books and between lexemes within books is large**
  (SD 1.10 and 1.96 on the logit scale), so much of what a new book does is
  not predictable from the fixed effects.

What this means for the conclusions: the interactions describe real
differences in the data (the QSP scrolls write the waw regardless of word
length and verb class; the MT Pentateuch avoids it after the article), but
they do not predict the spelling of a new text better. The suffix, I-yod and
ayin-ayin as main effects do.

## Effects not in the final model

`fig_ptca_effects_not_in_final_model`, `table_ptca_effects_not_in_final_model.csv`
(logit, median and 95% quantile interval):

- I-nun (M3n): -0.34 [-0.82, 0.15], pd 0.92. No credible effect. (The book
  has no I-nun effect in §9.2; an earlier version of this report said it
  had, corrected 2026-10-19.)
- III-he (check model M7_iii_h, fitted 2026-10-19): 0.50 [0.11, 0.87],
  pd 0.994 (odds about 1.6); -1.6 elpd (SE 3.0) against M7. Without ZNH[
  (זנה, 42 forms, 29 full; fitted 2026-11-03, 5,674 forms) it is 0.25
  [-0.13, 0.64], pd 0.902, so it is no longer credible: a lexeme effect of זנה (rule
  3(i)), not in the final model. Descriptively III-he verbs are slightly *less* often full (MT 17
  vs 20%), because the fuller I-yod verbs are almost all among the other
  verbs (26% of them, 0.8% of III-he); without I-yod and ayin-ayin, III-he
  in the MT is fuller (17 vs 13%). Barr's "more defective" is not supported.
  Rhat <= 1.003, no divergences.
- Corpus group x ayin-ayin (M6, extra vs MT Pentateuch): all intervals
  include 0 (medians -1.26 to +0.55, pd 0.62-0.83).
- Endings (M3e, alternative coding, no interactions): fem. sg. -0.56
  [-1.05, -0.06], masc. pl. -1.70 [-1.96, -1.44], fem. pl. -2.63 [-3.61,
  -1.76], pronominal suffix -1.70 [-2.16, -1.27]. The fem. sg. ending (one
  syllable added, e.g. יֹלְדָה) has a smaller effect than the plural endings
  and the suffixes; the fem. pl. -WT has the largest.

## Robustness

`fig_ptca_robustness`, `table_ptca_robustness.csv` (the key effects in M7,
M6 and the M6 robustness fits, and M7 with prior sd 1.5 and 4):

- **Without JCB[:** all effects stay; QSP x I-yod gets stronger.
- **Without HLK[:** the prefix effect in the MT Pentateuch weakens from -1.5
  to -1.0 but stays credible.
- **Without 1QIsaa:** all effects stay, with wider intervals for QSP.
- **1QIsaa I and II as separate groups** (`table_ptca_1qisaa_split.csv`):
  both halves and the other QSP scrolls are much fuller than the MT
  Pentateuch (logit 3.6, 5.3 and 5.4), and all three show the suffix
  interaction (+2.5, +1.5, +2.2) and the I-yod interaction (-2.4, -2.6,
  -2.9). The QSP pattern is not a 1QIsaa effect.
- **Prior sd 1.5 and 4:** the suffix, prefix, I-yod and ayin-ayin effects
  and the interactions hold. The corpus-group differences shrink with sd 1.5
  (MT LBH 0.92 [-0.54, 2.33], pd 0.89; MT other books and non-QSP pd 0.97)
  and grow with sd 4 (pd 0.986-0.999). The order of the groups is the same;
  the size of the MT LBH vs Pentateuch difference rests partly on the prior.

## Model checks

`verify_model()` (check_ptca_trace, _dens, _ppcheck_*), posterior predictive
checks per corpus group and suffix (`check_ptca_ppc_groups`), per corpus and
verb class (`check_ptca_ppc_verb_classes`) and for the largest lexemes
(`check_ptca_ppc_lexemes`):

- Convergence fine (see above). Bayes R2 0.55. In-sample accuracy 0.90
  (sensitivity 0.75, specificity 0.96; optimistic). LOO: 45 observations
  with Pareto k > 0.7 (0.8%); LOO is not used for model choice.
- The observed shares lie within the 95% predictive intervals in all 12
  corpus group x suffix cells (e.g. MT Pentateuch 9.4% / 1.7% observed vs
  9.6% / 2.0% predicted; QSP 85.5% / 86.1% vs 85.4% / 85.9%), in all verb
  classes per corpus (I-nun, not in the model, too: MT 9.6% vs 10.5%), and
  for the largest lexemes. <FH[ is slightly overpredicted (12.9% vs 15.8%,
  at the lower edge of the interval), >MR[ too (14.5% vs 18.5%).

## Comparison with the book (section 9.2, manuscript 2026-09-10)

- The refitted n3 (`table_ptca_n3_fixed_effects.csv`) gives the same picture
  as M7 for the effects that are credible in both: suffix -2.35, prefix
  -1.49, I-yod 2.70, ayin-ayin 2.33 (all for the MT Pentateuch), QSP 5.57,
  QSP x suffix +2.26, QSP x I-yod -3.14, and the prefix interactions with MT
  Former Prophets, MT LBH, MT other books, non-QSP other and QSP.
- In n3, six coefficients rest on the prior alone (SE about 2.1-2.5, close to
  the prior sd 2.5): non-QSP LBH x suffix, prefix, ayin-ayin and I-yod, and
  ayin-ayin x non-QSP Pentateuch and Former Prophets. In the book's Table
  9.16 (other priors) the same terms have SE about 5. They should not be
  reported as estimates.
- n3 predicts clearly worse than M7 in the k-fold (elpd -41.5 vs -12.2
  relative to M3e) and splits the non-QSP scrolls into groups of 7 and 36
  forms. M7 keeps the same credible effects with fewer parameters.
- Points in the book to revise: the non-QSP subgroups
  (one group), "suffix" (= suffix or ending, with the new ending decisions in
  "Suffix or ending"), interactions reported but not credible, and the
  k-fold result instead of Bayes factors (`../TODO.md` section 12).
