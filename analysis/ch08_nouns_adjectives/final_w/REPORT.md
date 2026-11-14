# Final syllable, optional waw (§8.2.2) — analysis report

*Script: `final_w/analysis.R`. Figures and tables: `final_w/figures/`.
Fitting run approved by the author on 2026-10-22; fits, grouped k-folds,
k-fold over forms and robustness fits 2026-10-29 to 2026-11-01; prior-
sensitivity fits 2026-11-01. Final model **M6** (`corpus_group * has_suffix
+ corpus_group * has_prefix`; author, 2026-11-01).*

Intervals: median with 95% quantile interval (66% in the figures), logit
scale unless an odds ratio (OR) is given; pd = probability of direction;
credible = pd ≥ 0.975. Reference levels: MT Pentateuch, no suffix, no prefix.

## Summary

- Of the 19,651 forms (376 lexemes), 8,783 (45%) are full. QSP is mostly
  full (84%); the MT Pentateuch is the most defective group (26%), the other
  groups lie between 40% and 51%. >LHJM/ alone has 4,079 forms (21%), 94% of
  them defective.
- **Corpus groups.** Against the MT Pentateuch, without affixes: QSP +4.27
  [2.62, 5.89], SP +2.64, MT other books +2.15, non-QSP +1.73 (all
  credible); MT Former Prophets and MT LBH not credible.
- **The suffix is the strongest effect.** It lowers fullness strongly in
  every group except QSP: SP −5.70, non-QSP −4.77, MT Pentateuch −4.66
  [−5.22, −4.11], MT other books −3.99, MT Former Prophets −3.40, MT LBH
  −3.04; QSP −0.01 (pd 0.51: no suffix effect at all).
- **The prefix lowers fullness in the MT Pentateuch** (−1.64 [−2.06,
  −1.23]) and a little in the MT Former Prophets (−0.68); in the other
  groups it has no credible effect (all six prefix interactions credible).
- **The lexeme decides much of the rest** (SD between lexemes within books
  5.9, between books 1.08), but less than in single_w (10.0).
- **Model choice.** Unlike single_w and first_w, both k-folds prefer M6: the
  grouped k-fold (nB −36.5, SE 6.4; M4 −66.4, SE 6.5) and the k-fold over
  forms (M3 −45.1, SE 12.5).
- Against the book: the book's model nB gives nearly the same estimates with
  the new data. Suffix × SP and prefix × non-QSP rest on >LHJM/.

## Descriptive results

`table_finalw_groups.csv`, `_groups_all`, `_suffix`, `_prefix`,
`_suffix_without_elohim`, `_prefix_without_elohim`, `_qsp_isaiah`,
`_lexemes`, `_lexeme_frequencies`, `_book_lexemes`, `_parallel_counts`, and
the tables of §8.2.2.4 (`_mqwm_pentateuch`, `_arwn_sp`, `_arwn_scrolls`,
`_gdwl_parallels`, `_bkr_prefix`):

| Corpus group | n | full | without / with suffix | without / with prefix |
|---|---|---|---|---|
| MT Pentateuch | 3526 | 922 (26%) | 716/1496 (48%) / 206/2030 (10%) | 530/2330 (23%) / 392/1196 (33%) |
| MT Former Prophets | 2424 | 991 (41%) | 695/1023 (68%) / 296/1401 (21%) | 482/1444 (33%) / 509/980 (52%) |
| MT LBH | 1855 | 882 (48%) | 486/630 (77%) / 396/1225 (32%) | 395/945 (42%) / 487/910 (54%) |
| MT other books | 5310 | 2717 (51%) | 1582/2422 (65%) / 1135/2888 (39%) | 1678/3604 (47%) / 1039/1706 (61%) |
| SP | 3661 | 1447 (40%) | 984/1546 (64%) / 463/2115 (22%) | 724/2417 (30%) / 723/1244 (58%) |
| Non-QSP | 1579 | 729 (46%) | 441/652 (68%) / 288/927 (31%) | 465/1090 (43%) / 264/489 (54%) |
| QSP | 1296 | 1095 (84%) | 448/551 (81%) / 647/745 (87%) | 735/891 (82%) / 360/405 (89%) |

