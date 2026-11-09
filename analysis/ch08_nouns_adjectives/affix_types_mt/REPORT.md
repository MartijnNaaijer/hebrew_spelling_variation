# Affix types in the MT, final waw and yod (§8.5) — analysis report

*Script: `affix_types_mt/analysis.R`. Figures and tables:
`affix_types_mt/figures/`. Fitting run approved by the author on
2026-11-01; candidate models, grouped k-folds and robustness fits 2026-11-01
to 2026-11-02; drop-one models and prior-sensitivity fits 2026-11-02 to
2026-11-03. Final models (author, 2026-11-02): **waw A2** (`nme2 *
corpus_group + prs2 * corpus_group + has_hloc * corpus_group + prefix_type *
corpus_group`) and **yod A3** (`corpus_group + nme2 + prs2 + has_hloc +
prefix_type`), both with `(1 | scr_book2/lex)`.*

Intervals: median with 95% quantile interval (66% in the figures), logit
scale unless an odds ratio (OR) is given; pd = probability of direction;
credible = pd ≥ 0.975. Reference levels: MT Pentateuch, no ending, no
suffix, no he locale, no prefix. "Effect" of a category = difference from
the form without that affix in the same MT group (main effect +
interaction).

## Summary

- **Data.** Waw: 11,517 forms of 260 lexemes, 47% full. Yod: 2,175 forms of
  82 lexemes, 74% full. Only lexemes that vary within the MT. >LHJM/ alone
  has 2,593 waw forms (23%).
- **Question 1 (endings with a vowel letter).** Yes. In waw words -WT
  (−7.1 in the MT Pentateuch) and -JM (−4.9) make the stem more defective
  than the endings without a vowel letter (-H −2.4, -T sg. −2.9, -T pl.
  −3.5, constr. -J −2.2). In yod words -JM is the strongest ending (−5.1).
- **Question 2 (same vowel letter).** Yes for both letters. Waw: -WT is
  stronger than -JM in all four groups (credible in three; MT Pentateuch pd
  0.969) and much stronger than -T pl. Yod: -JM is stronger than -WT (−1.85
  [−3.71, −0.08], pd 0.979). The waw suffix -W (3 m. sg.) also has the
  strongest suffix effect in waw words (−5.2 in the MT Pentateuch); it is
  stronger than -J, -K and -H in most groups.
- **Question 3 (suffixes without a vowel letter).** No difference between
  heavy and light suffixes: -HM vs -H and -KM vs -K are not credible in any
  group (waw) or overall (yod). In waw words all suffixes except -M (3 m.
  pl.) and -NW lower fullness strongly; in yod words no suffix has a
  credible effect.
- **Question 4 (prefix types).** Small effects. Waw: the article (−1.57) and
  the prepositions (−1.05) lower fullness in the MT Pentateuch, the article
  a little in the MT Former Prophets (−0.73); elsewhere no prefix type is
  credible. Article vs conjunction differs only in the MT Pentateuch. The
  grouped k-fold prefers the model with has_prefix (A1) to A2 (−36.5, SE
  4.7), and dropping prefix_type × corpus_group improves A2: the types add
  little for unseen books. Yod: the article makes the stem *fuller* (+1.00
  [0.29, 1.77]), more than the prepositions (+1.39, pd 0.998).
- **Corpus groups.** Waw: the MT Pentateuch is the most defective (MT
  Former Prophets +1.54, LBH +2.53, other books +2.55, all credible). Yod:
  no credible differences between the MT groups.
- **Drop-one (rule 4).** For waw, A2 without nme2 × corpus_group (+39.5, SE
  7.9) and without prefix_type × corpus_group (+17.4, SE 6.2) predicts
  better; for yod, A3 without prs2 (+6.8, SE 2.1). See points for the author.

## Descriptive results

Tables 8.37-8.43 (`table_affix_8_37_waw_endings.csv` … `_8_43_yod_prefixes.csv`),
`table_affix_shares.csv`, `fig_affix_<letter>_<variable>`,
`table_affix_dropped_categories.csv`.

