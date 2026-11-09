# Chapter 12: block spelling and rapid alternation

Replaces the Python notebook `notebooks/block_spelling_and_rapid_alternation.ipynb`.

## Run

From the repository root, `Rscript analysis/ch12_sequences/sequence_analysis.R` (10,000 permutations;
`CH12_B=200` for a quick test). It reads the cleaned chapter 8–9 datasets exported by
`../ch10_clustering/export_cleaned_data.R` (run that first) and writes `results/` and `figures/` (the
figures are not in the repository).

## Method (decisions of 2026-11-03)

- Sequences: the forms of a feature in an MT book, in textual order (`tf_id`); 1–2 Samuel, Kings
  and Chronicles combined. 1QIsaᵃ (the two halves separately) as a check.
- Features: qal active participle, qal infinitive construct (triliteral), final-syllable ו in
  nouns and adjectives (the chapter 8 datasets).
- Inclusion: at least 100 distinct orderings, and at least two defective and two full forms.
- Statistic: the number of changes between defective and full spelling. Rapid alternation: the
  number of overlapping four-form alternations (D F D F, F D F D).
- Null models: free shuffling (exact runs test for the changes; permutations for the four-form
  measure) and, as the main model, shuffling within each lexeme × suffix status. p-values count
  ties on the null side: (k + 1) / (B + 1).
- All books together: the total number of changes against the totals of the same permutations.
  Single books: two-sided p, Benjamini–Hochberg across the books of a feature.
- Fullness: linear regression of the stratified z on the share of full forms.
- Robustness: within lexeme only; without the most frequent lexeme (ישב, אמר, אלהים); at least
  1,000 orderings and three forms of each.

## Output

- `results/units.tsv`: one row per book (and 1QIsaᵃ half) and feature.
- `results/overall.tsv`: all MT books together, per feature.
- `results/robustness.tsv`, `results/fullness_regression.tsv`, `results/hypothetical.tsv`.
- `figures/fig_ch12_*`: runs example (Fig. 12.1), hypothetical sequences (12.2), and per feature
  the books, the four-form alternation and the fullness regression.

## Rerun of 2026-11-04 (data release v1.2.0)

Rerun unchanged on the cleaned data re-exported from v1.2.0 (earlier outputs replaced). Infinitive construct and final-syllable waw: results byte-identical.
Qal active participle: the 1QIsaa strata changed (has_suffix of DSS forms), and because 1QIsaa I is
permuted first, the random-number stream of the MT books shifts; the MT results differ only by
Monte Carlo noise (overall z within lexeme and suffix -4.65 -> -4.63; robustness "at least 1,000
orderings, 3 of each" -4.67 -> -4.56, the only rounded value in the book that changes; Table 12.3,
Job, Zephaniah, fullness p = 0.25 unchanged when rounded). 1QIsaa: still no block spelling or
alternation. The book follows this rerun.