- **Data.** 19,651 forms of 376 lexemes (book text 19,639 / 376; stored old
  fit 19,588 / 373).
- **Suffix and prefix in the raw shares.** Suffixed forms are much more
  defective in all groups except QSP, as in the model. Prefixed forms are
  fuller in every group, while the model gives a negative or no prefix
  effect within book × lexeme. The raw difference probably comes from the
  lexeme mix (lexemes that are often full occur more often with a prefix).
  It is not due to >LHJM/ alone: without it, prefixed forms are still fuller
  in every group (`table_finalw_prefix_without_elohim.csv`; MT Pentateuch
  36% vs 32%). Not checked lexeme by lexeme.
- **Non-QSP by group of books** (`table_finalw_groups_all.csv`):
  Pentateuch 297/755 (39%), Former Prophets 73/119 (61%), LBH 19/31 (61%),
  other 340/674 (50%).
- **1QIsaa** (`table_finalw_qsp_isaiah.csv`): 1QIsaa I 309/375 (82%),
  1QIsaa II 407/460 (88%), other QSP scrolls 379/461 (82%), MT Isaiah
  459/825 (56%).
- **Lexemes.** Tables 8.2 (ten most frequent lexemes), 8.3 (MQWM/), 8.4-8.6
  (>RWN/), 8.7 (GDWL/ vs SP) and 8.9 (BKR/) agree exactly with the data;
  Table 8.8 differs in one cell (see the comparison with the book).
- **Parallel passages** (scroll vs MT form):

  | Corpus | both defective | both full | MT fuller | scroll fuller |
  |---|---|---|---|---|
  | SP | 2005 | 819 | 87 | 550 |
  | Non-QSP | 761 | 526 | 67 | 180 |
  | QSP | 169 | 591 | 16 | 433 |

  *Recounted 2026-11-05: forms paired by their position in the raw text when the scroll and the MT have
  the same number of forms of the lexeme in the verse (`parallel_forms(occ = raw_occurrences(...))`).*

  All three corpora are more often fuller than the MT than the other way
  round: QSP strongly (433 vs 16), SP (550 vs 87) and non-QSP (180 vs 67).

## Method

- Bernoulli (logit) models in brms with nested random intercepts
  `(1 | scr_book2/lex)`.
- `corpus_group`: MT Pentateuch (reference), MT Former Prophets, MT LBH, MT
  other books, SP, non-QSP, QSP. The book's model nB uses `law_phase3`
  (non-QSP split by group of books).
- Priors: normal(0, 2.5) on the intercept and coefficients, exponential(1)
  on the SDs. The prior predictive check (`check_finalw_prior_predictive`)
  covers the whole range.
- Sampler: 4 chains, warmup 1000 / 3000 iterations (8000 draws); M6 with
  prior sd 4 warmup 2000 / 6000 (16000 draws; author, 2026-11-01), as in
  first_w and single_w.
- Grouped 5-fold k-fold: every scroll-book is left out as a whole. As in
  first_w and single_w (`../KFOLD_ISSUE.md`), an ordinary 5-fold over forms,
  stratified by scroll-book × lexeme, for M2, M3 and M6. No Bayes factors.
- Final model chosen by the credible-effects rules (`analysis/README.md`) and the
  author's decision of 2026-11-01.

## Model comparison

### Grouped k-fold (`table_finalw_kfold.csv`)

All formulas include `(1 | scr_book2/lex)`.

| Model | Fixed part | elpd diff | SE |
|---|---|---|---|
| **M6** | M3 + both interactions | 0 | – |
| nB | has_suffix × law_phase3 + has_prefix × law_phase3 (book) | −36.5 | 6.4 |
| M4 | M3 + corpus_group × suffix | −66.4 | 6.5 |
| M5 | M3 + corpus_group × prefix | −135.0 | 10.9 |
| M3 | corpus_group + has_suffix + has_prefix | −182.2 | 12.6 |
| M2 | corpus_group | −1210.7 | 36.2 |
| M1 | corpus (MT / SP / non-QSP / QSP) | −1582.3 | 39.3 |
| M0 | null | −1987.4 | 43.7 |

