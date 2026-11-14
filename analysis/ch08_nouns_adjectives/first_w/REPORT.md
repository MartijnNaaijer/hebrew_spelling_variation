# First syllable, optional waw (§8.4.2) — analysis report

*Script: `first_w/analysis.R`. Figures and tables: `first_w/figures/`. Model
set approved by the author on 2026-10-21; fits and grouped k-folds
2026-10-21/23; k-fold over forms 2026-10-27; prior-sensitivity fits
2026-10-28. Final model **M6** (`corpus_group * has_suffix + corpus_group *
has_prefix`; author, 2026-10-28, option (a) of `../KFOLD_ISSUE.md`).*

Intervals: median with 95% quantile interval (66% in the figures), logit
scale unless an odds ratio (OR) is given; pd = probability of direction;
credible = pd ≥ 0.975. Reference levels: MT Pentateuch, no suffix, no prefix.

## Summary

- Of the 9,752 forms, 2,644 (27%) are full. Only QSP is mostly full (75%);
  the other groups lie between 16% and 29%.
- **QSP is the one large corpus effect.** QSP is far fuller than the MT
  Pentateuch (logit +9.93 [7.66, 12.40]). No other corpus group is credibly
  different (largest MT Former Prophets −1.76, pd 0.92).
- **The prefix lowers fullness in most MT groups**: MT Pentateuch −2.26
  [−3.16, −1.42], MT Former Prophets −1.37, MT other books −1.29, and also
  in non-QSP (−1.91). It has no effect in MT LBH, SP and QSP (credible
  interactions LBH, SP and QSP × prefix). In the MT Pentateuch the effect
  rests on Barr's examples <WLM/ and JWBL/: without them −0.96, pd 0.972
  (rule 3(i)).
- **The suffix lowers fullness in the MT** (Pentateuch −1.20, pd 0.984; LBH
  −2.55; other books −1.97), not in SP (0.01) and not in non-QSP (+1.15;
  non-QSP × suffix +2.36, credible). In the MT Pentateuch the suffix effect
  is weak: pd 0.970 with prior sd 4.
- **The lexeme decides most of the rest.** KHN/, QDC/, >HL/, XRB/, M>D/ and
  N>M/ are almost always defective, <WLM/, MW<D/ and TW<BH/ almost always
  full (SD between lexemes within books 10.0, between books 0.70).
- **Model choice.** The grouped k-fold prefers the book's model nB (M6
  −41.6, SE 6.2), but it cannot use the nested lexeme effects
  (`../KFOLD_ISSUE.md`). The k-fold over forms prefers M6 (M3 −15.7, SE 6.6;
  M2 −42.6, SE 10.3). All terms of M6 that the rules require are credible.
- Against the book: the prefix pattern of the book's model (has_prefix ×
  law_phase3) is confirmed; the suffix effects in the MT and the non-QSP ×
  suffix interaction are new.

## Descriptive results

`table_firstw_groups.csv`, `_groups_all`, `_suffix`, `_prefix`,
`_qsp_isaiah`, `_lexemes`, `_book_lexemes`, `_book_parallels`,
`_book_prefix_tables`, `_olam_parallels`, `_parallel_passages`,
`_parallel_counts`:

| Corpus group | n | full | without / with suffix | without / with prefix |
|---|---|---|---|---|
| MT Pentateuch | 1787 | 414 (23%) | 257/1352 (19%) / 157/435 (36%) | 301/863 (35%) / 113/924 (12%) |
| MT Former Prophets | 1023 | 167 (16%) | 115/643 (18%) / 52/380 (14%) | 73/465 (16%) / 94/558 (17%) |
| MT LBH | 805 | 158 (20%) | 105/402 (26%) / 53/403 (13%) | 58/283 (21%) / 100/522 (19%) |
| MT other books | 2951 | 744 (25%) | 455/1770 (26%) / 289/1181 (24%) | 412/1798 (23%) / 332/1153 (29%) |
| SP | 1836 | 486 (26%) | 298/1387 (21%) / 188/449 (42%) | 314/882 (36%) / 172/954 (18%) |
| Non-QSP | 739 | 217 (29%) | 138/472 (29%) / 79/267 (30%) | 124/385 (32%) / 93/354 (26%) |
| QSP | 611 | 458 (75%) | 279/351 (79%) / 179/260 (69%) | 252/337 (75%) / 206/274 (75%) |

- **Data.** 9,752 forms of 149 lexemes (book text 9,741 / 148; stored old fit
  9,718 / 147).