| MT group | waw n | waw full | yod n | yod full |
|---|---|---|---|---|
| MT Pentateuch | 2908 | 874 (30%) | 509 | 389 (76%) |
| MT Former Prophets | 2177 | 977 (45%) | 394 | 240 (61%) |
| MT LBH | 1715 | 878 (51%) | 287 | 210 (73%) |
| MT other books | 4717 | 2669 (57%) | 985 | 780 (79%) |

- **Categories** (author, 2026-10-19): those of Tables 8.34-8.36 plus the 3
  m. pl. suffix -M; categories with fewer than 20 forms dropped with their
  forms. Waw loses only tiny categories (1-7 forms each); yod keeps the
  defective masc. pl. -M (33 forms) but loses the suffixes -J, -KM, -M and
  -NW (4-16 forms each).
- **Yod categories** are small: -M 33, -T pl. 54, -WT 65 forms; suffixes -W
  64, -H 31, -K 28, -HM 20; he locale 22 (MT other books only).
- **Most frequent lexemes.** Waw: >LHJM/ 2593, CLC/ 600, GDWL/ 523, MQWM/
  401, N>M/ 376. Yod: NBJ>/ 307, YDJQ/ 206, ZQN/ 175, NFJ>/ 130.

## Method

- Bernoulli (logit) models in brms with nested random intercepts
  `(1 | scr_book2/lex)`; `corpus_group` = the four MT groups.
- Priors: normal(0, 2.5) on the intercept and coefficients, exponential(1)
  on the SDs. Prior predictive checks (`check_affix_<letter>_prior_predictive`)
  cover the whole range.
- Sampler: 4 chains, warmup 1000 / 3000 iterations (8000 draws).
- Model set per letter: A0 binary model (`corpus_group * has_suffix +
  corpus_group * has_prefix`), A1 the book's text model (nme2, prs2,
  has_hloc, has_prefix, each × corpus_group), A2 the book's fitted model (A1
  with prefix_type), A3 A2 without interactions. Yod: has_hloc without
  interaction (forms in MT other books only).
- Grouped 5-fold k-fold over `scr_book2`; no Bayes factors. Contrasts
  between categories from the posterior draws (`table_affix_contrasts.csv`).
- Final models: author's decision of 2026-11-02, with the questions of
  §8.5.1 as the deciding criterion (see model comparison).

## Model comparison

### Grouped k-fold (`table_affix_<letter>_kfold.csv`)

| Model | waw elpd diff (SE) | yod elpd diff (SE) |
|---|---|---|
| A0 binary | −129.5 (24.8) | −25.8 (9.5) |
| A1 has_prefix, interactions | **0** | −39.2 (5.3) |
| A2 prefix_type, interactions | −36.5 (4.7) | −30.9 (5.1) |
| A3 no interactions | −72.9 (11.6) | **0** |

- **Waw.** The affix types clearly improve on the binary model (A0), and the
  interactions with corpus_group on A3. A1 is best: the prefix types add
  nothing for an unseen book. The author chose A2 because §8.5.1 asks whether
  the type of prefix matters (question 4); A1 cannot answer that, and the
  k-fold result is part of the answer.
- **Yod.** With 2,175 forms the interactions cost more than they give: A3 is
  best. A3 keeps corpus_group, prs2 and has_hloc, although not credible, so
  that all four questions can be answered.

### Drop-one comparison (rule 4)

`table_affix_<letter>_kfold_drop_one.csv`: elpd of the reduced model minus
the final model (negative = the effect improves the prediction).

| Letter | Effect dropped | elpd diff | SE |
|---|---|---|---|
| waw | nme2 × corpus_group | **+39.5** | 7.9 |
| waw | prs2 × corpus_group | −70.8 | 6.0 |
| waw | has_hloc × corpus_group | −7.3 | 0.9 |
| waw | prefix_type × corpus_group | **+17.4** | 6.2 |
| yod | corpus_group | −14.3 | 5.5 |
| yod | nme2 | −84.8 | 12.8 |
| yod | prs2 | **+6.8** | 2.1 |
| yod | has_hloc | +0.1 | 0.3 |
| yod | prefix_type | −2.4 | 3.2 |

- **Waw.** The suffix and he locale interactions are needed; the ending and
  prefix-type interactions are not: without them A2 predicts better (5.0
  and 2.8 SE). Only 3 of 18 ending interactions and 4 of 12 prefix-type
  interactions are credible.