Here the grouped k-fold clearly rewards the affix effects and both
interactions. With sd(scr_book2:lex) about 6 (single_w 10, first_w 9) the
lexeme explains less, so population-level effects matter more for a
held-out scroll-book.

### k-fold over forms (`table_finalw_kfold_forms.csv`)

| Model | elpd diff | SE |
|---|---|---|
| **M6** | 0 | – |
| M3 | −45.1 | 12.5 |
| M2 | −758.1 | 42.4 |

Both k-folds agree: the affix effects improve the prediction strongly (M2 →
M3), the interactions clearly (M3 → M6, 3.6 SE).

### Drop-one comparison for M6 (rule 4)

`table_finalw_kfold_drop_one.csv` (grouped k-fold):

| Effect dropped | Model | elpd diff | SE |
|---|---|---|---|
| corpus_group × suffix | M5 | −135.0 | 10.9 |
| corpus_group × prefix | M4 | −66.4 | 6.5 |

Dropping either interaction makes the prediction clearly worse.

## Final model M6

`has_vowel_letter ~ corpus_group * has_suffix + corpus_group * has_prefix +
(1 | scr_book2/lex)`

Figures and tables: `fig_finalw_effects` / `table_finalw_effects.csv`,
`table_finalw_predicted.csv`, `table_finalw_fixed_effects.csv`.

| Parameter | Estimate [95%] | pd |
|---|---|---|
| Intercept | 1.53 [0.46, 2.72] | 1 |
| MT other books | 2.13 [0.74, 3.40] | 1 |
| SP | 2.60 [0.85, 4.17] | 1 |
| Non-QSP | 1.72 [0.37, 3.08] | 0.99 |
| QSP | 4.27 [2.62, 5.89] | 1 |
| Suffix (MT Pentateuch) | −4.66 [−5.22, −4.11] | 1 |
| Prefix (MT Pentateuch) | −1.64 [−2.06, −1.23] | 1 |
| MT Former Prophets × suffix | 1.25 [0.33, 2.14] | 1 |
| MT LBH × suffix | 1.62 [0.73, 2.47] | 1 |
| SP × suffix | −1.05 [−2.06, −0.12] | 0.99 |
| QSP × suffix | 4.65 [3.51, 5.80] | 1 |
| MT Former Prophets × prefix | 0.96 [0.27, 1.65] | 1 |
| MT LBH × prefix | 1.58 [0.95, 2.22] | 1 |
| MT other books × prefix | 1.45 [0.92, 2.00] | 1 |
| SP × prefix | 2.00 [1.26, 2.73] | 1 |
| Non-QSP × prefix | 1.11 [0.25, 1.97] | 0.99 |
| QSP × prefix | 1.67 [0.71, 2.64] | 1 |
| sd(scr_book2) | 1.08 [0.53, 1.66] | |
| sd(scr_book2:lex) | 5.90 [5.46, 6.37] | |

Not credible: MT Former Prophets 0.94 [−0.89, 2.62], MT LBH 1.45 [−0.29,
3.16], MT other books × suffix 0.67 [−0.04, 1.39] (pd 0.97), non-QSP ×
suffix −0.13 [−1.20, 0.90].

**Total effects per corpus group** (main effect + interaction; logit, pd;
credible in bold):

| Effect | MT Pent. | MT Former Pr. | MT LBH | MT other | SP | Non-QSP | QSP |
|---|---|---|---|---|---|---|---|
| Corpus (vs MT Pent.) | – | 0.98 .859 | 1.46 .948 | **2.15 .998** | **2.64 .998** | **1.73 .992** | **4.27 1** |
| Suffix | **−4.66 1** | **−3.40 1** | **−3.04 1** | **−3.99 1** | **−5.70 1** | **−4.77 1** | −0.01 .509 |
| Prefix | **−1.64 1** | **−0.68 .993** | −0.05 .590 | −0.19 .850 | 0.36 .877 | −0.52 .911 | 0.03 .524 |