- **The raw shares mislead.** In the MT Pentateuch and SP suffixed forms are
  fuller (36% and 42%), but within book × lexeme the model finds no or a
  negative suffix effect, so the raw difference comes from the lexeme mix
  (not checked lexeme by lexeme). The prefix difference in the MT Pentateuch
  (35% vs 12%) shrinks within lexemes to −0.96 once <WLM/ and JWBL/ are left
  out (Robustness).
- **1QIsaa** (`table_firstw_qsp_isaiah.csv`): 1QIsaa I 93/168 (55%),
  1QIsaa II 183/229 (80%), other QSP scrolls 182/214 (85%), MT Isaiah 88/398
  (22%).
- **Lexemes.** Tables 8.25 (>WYR/), 8.26-8.28, 8.30 (<WLM/) and 8.31
  (JWBL/) agree exactly with the data; Table 8.29 differs by one form (see
  the comparison with the book).
- **Parallel passages** (scroll vs MT form):

  | Corpus | both defective | both full | MT fuller | scroll fuller |
  |---|---|---|---|---|
  | SP | 1282 | 398 | 8 | 70 |
  | Non-QSP | 484 | 149 | 19 | 61 |
  | QSP | 145 | 148 | 4 | 280 |

  *Recounted 2026-11-05: forms paired by their position in the raw text when the scroll and the MT have
  the same number of forms of the lexeme in the verse (`parallel_forms(occ = raw_occurrences(...))`).*

  All three corpora are more often fuller than the MT than the other way
  round; QSP strongly (280 vs 4), SP and non-QSP moderately (70 vs 8, 61 vs
  19).

## Method

- Bernoulli (logit) models in brms with nested random intercepts
  `(1 | scr_book2/lex)`.
- `corpus_group`: MT Pentateuch (reference), MT Former Prophets, MT LBH, MT
  other books, SP, non-QSP, QSP. The book's model nB uses `law_phase3`
  (non-QSP split by group of books).
- Priors: normal(0, 2.5) on the intercept and coefficients, exponential(1)
  on the SDs. The prior predictive check (`check_firstw_prior_predictive`)
  covers the whole range.
- Sampler: 4 chains, warmup 1000 / 3000 iterations (8000 draws); M6 with
  prior sd 4 warmup 2000 / 6000 (16000 draws; author, 2026-10-28), because
  the first fit had max Rhat 1.021.
- Grouped 5-fold k-fold: every scroll-book is left out as a whole. As a check
  (`../KFOLD_ISSUE.md`, option (c)), an ordinary 5-fold over forms,
  stratified by scroll-book × lexeme, for M2, M3 and M6. No Bayes factors.
- Final model chosen by the credible-effects rules (`analysis/README.md`) and the
  author's decision of 2026-10-28.

## Model comparison

### Grouped k-fold (`table_firstw_kfold.csv`)

All formulas include `(1 | scr_book2/lex)`.