- **Yod.** The endings are needed (−84.8), and corpus_group too (−14.3),
  although no single MT group differs credibly from the Pentateuch. The
  suffixes make the prediction worse (+6.8, 3.3 SE), he locale makes no
  difference, prefix_type is unclear (−2.4, SE 3.2).

## Final models

### Waw: A2

`table_affix_waw_fixed_effects.csv`, `table_affix_waw_effects.csv`,
`fig_affix_waw_effects_<variable>`.

Intercept 1.60 [0.71, 2.57]; MT Former Prophets +1.54 [0.14, 2.95] (pd
0.98), MT LBH +2.53 [1.03, 3.97], MT other books +2.55 [1.40, 3.63];
sd(scr_book2) 0.87, sd(scr_book2:lex) 3.85.

**Effects per MT group** (logit; credible in bold):

| Category | MT Pent. | MT Former Pr. | MT LBH | MT other |
|---|---|---|---|---|
| fem. sg. -H | **−2.41** | 0.03 | **−1.77** | **−1.44** |
| fem. sg. -T | **−2.95** | **−3.01** | **−3.36** | **−2.22** |
| masc. pl. -JM | **−4.91** | **−4.34** | **−3.31** | **−4.08** |
| masc. pl. constr. -J | **−2.23** | **−2.29** | **−2.21** | **−2.16** |
| fem. pl. -WT | **−7.08** | **−6.98** | **−9.90** | **−7.51** |
| fem. pl. -T | **−3.46** | **−3.29** | −1.09 | **−2.19** |
| 1 sg. -J | **−3.58** | **−3.27** | −2.52 | **−2.81** |
| 2 sg. -K | **−3.13** | **−3.16** | −1.67 | **−2.48** |
| 3 m. sg. -W | **−5.23** | **−5.21** | **−3.79** | **−3.80** |
| 3 f. sg. -H | **−3.62** | 0.10 | −3.43 | **−1.84** |
| 1 pl. -NW | −1.53 | −1.33 | **−3.40** | **−2.14** |
| 2 m. pl. -KM | **−3.24** | −1.17 | −4.31 | −1.23 |
| 3 m. pl. -HM | **−2.63** | **−3.13** | −2.66 | −1.45 |
| 3 m. pl. -M | −0.73 | 0.15 | −0.87 | −0.23 |
| he locale | **−3.23** | −1.91 | −1.81 | 0.15 |
| article | **−1.57** | **−0.73** | −0.04 | 0.14 |
| conjunction | −0.57 | −1.07 | −0.30 | −0.38 |
| preposition | **−1.05** | −0.29 | −0.10 | −0.16 |
| other prefix | −0.91 | 0.11 | −0.70 | −0.51 |

Small cells (fewer than 20 forms): -T pl. FP and LBH (12 each), -J LBH,
-K LBH, -HM LBH, -KM LBH (15-16), -H suffix FP (11) and LBH (2), -M FP (11),
he locale in all groups (5-27).

**Contrasts** (`table_affix_contrasts.csv`; first category minus second):

| Contrast | MT Pent. | MT Former Pr. | MT LBH | MT other |
|---|---|---|---|---|
| -WT vs -JM | −2.17 (.969) | **−2.62** | **−6.56** | **−3.43** |
| -WT vs -T pl. | **−3.63** | **−3.70** | **−8.83** | **−5.32** |
| -JM vs -H | **−2.50** | **−4.38** | **−1.54** | **−2.65** |
| -W vs -J | **−1.65** | **−1.96** | −1.29 | **−0.99** |
| -W vs -K | **−2.11** | −2.04 | −2.14 | **−1.32** |
| -W vs -H | −1.60 (.968) | **−5.32** | −0.39 | **−1.96** |
| -NW vs -W | **+3.69** | **+3.88** | +0.39 | +1.66 (.974) |
| -KM vs -K | −0.11 | +1.97 | −2.67 | +1.25 |
| -HM vs -H | +1.00 | −3.24 | +0.73 | +0.39 |
| article vs conjunction | **−0.99** | +0.33 | +0.25 | +0.53 |
| article vs preposition | −0.52 | −0.44 | +0.05 | +0.30 |