- **Predicted probability of full spelling** (typical book and lexeme,
  `re_formula = NA`): MT Pentateuch without affix 82% [61, 94], with a prefix
  47% [23, 75], with a suffix 4.1% [1.5, 12.8]; SP without affix 98%, with a
  suffix 17%; QSP 99.7% in all cells. With an SD of 6 between lexemes these
  numbers describe a lexeme of average fullness only; the odds ratios are
  the better summary.
- **Why this model.**
  - The corpus groups, suffix, prefix and ten interactions are credible
    (rule 1).
  - Both k-folds prefer M6 to every other model; dropping either interaction
    is clearly worse (rule 4).
  - Suffix × SP and prefix × non-QSP rest on >LHJM/ (rule 3(i); next
    section).

## Robustness

`fig_finalw_robustness`, `table_finalw_robustness.csv`,
`table_finalw_1qisaa_split.csv`. Total effects (logit, pd):

| Effect | M6 | no >LHJM/ | no 1QIsaa | prior sd 1.5 | prior sd 4 |
|---|---|---|---|---|---|
| MT other books | 2.15 .998 | 2.17 .999 | 2.18 .998 | 1.39 .982 | 2.54 .999 |
| SP | 2.64 .998 | 2.56 .997 | 2.67 .998 | 1.70 .979 | 3.11 .999 |
| Non-QSP | 1.73 .992 | 1.95 .997 | 1.78 .993 | 1.00 .947 | 2.13 .997 |
| QSP | 4.27 1 | 4.01 1 | 4.11 1 | 3.36 1 | 4.75 1 |
| Suffix, MT Pent. | −4.66 1 | −4.56 1 | −4.67 1 | −4.44 1 | −4.72 1 |
| Suffix, MT Former Pr. | −3.40 1 | −3.30 1 | −3.42 1 | −3.40 1 | −3.43 1 |
| Suffix, MT LBH | −3.04 1 | −2.97 1 | −3.04 1 | −3.02 1 | −3.07 1 |
| Suffix, MT other | −3.99 1 | −3.82 1 | −4.02 1 | −3.96 1 | −4.01 1 |
| Suffix, SP | −5.70 1 | −5.47 1 | −5.74 1 | −5.56 1 | −5.76 1 |
| Suffix, non-QSP | −4.77 1 | −3.78 1 | −4.85 1 | −4.74 1 | −4.83 1 |
| Suffix, QSP | −0.01 .509 | −0.03 .522 | −0.58 .722 | −0.21 .668 | 0.04 .532 |
| Prefix, MT Pent. | −1.64 1 | −1.63 1 | −1.63 1 | −1.51 1 | −1.69 1 |
| Prefix, MT Former Pr. | −0.68 .993 | −0.68 .991 | −0.69 .994 | −0.68 .991 | −0.69 .992 |
| Prefix, non-QSP | −0.52 .911 | **−0.87 .989** | −0.55 .924 | −0.52 .911 | −0.56 .929 |
| Prefix, QSP | 0.03 .524 | −0.02 .521 | **2.52 .993** | −0.00 .501 | 0.03 .526 |

- **The suffix in all six non-QSP groups**, **the prefix in the MT
  Pentateuch and MT Former Prophets** and **QSP** are credible in every
  variant.