| Model | Fixed part | elpd diff | SE |
|---|---|---|---|
| nB | has_prefix × law_phase3 (the book's model) | 0 | – |
| M1 | corpus (MT / SP / non-QSP / QSP) | −10.7 | 6.4 |
| M2 | corpus_group | −24.3 | 5.4 |
| **M6** | M3 + both interactions | −41.6 | 6.2 |
| M4 | M3 + corpus_group × suffix | −45.3 | 7.2 |
| M5 | M3 + corpus_group × prefix | −57.4 | 5.3 |
| M3 | corpus_group + has_suffix + has_prefix | −59.8 | 6.6 |
| M0 | null | −459.3 | 22.1 |

- The corpus groups (QSP) carry the predictive information for new books
  (M0 → M2 about +435).
- The affix terms make the grouped k-fold worse (M2 → M3 −35.5). With
  sd(scr_book2:lex) about 10, a held-out scroll-book gets new book × lexeme
  effects, so the grouped k-fold scores only population-level predictions and
  cannot use the lexeme. Effects estimated within lexemes then fit the
  held-out books worse (`../KFOLD_ISSUE.md`, "Why the k-fold behaves like
  this"). Among the models with affixes, the interactions help (M6 vs M3
  +18.1).

### The earlier model with corpus_group (nB_cg; 2026-11-10)

The author does not want doc_group (`law_phase3`) in the book's models.
nB_cg is nB with `corpus_group` instead: `corpus_group * has_prefix +
(1 | scr_book2/lex)`, no suffix (`../tools/fit_firstw_nb_cg.R`). Same data as M6 (checked row by row), same
folds as above. Max Rhat 1.01, no divergences.

| k-fold | nB_cg against | elpd diff | SE |
|---|---|---|---|
| grouped | nB (doc_group) | +3.3 | 2.5 |
| grouped | M2 | +27.6 | 5.0 |
| grouped | M6 | +44.9 | 5.9 |
| over forms | M6 | −19.8 | 7.0 |
| over forms | M3 | −4.2 | 7.7 |
| over forms | M2 | +22.8 | 8.1 |

- nB_cg is the best model in the grouped k-fold (just ahead of nB, within
  2 SE). M6 −44.9 (SE 5.9).
- The k-fold over forms still prefers M6 (nB_cg −19.8, SE 7.0, 2.8 SE).
- Estimates (`table_firstw_nb_cg_fixed_effects.csv`, `_total_effects.csv`)
  as in nB: prefix in the MT Pentateuch −2.36 [−3.21, −1.55]; credible
  interactions with MT LBH (2.05), MT other books (1.19), SP (3.13) and QSP
  (2.38); QSP 9.42 [7.33, 11.74]; total prefix effect credible in MT
  Pentateuch, MT Former Prophets (−1.17, pd 0.978), MT other books (−1.17)
  and non-QSP (−1.69, pd 0.984).

### k-fold over forms (`table_firstw_kfold_forms.csv`)

| Model | elpd diff | SE |
|---|---|---|
| **M6** | 0 | – |
| M3 | −15.7 | 6.6 |
| M2 | −42.6 | 10.3 |

A held-out form keeps its known book × lexeme effect. The affix effects
(M2 → M3 +26.9) and the interactions (M3 → M6 +15.7, 2.4 SE) improve the
prediction of new forms.

### Drop-one comparison for M6 (rule 4)

`table_firstw_kfold_drop_one.csv` (grouped k-fold):

| Effect dropped | Model | elpd diff | SE |
|---|---|---|---|
| corpus_group × suffix | M5 | −15.8 | 3.8 |
| corpus_group × prefix | M4 | −3.7 | 3.7 |

The suffix interaction clearly helps; the prefix interaction does not change
the grouped k-fold (1 SE). The k-fold over forms has no M4 or M5.

## Final model M6

`has_vowel_letter ~ corpus_group * has_suffix + corpus_group * has_prefix +
(1 | scr_book2/lex)`

Figures and tables: `fig_firstw_effects` / `table_firstw_effects.csv`,
`table_firstw_predicted.csv`, `table_firstw_fixed_effects.csv`.

| Parameter | Estimate [95%] | pd |
|---|---|---|
| Intercept | −4.26 [−5.84, −2.70] | 1 |
| QSP | 9.95 [7.66, 12.40] | 1 |
| Suffix (MT Pentateuch) | −1.21 [−2.35, −0.09] | 0.984 |
| Prefix (MT Pentateuch) | −2.27 [−3.16, −1.42] | 1 |
| Non-QSP × suffix | 2.36 [0.34, 4.43] | 0.990 |
| MT LBH × prefix | 1.81 [0.43, 3.18] | 1.00 |
| SP × prefix | 3.08 [1.59, 4.61] | 1 |
| QSP × prefix | 2.28 [0.97, 3.61] | 1 |
| sd(scr_book2) | 0.70 [0.03, 1.78] | |
| sd(scr_book2:lex) | 9.98 [8.70, 11.43] | |

The other corpus groups and interactions are not credible (pd 0.56-0.96;
MT other books × prefix 0.97 [−0.13, 2.08], pd 0.96).

**Total effects per corpus group** (main effect + interaction; logit, pd;
credible in bold):

| Effect | MT Pent. | MT Former Pr. | MT LBH | MT other | SP | Non-QSP | QSP |
|---|---|---|---|---|---|---|---|
| Corpus (vs MT Pent.) | – | −1.76 .920 | 0.45 .635 | −0.39 .659 | −1.22 .855 | −0.48 .679 | **9.93 1** |
| Suffix | **−1.20 .984** | −1.77 .968 | **−2.55 1** | **−1.97 1** | 0.01 .507 | 1.15 .896 | −1.07 .962 |
| Prefix | **−2.26 1** | **−1.37 .987** | −0.45 .799 | **−1.29 1** | 0.80 .893 | **−1.91 .987** | 0.02 .516 |

- **Predicted probability of full spelling** (`re_formula = NA`): for a
  typical book and lexeme the model predicts almost always defective (MT
  Pentateuch without affix 1.4% [0.3, 6.3]; QSP 99.7% [98.0, 99.9]). With
  an SD of 10 between lexemes the "typical lexeme" is a defective one, so
  these numbers say little; the odds ratios are the better summary.
- **Why this model** (option (a), author 2026-10-28).
  - QSP, the suffix and prefix effects and four interactions are credible
    (rule 1).
  - The grouped k-fold cannot judge effects within lexemes (rule 4; see
    above); the k-fold over forms prefers M6 to M3 and M2.
  - The prefix effect in the MT Pentateuch rests on <WLM/ and JWBL/ (rule
    3(i)); it is reported as a lexeme effect (next section).
  - Drop-one: the prefix interaction does not improve the grouped k-fold
    (−3.7, SE 3.7), but three of its terms are credible and robust.

## Robustness

`fig_firstw_robustness`, `table_firstw_robustness.csv`,
`table_firstw_1qisaa_split.csv`. Total effects (logit, pd):

| Effect | M6 | no KHN/ QDC/ | no <WLM/ JWBL/ | no 1QIsaa | prior sd 1.5 | prior sd 4 |
|---|---|---|---|---|---|---|
| QSP | 9.93 1 | 8.86 1 | 10.17 1 | 10.52 1 | 7.37 1 | 11.74 1 |
| Suffix, MT Pent. | −1.20 .984 | −1.19 .981 | −1.28 .989 | −1.35 .991 | −1.15 .992 | −1.22 .970 |
| Suffix, MT Former Pr. | −1.77 .968 | −1.88 .968 | −2.16 .970 | −1.91 .973 | −1.71 .978 | −1.80 .956 |
| Suffix, MT LBH | −2.55 1 | −2.62 1 | −2.20 .999 | −2.67 1 | −2.33 1 | −2.69 1 |
| Suffix, MT other | −1.97 1 | −2.00 1 | −1.54 .998 | −2.17 1 | −1.83 1 | −2.08 1 |
| Suffix, non-QSP | 1.15 .896 | 1.49 .942 | 2.57 .998 | 1.32 .909 | 0.62 .791 | 1.50 .935 |
| Suffix, QSP | −1.07 .962 | −0.43 .741 | −0.97 .946 | −1.54 .887 | −0.75 .909 | −1.26 .978 |
| Prefix, MT Pent. | −2.26 1 | −2.26 1 | −0.96 .972 | −2.30 1 | −1.84 1 | −2.52 1 |
| Prefix, MT Former Pr. | −1.37 .987 | −1.38 .987 | −0.72 .859 | −1.47 .990 | −1.42 .993 | −1.35 .982 |
| Prefix, MT other | −1.29 1 | −1.31 1 | −1.17 .999 | −1.39 1 | −1.24 1 | −1.33 1 |
| Prefix, SP | 0.80 .893 | 0.90 .913 | 1.34 .976 | 0.86 .898 | 0.46 .789 | 1.00 .932 |
| Prefix, non-QSP | −1.91 .987 | −2.07 .991 | −1.85 .984 | −2.08 .991 | −1.78 .994 | −1.96 .985 |

- **QSP**, the **suffix in MT LBH and MT other books** and the **prefix in
  MT other books and non-QSP** are credible in every variant.
- **Prefix in the MT Pentateuch**: without <WLM/ and JWBL/ −0.96 [−1.97,
  0.02], pd 0.972, just not credible. Barr's examples carry the effect (rule
  3(i)); in the other lexemes the prefix tendency is the same but weaker.
  The prefix in MT Former Prophets also depends on them (−0.72, pd 0.86).