### Yod: A3

`table_affix_yod_fixed_effects.csv`, `table_affix_yod_effects.csv`,
`fig_affix_yod_effects_<variable>`. No interactions: one effect for all MT
groups.

| Parameter | Estimate [95%] | pd |
|---|---|---|
| Intercept | 4.66 [3.07, 6.34] | 1 |
| MT Former Prophets | −1.04 [−3.23, 1.09] | 0.83 |
| MT LBH | 0.49 [−1.64, 2.65] | 0.68 |
| MT other books | 0.98 [−0.79, 2.80] | 0.86 |
| fem. sg. -H | **−2.59 [−4.31, −0.81]** | 1.00 |
| fem. sg. -T | **−2.50 [−3.59, −1.46]** | 1 |
| masc. pl. -JM | **−5.06 [−6.08, −4.13]** | 1 |
| masc. pl. -M | −1.26 [−3.36, 1.03] | 0.87 |
| masc. pl. constr. -J | **−2.07 [−3.11, −1.08]** | 1 |
| fem. pl. -WT | **−3.20 [−4.95, −1.50]** | 1 |
| fem. pl. -T | **−3.96 [−6.00, −2.06]** | 1 |
| 2 sg. -K | 2.01 [−0.21, 4.41] | 0.96 |
| 3 m. sg. -W | −0.51 [−1.79, 0.79] | 0.77 |
| 3 f. sg. -H | 0.83 [−1.04, 2.73] | 0.81 |
| 3 m. pl. -HM | −0.84 [−2.65, 1.13] | 0.81 |
| he locale | −2.36 [−5.23, 0.04] | 0.97 |
| article | **1.01 [0.29, 1.77]** | 1.00 |
| conjunction | 0.37 [−0.58, 1.36] | 0.77 |
| preposition | −0.38 [−1.25, 0.46] | 0.81 |
| other prefix | −0.07 [−1.06, 0.92] | 0.55 |
| sd(scr_book2) | 1.27 | |
| sd(scr_book2:lex) | 4.58 | |

Contrasts: -JM vs -WT −1.85 [−3.71, −0.08] (pd 0.979), -JM vs -M −3.76
(pd 1), -JM vs -H −2.47 (pd 0.998), -HM vs -H −1.66 (pd 0.904), article vs
preposition +1.39 (pd 0.998), article vs conjunction +0.64 (pd 0.867).

## Robustness

`table_affix_robustness.csv`. Variants: A2 without the dominant lexeme
(waw >LHJM/, yod ZQN/), and the final models with prior sd 1.5 and 4. For
yod the lexeme variant is A2 (as in the plan of 2026-10-19), so it is
compared with yod A2, not A3.