- **Without >LHJM/** (15,572 forms left): suffix × SP and prefix × non-QSP
  are no longer credible; suffix × MT other books becomes credible (+0.74,
  pd 0.980). The suffix effect in non-QSP becomes weaker (−3.78 instead of
  −4.77), the prefix effect in non-QSP stronger and credible (−0.87). These
  interactions rest on >LHJM/ (rule 3(i)); the total suffix effect in SP
  stays strongly credible (−5.47).
- **Without Barr's prefix examples GDWL/, >RWN/, YPWR/** (fitted 2026-11-03,
  author's approval; 18,585 forms): prefix in the MT Pentateuch −1.28
  [−1.74, −0.83] (M6 −1.64) and in MT Former Prophets −0.65 [−1.28, −0.03]
  (pd 0.980). Both stay credible, so the prefix effect does **not** rest on
  Barr's examples, unlike first_w (<WLM/, JWBL/). The suffix effects hardly
  change (MT Pentateuch −4.68, SP −5.08); no other affix effect changes its
  credibility (the corpus contrasts were not checked for this fit). Max Rhat 1.004, min bulk ESS 492, no divergences.
- **Without 1QIsaa** the prefix effect in the other QSP scrolls becomes
  positive and credible (+2.52): the prefix lowers fullness in 1QIsaa, not in
  the other QSP scrolls. The QSP main effect and suffix effects hardly
  change.
- **1QIsaa split** (other QSP, 1QIsaa I, 1QIsaa II as groups): against the MT
  Pentateuch, the other QSP scrolls +3.67 [1.61, 5.74], 1QIsaa II +3.44
  [0.36, 6.07] (pd 0.985), 1QIsaa I +2.59 [−0.36, 5.19] (pd 0.96, not
  credible). In none of the three groups is the suffix effect credible; the
  prefix effect is credible only in the other QSP scrolls (+2.50, pd 0.993).
- **Prior sensitivity**: the intercept is 2.20, 1.51 and 1.15 with sd 1.5,
  2.5 and 4. With sd 1.5 the corpus effects shrink (QSP 3.36, SP 1.70) and
  the non-QSP main effect is no longer credible (pd 0.947); with sd 4 all
  stay credible. The affix effects hardly change.

## Model checks

- **Convergence.** M6 (1000 / 3000): max Rhat 1.007, no divergent
  transitions (`check_finalw_trace`, `_dens`). The lowest bulk ESS is for
  sd(scr_book2): 759 (ratio 0.095). Prior sd 1.5: max Rhat 1.006, ESS 668.
  Prior sd 4: with 1000 / 3000 max Rhat 1.015 (sd(scr_book2), ESS 333);
  refitted with 2000 / 6000: max Rhat 1.002, ESS 1455.
- **Posterior predictive checks** (`check_finalw_ppcheck_bars`, `_mean`):
  fine.
- **Groups** (`check_finalw_ppc_groups`): the observed share lies inside the
  95% predictive interval in all 14 corpus group × suffix cells.
- **Lexemes** (`check_finalw_ppc_lexemes`): >LHJM/, CLC/, GDWL/, MQWM/,
  >DWN/ and the other lexemes lie inside the 95% interval. Three nearly
  always defective lexemes lie just below it: PR<H/ (0.9% full observed,
  interval 1.2-3.7%), M>D/ (0.7%; 1.8-5.6%) and N>M/ (0.9%; 1.4-5.2%). The
  normal random effects cannot quite reach such extreme lexemes; harmless
  for the fixed effects.
- **Bayes R2** 0.84 [0.83, 0.84].
- **LOO** (for completeness; the k-fold is used for comparison): elpd −4057.8
  (SE 71.8), 2,368 observations (12.1%) with Pareto k > 0.7, expected with
  many small book × lexeme groups.
- **In-sample classification**: accuracy 0.96, sensitivity 0.97, specificity
  0.96.

## Comparison with the book (§8.2.2, manuscript 2026-09-10)

`table_finalw_book_model.csv`: the book's model nB refitted with the new
priors and data, against the stored old fit (19,588 forms).

| Parameter | nB (new) | old fit |
|---|---|---|
| Intercept | 1.75 [0.70, 2.94] | 1.13 [0.00, 2.36] |
| Suffix (MT Pentateuch) | −4.65 [−5.20, −4.12] | −4.81 [−5.42, −4.25] |
| Prefix (MT Pentateuch) | −1.63 [−2.05, −1.21] | −1.71 [−2.16, −1.26] |
| MT Other | 1.92 [0.52, 3.16] | 2.60 [1.14, 3.99] |
| SP | 2.41 [0.61, 4.03] | 3.25 [1.37, 4.98] |
| Non-QSP LBH | 2.75 [−0.67, 6.24] | 6.49 [1.29, 12.14] |
| Non-QSP Other | 2.46 [0.93, 3.99] | 3.23 [1.52, 4.96] |
| QSP | 4.06 [2.37, 5.66] | 4.86 [3.09, 6.63] |
| MT Former Prophets × suffix | 1.23 [0.30, 2.12] | 1.39 [0.42, 2.32] |
| MT LBH × suffix | 1.61 [0.77, 2.46] | 1.76 [0.86, 2.67] |
| MT Other × suffix | 0.65 [−0.04, 1.36] | 0.78 [0.03, 1.52] |
| SP × suffix | −1.07 [−2.08, −0.11] | −1.04 [−2.09, −0.04] |
| Non-QSP Former Prophets × suffix | 2.66 [0.32, 4.96] | 3.47 [0.79, 6.11] |
| QSP × suffix | 4.63 [3.48, 5.77] | 4.85 [3.65, 6.05] |
| MT Former Prophets × prefix | 0.94 [0.23, 1.62] | 1.02 [0.29, 1.74] |
| MT LBH × prefix | 1.57 [0.93, 2.20] | 1.66 [0.99, 2.32] |
| MT Other × prefix | 1.45 [0.90, 1.99] | 1.53 [0.95, 2.11] |
| SP × prefix | 1.98 [1.26, 2.70] | 2.08 [1.30, 2.84] |
| Non-QSP Other × prefix | 1.35 [0.19, 2.48] | 1.43 [0.25, 2.64] |
| QSP × prefix | 1.65 [0.69, 2.62] | 1.74 [0.71, 2.76] |
| sd(scr_book2) | 1.16 | 1.12 |
| sd(scr_book2:lex) | 5.92 | 6.00 |

- **The book's model.** The new fit gives nearly the same estimates; the
  corpus effects are somewhat smaller (narrower priors: sd 2.5). Two terms
  are no longer credible: non-QSP LBH (31 forms; old 6.49 [1.29, 12.14])
  and MT Other × suffix (pd 0.97). The conclusions of §8.2.2 stand.
- **M6 and nB** agree: M6 replaces the non-QSP split by book group with one
  non-QSP group. The grouped k-fold prefers M6 (nB −36.5, SE 6.4).
  Non-QSP Former Prophets × suffix (119 forms) is credible in nB only.
- **Model choice.** The book chose nB by Bayes factor; both k-folds now
  prefer M6.
- **Counts.** 19,651 forms of 376 lexemes (book 19,639 / 376).
- **Table 8.8** (GDWL/, MT vs non-QSP): "defective in both" is 12 in the
  data, 14 in the book; the other three cells agree.
- **Table 8.6**, 2 Sam 6:4: the book gives MT הארון; the MT (and the data)
  read ארון (עִם אֲרוֹן הָאֱלֹהִים).
- **§8.2.2.4** "23 {'21'?} times": >RWN/ occurs 23 times in the scrolls, all
  non-QSP and full.

## Points for the author

1. **Final model M6** (agreed 2026-11-01). Wording: suffix × SP and prefix ×
   non-QSP rest on >LHJM/ (rule 3(i)); the non-QSP main effect is not
   credible with prior sd 1.5 (pd 0.947).
2. **Prefix in QSP**: no effect in QSP as a whole, but +2.52 (credible)
   without 1QIsaa; the prefix lowers fullness in 1QIsaa against the other
   QSP scrolls. Worth a sentence in §8.2.2 or chapter 11.
3. **Raw prefix shares vs model**: prefixed forms are fuller in the raw
   shares of every group, but the model gives a negative or no prefix
   effect within book × lexeme. Not due to >LHJM/ alone (the raw pattern
   stays without it); a lexeme-mix effect, not checked lexeme by lexeme.
   The book's text on the raw prefix shares should say this.
4. **Book corrections:** counts (19,651 forms), Table 8.8, Table 8.6 (2 Sam
   6:4), "23 {'21'?}", and the model-choice text of §8.2.2 (Bayes factors).