- **Suffix in the MT Pentateuch**: credible in all variants except prior sd
  4 (pd 0.970). Weak.
- **Non-QSP × suffix**: the interaction is credible (2.36, pd 0.990), the
  total suffix effect in non-QSP is not (1.15, pd 0.90), except without
  <WLM/ JWBL/ (2.57, pd 0.998).
- **1QIsaa split** (other QSP, 1QIsaa I, 1QIsaa II as groups): against the MT
  Pentateuch, the other QSP scrolls +9.00 [6.10, 11.94], 1QIsaa II +8.13
  [3.98, 11.52], 1QIsaa I only +3.45 [0.26, 6.53] (pd 0.982). 1QIsaa I is
  much less full than the other QSP texts (55% vs 80-85% observed). No
  affix effect is credible in the three groups.
- **Prior sensitivity**: the intercept is −3.38, −4.25 and −4.97 with sd
  1.5, 2.5 and 4, QSP 7.37, 9.93 and 11.74 (the QSP forms are nearly all
  full, so the prior limits this effect). The affix effects hardly change.

## Model checks

- **Convergence.** M6 (1000 / 3000): max Rhat 1.006, no divergent
  transitions, no transitions at the maximum treedepth
  (`check_firstw_trace`, `_dens`). The lowest bulk ESS is for sd(scr_book2):
  532 (ratio 0.066). Prior sd 1.5: max Rhat 1.007, ESS of sd(scr_book2) 434.
  Prior sd 4 (2000 / 6000): max Rhat **1.011**, ESS of sd(scr_book2) 752, no
  divergences.
