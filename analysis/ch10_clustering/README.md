# Chapter 10: cluster analysis of documents

Replaces the Python notebooks `notebooks/clustering_spelling.ipynb` and
`notebooks/clustering_spelling_for_book_summary.ipynb` (removed from the repository; they are in
the history up to release v1.2.0).

## Steps

Run from the repository root.

1. `Rscript analysis/ch10_clustering/export_cleaned_data.R` writes `data/cleaned_<dataset>.tsv` and
   `data/manifest.tsv` (not in the repository): the cleaned datasets of chapters 8 and 9 (six noun datasets,
   seven verb datasets). Nouns come from `read_nouns()` + `noun_dataset()`; each verb
   `analysis.R` is run only up to its section 2. Nothing is fitted. The counts equal
   Table 6.1 (51,487 noun forms; verbs 5,716 / 1,200 / 2,186 / 963 / 414 / 3,437 / 2,248).
2. `Rscript analysis/ch10_clustering/cluster_analysis.R` runs the three analyses (nouns with SP, verbs, combined),
   the bootstrap (`CH10_B` replicates, default 1,000; `CH10_B=20` for a quick test) and
   the grid of settings, and writes `results/` and `figures/` (the figures are not in the repository). About 15 minutes at 1,000
   replicates.

## Method (decisions of 2026-11-03)

- Feature = dataset × spelling (defective, full) × suffix (none, suffix). The suffix
  variable is the one of the chapter 8–9 models: `has_prs` for the ל״ה infinitive, no
  suffix split for the infinitive absolute and the triliteral infinitive construct,
  `has_suffix` otherwise.
- Lexeme cap per lexeme (within document and dataset), keeping its share of full
  spelling; main cut-off 4.
- Documents: at least 80 forms before capping, the same rule in all analyses; units as in
  the models (`scr_book2`, 1QIsaᵃ in two halves).
- Features: total (capped) count over the documents more than 10.
- Main profile: counts normalised within each document. Check profile: share of full
  spelling per dataset × suffix cell, shrunk toward the corpus share with 2 pseudo-forms,
  columns weighted by the square root of the cell's share of all forms.
- Ward linkage on Euclidean distances (`hclust(..., 'ward.D2')`).
- Support: share of bootstrap replicates (forms resampled within each document) that
  contain a cluster. Grid: cut-off 2, 4, 10, none × documents 50, 80, 120 × both profiles.

## Output

- `results/clades_support.tsv`: every cluster of the main trees, with its support and
  whether it also occurs with the check profile.
- `results/named_groups.tsv`: the groups discussed in §10.5 (QSP, MT Pentateuch, MT LBH,
  middle tier, SP): the smallest cluster containing them, its size and support.
- `results/settings_grid.tsv`: agreement of each setting with the main tree.
- `results/documents.tsv`: the documents of each analysis with their number of forms.
- `figures/fig_ch10_<analysis>_dendrogram|heatmap.png|pdf`.

## Rerun of 2026-11-04 (data release v1.2.0)

`data/` was re-exported from v1.2.0 on 2026-11-03 (ptcp 1,198 forms,
DSS suffix coding as in MT). `cluster_analysis.R` rerun unchanged (B = 1,000);
the earlier outputs are replaced. Same documents in all three analyses (1Q8 and 4Q84
change by one form); the trees are identical for the nouns and change only in small, unsupported
clusters for the verbs; the noun and combined clades are the same sets. Support changes
quoted in the book: nouns 11Q5 + 1QIsaa II 65 -> 66, group of three 28 -> 30 (rates 85 -> 86); verbs
QSP core 96 -> 97; combined group of six 50 -> 47, QSP core 93 -> 97, 1QIsaa I + II 71 -> 68 (drops out
of Table 10.1), Genesis-Exodus-Numbers 91 -> 90. Heatmap shares (means of document percentages
after the cut-off, as in the book): only the QSP qal active participle moves (84/89 -> 85/88).
Without a lexeme cut-off none of the well-supported combined clusters is recovered (before: one
setting). The book follows this rerun (§§10.1, 10.4.2-10.4.5, Table 10.1, §10.5, Figs. 10.1-10.6).
