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
  (as in chapter 9).

## Output

- `results/models.tsv`: per feature and manuscript: n, full, suffixed, contrast and probability
  (median, intervals), pd, flags.
- `results/suffix_contrasts.tsv`: final-syllable and monosyllabic ו, contrast with MT per suffix status.
- `results/parallels.tsv`, `results/parallel_lists/<feature>.tsv`: parallel counts and the differing parallels.
- `results/mt_shares.tsv`, `results/forms_per_manuscript.tsv`, `results/convergence.tsv`.
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
