# Chapter 11: the manuscripts of Isaiah

Replaces the "Isaiah manuscripts" sections of earlier versions of the chapter 8 and 9 scripts (not in the
repository).

## Run

From the repository root, `Rscript analysis/ch11_isaiah/isaiah_analysis.R` fits the models once into
`isaiah/` in the model folder (see `../README.md`) and reloads them afterwards.
`ISA_ONLY_DATA=1 Rscript analysis/ch11_isaiah/isaiah_analysis.R` writes only the counts and parallels (no
models). It reads the cleaned chapter 8–9 datasets (`../ch10_clustering/data`, from
`../ch10_clustering/export_cleaned_data.R`) and the files in `data/` for the consonantal forms and the
hiphil MT match.

`Rscript analysis/ch11_isaiah/isaiah_followup.R` (after `isaiah_analysis.R`) runs the checks of 2026-11-13
described in the last section; it fits its models once into the same folder.

## Method (decisions of 2026-11-03)

- Data: the Isaiah forms of the 13 features of Chapters 8–9; 1QIsaᵃ in two parts (Isaiah 1–33, 34–66).
- A manuscript enters a model with more than five forms of the feature.
- Models (brms, Bernoulli, logit; priors of Chapters 8–9: normal(0, 1.5), exponential(1)):
  - nouns: `has_vowel_letter ~ scroll + has_suffix + (1 | lex)`;
  - final-syllable and monosyllabic ו also `scroll * has_suffix + (1 | lex)`;
  - verbs: `has_vowel_letter ~ scroll + has_suffix + (1 | lex)` since 2026-11-04 (author); before
    `scroll + (1 | lex)`, because the suffix coding of the participles differed between MT and the scrolls,
    which the data of 2026-11-03 corrected. The infinitives (all forms in Isaiah with the same has_suffix
    value) get no suffix term.
- Reported: medians and 66%/95% quantile intervals of the contrast with MT Isaiah and of the probability of
  full spelling for a typical lexeme (nouns: unsuffixed). Contrasts on fewer than 20 forms or on a
  manuscript whose forms are all full or all defective are flagged (`small`, `separated`) and not counted
  as credible.
- Parallels: the same lexeme in the same verse, paired by occurrence; the hiphil by the stored MT match
  (as in chapter 9). Since 2026-11-13 an exact two-sided sign test (binomial, p = 0.5) on the parallels
  that differ (scroll fuller against MT fuller): column `p_sign` of `results/parallels.tsv`.

## Output

- `results/models.tsv`: per feature and manuscript: n, full, suffixed, contrast and probability
  (median, intervals), pd, flags.
- `results/suffix_contrasts.tsv`: final-syllable and monosyllabic ו, contrast with MT per suffix status.
- `results/parallels.tsv`, `results/parallel_lists/<feature>.tsv`: parallel counts and the differing parallels.
- `results/mt_shares.tsv`, `results/forms_per_manuscript.tsv`, `results/convergence.tsv`.
- `results/followup_*.tsv`: the checks of `isaiah_followup.R` (last section).
- `figures/fig_ch11_mt_shares` (Figure 11.1; the figures are not in the repository), `fig_ch11_<feature>` (one per feature),
  `fig_ch11_<final_w|single_w>_suffix`.

## Refit of 2026-11-04

Data release v1.2.0 (commit 37b4f01, cleaned data exported by `../ch10_clustering`). Refitted
with the file prefix `isa_d2_` (the `isa_` fits stay): the seven verb features (new formula) and final_w,
single_w (has_suffix changed for a few 1QIsaᵃ forms). ptcp_qal: 1Q8 20 forms (was 21), 19 parallels (15 full
in both). All converged (max Rhat 1.006, no divergences); no manuscript contrast changed credibility.
Suffix effects of the verbs: ptca −0.97 [−1.39, −0.55]; ptcp −0.21 [−1.63, 0.97]; hiphil −0.84 [−1.77, 0.10];
pe-yod −1.04 [−2.17, 0.03]. The book follows this refit.

**Pairing of parallels, 2026-11-05.** `pair_parallels()` now calls `parallel_forms()` of `../shared/functions.R`
with `raw_occurrences()`: a scroll form is paired with the MT form at the same position in the raw text when
the scroll and the MT have the same number of forms of the lexeme in the verse (reconstructed forms included);
otherwise as before (numbered after the cleaning). Before, a reconstructed earlier form, dropped by the
cleaning, shifted the pairing. Changes (`ISA_ONLY_DATA=1`): final_w 1Q8 89/75/6/18 (was 90/75/5/18; Isa 49:7
1Q8 קדוש against MT קדש, scroll fuller) and infa_qal 4Q57 Isa 22:13 both full (was scroll fuller). Self-test
updated; Table 11.3 of the book follows the new pairing.

## Checks of 2026-11-13 (`isaiah_followup.R`)

All fits converged (max Rhat ≤ 1.007, no divergences).

- **Part II − Part I of 1QIsaᵃ** (stored models, no refit): `results/followup_part2_minus_part1.tsv`. Credible
  for all five features with credible QSP contrasts: final_w 1.13 [0.52, 1.78] (interaction model: suffixed
  1.21 [0.25, 2.16], unsuffixed 0.16 [−0.76, 1.09]), single_w 1.88, first_w 2.08, ptca_qal 1.04,
  infc_qal_triliteral 1.90 [0.57, 3.43]. Not credible for the other features.
- **Prior sensitivity:** the 13 main and 2 interaction models refitted with `book_priors(2.5)`, the priors of
  chapters 8–9 (`isa_p25_*.rds`): `results/followup_prior_sensitivity[_suffix].tsv`. Of 64 contrasts (65 before data v1.4.0), none
  changes classification; only the flagged infa_qal 1QIsaᵃ Part II (10 forms) gets an interval that excludes
  zero.
- **Paired model on the parallels:** `has_vowel_letter ~ witness + (1 | lex) + (1 | pair)` per feature, one
  pair per scroll form (the MT form repeated for every scroll it is paired with), manuscripts with at least
  6 parallels; final_w and single_w also `witness * has_suffix` (`isa_pair_*.rds`):
  `results/followup_paired[_suffix].tsv`. With contrasts on fewer than 20 parallels flagged, exactly the same
  credible contrasts as the main models. 4Q58 final_w −2.25 [−3.56, −0.90], but all five differing parallels
  go in one direction, so the size of the estimate depends on the prior. The suffix-specific results for 1Q8
  are confirmed.

## Data release v1.4.0 (2026-11-14)

The only full form of XLB=/ (heleb 'fat'), 4Q130 at Exod. 13.5, is halab 'milk' and was removed in the
pipeline; the lexeme then has no variation and drops out. Only first_y changes; its models are refitted with the
prefix `isa_d4_` (`REFIT_D4`; follow-up fits `isa_p25_d4_first_y`, `isa_pair_d4_first_y`). first_y: MT Isaiah 28
forms (4 full; 33 before); 1QIsaᵃ Part I 20 forms, contrast 0.18 [−1.60, 2.07]; Part II (5 forms, below the minimum
of 6) leaves the model; 4Q61 and Mur3 have no first_y forms any more. Parallels: Part I 19 (17 both defective, 2 scroll fuller), Part II 5 (2 both full, 3 both
defective). The prior-sensitivity check now has 64 contrasts (65 before); none changes classification.