- **Posterior predictive checks** (`check_firstw_ppcheck_bars`, `_mean`):
  fine.
- **Groups** (`check_firstw_ppc_groups`): the observed share lies inside the
  95% predictive interval in all 14 corpus group × suffix cells.
- **Lexemes** (`check_firstw_ppc_lexemes`): all eight main lexemes (KHN/,
  QDC/, <WLM/, >HL/, XRB/, M>D/, N>M/, MW<D/) and the other lexemes lie inside
  the 95% interval.
- **Bayes R2** 0.90 [0.89, 0.90].
- **LOO** (for completeness; the k-fold is used for comparison): elpd −1167.4
  (SE 37.9), 1,186 observations (12%) with Pareto k > 0.7, expected with
  many small book × lexeme groups.
- **In-sample classification**: accuracy 0.98, sensitivity 0.97, specificity
  0.99.

## Comparison with the book (§8.4.2, manuscript 2026-09-10)

`table_firstw_book_model.csv`: the book's model nB refitted with the new
priors and data, against the stored old fit (9,718 forms).

| Parameter | nB (new) | old fit |
|---|---|---|
| Intercept | −4.50 [−5.96, −3.13] | −5.55 [−7.55, −3.61] |
| Prefix (MT Pentateuch) | −2.36 [−3.20, −1.57] | −2.77 [−3.73, −1.85] |
| QSP | 9.48 [7.36, 11.66] | 11.90 [9.04, 15.10] |
| MT LBH × prefix | 2.04 [0.78, 3.30] | 2.48 [1.05, 3.91] |
| MT other × prefix | 1.19 [0.15, 2.22] | 1.52 [0.33, 2.73] |
| SP × prefix | 3.13 [1.72, 4.59] | 3.82 [2.21, 5.53] |
| QSP × prefix | 2.37 [1.17, 3.58] | 2.91 [1.55, 4.31] |
| sd(scr_book2) | 0.60 | 0.86 |
| sd(scr_book2:lex) | 9.46 | 10.80 |

- **The book's model.** The new fit gives the same pattern as the old one;
  all estimates are somewhat smaller (narrower priors: sd 2.5). The
  conclusion of §8.4.2.7 on the prefix stands: the prefix lowers fullness in
  the MT Pentateuch, much less in MT LBH, MT other books, SP and QSP.
- **New in M6.**
  - The suffix lowers fullness in the MT (Pentateuch weakly, LBH and other
    books clearly), not in SP and non-QSP. The book's model has no suffix.
  - Non-QSP × suffix (credible).
  - In M6, MT other books × prefix is not credible (0.97, pd 0.96; in nB
    1.19, credible).
- **Barr's examples.** The prefix effect in the MT Pentateuch rests on <WLM/
  and JWBL/; without them it is −0.96 (pd 0.972). The text can say that the
  effect is clear in Barr's examples and only a tendency elsewhere.
- **Model choice.** The book chose nB by Bayes factor. The grouped k-fold
  also prefers nB, but it cannot use the lexeme effects; the k-fold over
  forms prefers M6.
- **Counts.** 9,752 forms of 149 lexemes (book 9,741 / 148).
- **Table 8.29** (<WLM/, MT vs non-QSP): "both full" is 48 in the data, 47
  in the book.

## Points for the author

1. **Final model M6** (agreed 2026-10-28). The wording on the prefix in the
   MT Pentateuch: a lexeme effect of <WLM/ and JWBL/ (rule 3(i)).
2. **Prior sd 4 fit: max Rhat 1.011** after the refit with 2000 / 6000 (was
   1.021; ESS of sd(scr_book2) 752). Just above 1.01; the estimates agree
   with the other two priors. A longer refit is possible but seems
   unnecessary.
3. **ESS of sd(scr_book2)** is 532 in M6 and 434 with prior sd 1.5 (> 400,
   ratio below 0.1). In final_y the same ratio was raised with 2000 / 6000;
   optional here.
4. **Suffix in the MT Pentateuch** is weak (pd 0.970-0.992 across the
   variants): report it as a tendency.
5. **Book corrections:** counts (9,752 / 149), Table 8.29 (48 vs 47), and
   §8.4.2.7 (Bayes factors; the suffix effects and non-QSP × suffix are
   new).