- **Waw without >LHJM/** (8,924 forms): all effects keep their credibility
  except the constr. -J in the MT Former Prophets (−2.29 → −1.26) and MT LBH
  (−2.21 → −1.30): there it rests on >LHJM/ (ʾĕlōhê, rule 3(i)). -WT, -JM,
  -W and the prefix effects in the MT Pentateuch are unchanged.
- **Yod without ZQN/** (A2, 2,000 forms): the constr. -J is no longer
  credible in the MT Pentateuch (−1.97 → −0.98) and MT other books (−2.23 →
  −1.34): the -J effect rests largely on ZQN/ (ziqnê). Fem. sg. -H becomes
  credible in the MT Former Prophets (−4.03) and MT Pentateuch (−2.32). -JM
  stays the strongest ending.
- **Prior sensitivity, waw:** with sd 1.5 three small suffix effects become
  credible (-NW MT Pent. −1.37, -J MT LBH −2.63, -HM MT other −1.50); with
  sd 4 nothing changes.
- **Prior sensitivity, yod:** with sd 4 the suffix -K (+2.54) and he locale
  (−2.98) become credible (pd 0.96 and 0.97 with sd 2.5); with sd 1.5 they
  are weaker (+1.33, −1.50). The endings and the article are credible with
  all three priors.

## Model checks

- **Convergence.** All fits: max Rhat ≤ 1.01, no divergent transitions, no
  treedepth hits. Waw A2: max Rhat 1.004, min bulk ESS 1675; prior sd 4
  Rhat 1.01, tail ESS 2505. Yod A3: max Rhat 1.003, bulk ESS 980, tail ESS
  868; prior sd 4 max Rhat 1.01 (lprior, sd(scr_book2:lex); bulk ESS > 1600),
  tail ESS 666. No refit with 2000 / 6000 needed.
- **Posterior predictive checks** (`check_affix_<letter>_ppcheck_bars`,
  `_mean`): fine. Per MT group × ending and × suffix
  (`check_affix_<letter>_ppc_endings`, `_suffixes`): all observed shares lie
  inside the 95% predictive interval; the small yod suffix cells have very
  wide intervals.
- **Bayes R2**: waw 0.81 [0.80, 0.81], yod 0.73 [0.70, 0.75].
- **LOO** (for completeness): waw elpd −2565.5 (SE 60.0), 5.5% of
  observations with Pareto k > 0.7; yod −549.4 (SE 25.4), 11.5%.
- **In-sample classification**: waw accuracy 0.95, sensitivity 0.96,
  specificity 0.95; yod 0.95, 0.97, 0.89.

## Comparison with the book (§8.5, manuscript 2026-09-10)

`table_affix_book_models_old_fits.csv`: the stored old fits of the book's
fitted model (prefix types × law_phase3, all categories, wider priors).

- **Waw.** The MT Pentateuch effects of the old fit are close to those of
  A2: -WT −9.1 (A2 −7.1), -JM −5.5 (−4.9), -H −2.7 (−2.4), suffix -W −5.9
  (−5.2), article −1.8 (−1.6), prepositions −1.2 (−1.1); he locale −5.2
  (−3.2). The corpus effects agree (Former Prophets +1.5, LBH +2.6, other
  +2.6). The answers of §8.5 for waw stand.
- **Yod.** The old fit has interactions and the rare categories; its
  Pentateuch effects are larger and much more uncertain (-JM −8.7 [−11.6,
  −6.1], intercept 6.9). The order of the endings (-JM strongest) is the
  same. The old fit gives no credible prefix effect in the Pentateuch;
  A3 (one effect for all groups) finds a credible positive article effect.
- **Counts.** 11,517 waw and 2,175 yod forms after dropping small
  categories (11,545 and 2,220 before; stored fits 11,541 and 2,223).
- **Tables.** Table 8.38, MT Other, suffix -K: 245 in the data, 129 in the
  book (the -J value repeated?). Table 8.41, MT Pentateuch: the defective
  masc. pl. -M has 25 yod forms, not rare there.
- **Model choice.** The book compared models by Bayes factor; here the
  grouped k-fold and the questions of §8.5.1.

## Points for the author

1. **Waw drop-one.** A2 without nme2 × corpus_group predicts clearly better
   (+39.5, SE 7.9), and without prefix_type × corpus_group too (+17.4, SE
   6.2). The author keeps A2 (2026-11-03); no reduced model fitted. The text
   should say that the differences between MT groups in the ending and
   prefix-type effects add little for unseen books (only 3 of 18 and 4 of
   12 interactions credible).
2. **Yod drop-one.** A3 without prs2 predicts better (+6.8, SE 2.1); he
   locale makes no difference. The author keeps A3 (2026-11-03) for
   question 3; the text can say that the suffixes do not matter for yod.
3. **Prefixes (question 4).** The answer is "little": in waw words only the
   article and prepositions in the MT Pentateuch (and the article in the
   Former Prophets) lower fullness, and the k-fold prefers a single prefix
   variable. In yod words the article *raises* fullness (+1.00), the
   opposite of waw. Worth a sentence in §8.5.
4. **Same vowel letter (question 2)** is confirmed for both letters, and the
   waw suffix -W is a further case (strongest suffix in waw words).
5. **Rests on one lexeme** (rule 3(i)): constr. -J in waw words in the MT
   Former Prophets and LBH (>LHJM/), and in yod words (ZQN/, A2 variant).
6. **Yod prior sensitivity**: the -K suffix and he locale are credible only
   with prior sd 4; report them as not credible.
7. **Open from 2026-10-19:** suffix -H is labelled 3 f. sg.; the data do not
   separate the rare 3 m. sg. -H. Table 8.38 (-K) and Table 8.41 (-M) as
   above.
