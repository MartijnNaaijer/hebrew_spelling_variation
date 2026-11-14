# Chapter 10: documents by vowel-letter profile

Replaces the Python notebooks `notebooks/clustering_spelling.ipynb` and
`notebooks/clustering_spelling_for_book_summary.ipynb` (removed from the repository; they are in
the history up to release v1.2.0).

## Steps

Run from the repository root.

1. `Rscript analysis/ch10_clustering/export_cleaned_data.R` writes `data/cleaned_<dataset>.tsv` and
   `data/manifest.tsv` (not in the repository): the cleaned datasets of chapters 8 and 9 (six noun datasets,
   seven verb datasets). Nouns come from `read_nouns()` + `noun_dataset()`; each verb
   `analysis.R` is run only up to its section 2. Nothing is fitted. The counts equal
   Table 6.1 (51,310 noun forms since data release v1.4.0, 51,487 before; verbs 5,716 / 1,200 / 2,186 / 963 / 414 / 3,437 / 2,248).
2. `Rscript analysis/ch10_clustering/cluster_analysis.R` runs the three analyses (nouns and adjectives with
   SP, verbs, combined), the bootstrap (`CH10_B` replicates, default 1,000; `CH10_B=20` for a quick test), the
   grid of settings and the direct group tests (`CH10_BT` permutations, default 10,000), and writes
   `results/` and `figures/` (the figures are not in the repository).

## Method (revision of 2026-11-13)

- Feature = dataset × suffix status (12 noun, 12 verb, 24 combined features). The suffix variable is the one
  of the chapter 8–9 models: `has_prs` for the ל״ה infinitive, no suffix split for the infinitive absolute and
  the triliteral infinitive construct, `has_suffix` otherwise.
- Main profile: percentage of full spelling per feature, shrunk toward the corpus share with 2 pseudo-forms;
  columns weighted by the square root of the feature's share of all forms (the same weights for every
  document). Two check profiles: counts (dataset × spelling × suffix, normalised within each document; the
  main profile of the earlier version) and lexeme-adjusted (each form compared with the spelling of its
  lexeme in the other documents, so that differences in vocabulary drop out).
- Lexeme cap per lexeme (within document and dataset), keeping its share of full spelling; main cut-off 4.
- Documents: at least 80 forms before capping, the same rule in all analyses; units as in the models
  (`scr_book2`, 1QIsaᵃ in two halves).
- Ward linkage on Euclidean distances (`hclust(..., 'ward.D2')`); a map of the first two principal
  components of the main profile next to each dendrogram.
- Bootstrap support: lexemes (all forms of a lexeme in a document and dataset) resampled within each
  document. Grid of 36 settings: cut-off 2, 4, 10, none × documents 50, 80, 120 × the three profiles.
- Rule fixed in advance: a cluster counts as an orthographic affinity only if its support with the main
  profile is at least 70 percent, it recurs in at least 24 of the 36 settings, and it contains at most half of
  the documents (a larger cluster is the rest of a split).
- Direct tests of groups named in advance: the mean distance within a group against 10,000 random sets of the
  same size from a reference pool (`group_tests.tsv`); two-group contrasts with a permutation F test
  (PERMANOVA): Trebolle's two series, with and without the Pentateuch, and SP against MT Pentateuch
  (`group_contrasts.tsv`).

## Output

- `results/clades_support.tsv`: every cluster of the main trees, with its support, its recurrence over the
  settings and whether it meets the rule (`affinity`).
- `results/table_10_1_supported_clusters.tsv`: the clusters of Table 10.1.
- `results/settings_grid.tsv`: agreement of each setting with the main tree.
- `results/group_tests.tsv`, `results/group_contrasts.tsv`: the direct tests.
- `results/pca_loadings.tsv`: loadings of the principal components.
- `results/profile_rates_<analysis>.tsv`, `results/percent_full_<analysis>.tsv`: the main profile and the
  percentages of full spelling shown in the heatmaps; `results/group_percent_full.tsv`: group means.
- `results/documents.tsv`: the documents of each analysis with their number of forms.
- `figures/fig_ch10_<analysis>_dendrogram|heatmap|map.png|pdf`.

## History

- 2026-11-03: first version (counts profile as the main profile, bootstrap of single forms).
- 2026-11-04: rerun on data release v1.2.0 (same documents; trees identical for the nouns and changed only in
  small, unsupported clusters for the verbs).
- 2026-11-13: the methodological revision described above (main profile, lexeme bootstrap, rule fixed in
  advance, direct tests, map). The earlier version is in the repository history. Results: only QSP clusters
  meet the rule (verbs 11Q5 + 1QIsaᵃ I + II, 97 percent, 36 of 36 settings; 11Q5 + 1QIsaᵃ II in the verb and
  combined analyses); MT Pentateuch and SP are cohesive in every profile; SP differs from MT Pentateuch
  (F = 8.9, p = 0.009); MT LBH is not cohesive (p ≥ 0.32); Trebolle's series do not differ.

- 2026-11-14, data release v1.4.0 (XLB=/ removed from the nouns, see `../ch08_nouns_adjectives`): 51,310 noun
  forms (51,487 before). The noun cluster 11Q5 + 1QIsaᵃ II + 4Q27 now meets the rule, narrowly (support 71
  percent, 27 of 36 settings; before 69 percent, 26). MT Kings + Samuel (combined) 61 percent (56). SP vs MT
  Pentateuch F = 8.8 (8.9), p = 0.009. No group test crosses 0.05; the verb results are unchanged.
