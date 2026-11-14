# Chapter 12: block spelling and rapid alternation

Replaces an earlier Python notebook (`block_spelling_and_rapid_alternation.ipynb`, removed from the repository).

## Run

From the repository root, in this order:

1. `Rscript analysis/ch12_sequences/model_weights.R`: the linear predictors of the chapter 9 final models
   for the model-based null (`results/model_weights.tsv`, in the repository). Needs the stored chapter 9
   fits; without this file the model-based null is skipped.
2. `Rscript analysis/ch12_sequences/sequence_analysis.R` (10,000 permutations; `CH12_B=200` for a quick
   test). It reads the cleaned chapter 8–9 datasets exported by `../ch10_clustering/export_cleaned_data.R`
   (run that first) and writes `results/` and `figures/` (the figures are not in the repository).
3. `Rscript analysis/ch12_sequences/chronicles_precision.R`: Chronicles with 1,000,000 permutations
   (see the last section).

## Method (decisions of 2026-11-03)

- Sequences: the forms of a feature in an MT book, in textual order (`tf_id`); 1–2 Samuel, Kings
  and Chronicles combined. 1QIsaᵃ (the two halves separately) as a check.
- Features: qal active participle and qal infinitive construct (triliteral). Final-syllable ו in nouns
  and adjectives was dropped on 2026-11-13 (author: too vague a feature).
- Inclusion: at least 100 distinct orderings, and at least two defective and two full forms.
- Statistic: the number of changes between defective and full spelling. Rapid alternation: the
  number of overlapping four-form alternations (D F D F, F D F D).
- Null models: free shuffling (exact runs test for the changes; permutations for the four-form
  measure); shuffling within each lexeme × suffix status; and a model-based null (since 2026-11-13):
  within each book, the observed number of full forms is placed with probabilities proportional to the
  odds of the chapter 9 final model (participle M7, infinitive M2; posterior mean of the linear
  predictor), by exact conditional-Bernoulli sampling, so that book-level terms cancel. MT books only.
  p-values count ties on the null side: (k + 1) / (B + 1).
- All books together: the total number of changes against the totals of the same permutations.
  Single books: two-sided p, Benjamini–Hochberg across the books of a feature. A book enters the
  stratified correction only if its order can vary within lexeme × suffix (`strat_informative`: the
  number of changes is not constant over the permutations). Four-form alternations: Benjamini–Hochberg
  on the two-sided p, as for the changes.
- Fullness: linear regression of the stratified z on the share of full forms (informative books).
- Robustness: within lexeme only; without the most frequent lexeme (ישב, אמר); at least 1,000
  orderings and three forms of each; within lexeme, suffix and prefix; without Chronicles and Ezekiel;
  within chapter, lexeme and suffix. Sign count of the informative books in `overall.tsv`.

## Output

- `results/units.tsv`: one row per book (and 1QIsaᵃ half) and feature, with the forms that can move
  in the stratified null (`exchangeable`) and the isolated full forms (`isolated_full`).
- `results/model_weights.tsv`: the linear predictors of the model-based null.
- `results/chronicles_precision.tsv`: Chronicles with 1,000,000 permutations.
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

## Revision of 2026-11-13

Nouns removed; the informative-book rule, the two-sided correction of the four-form alternations, the
model-based null and the new robustness checks described above added. The participle and infinitive
results of 2026-11-04 are reproduced exactly (the seed is set per feature; the model-based null has its own
random stream). Of the participle's shortfall within lexeme and suffix (1,246 − 1,172 = 74 changes), 23
remain within chapters.

## Precision check for Chronicles (2026-11-14)

In the main run (10,000 permutations) the stratified p of Chronicles (participle) is 9/10,001 = 0.0009,
which gives a corrected p of 0.052 over the 29 informative books: within Monte Carlo error of 0.05.
`chronicles_precision.R` reruns Chronicles with 1,000,000 permutations: within lexeme and suffix
p = 0.00036 (Monte Carlo 95% interval 0.00032–0.00039), corrected p = 0.021; model-based p = 0.00019,
corrected p = 0.013 (33 books). Chronicles is therefore significant after correction under both nulls that
take the lexeme into account; the value of the main run was high by chance. No other book is near the
threshold (next smallest corrected p 0.51 and 0.64).
