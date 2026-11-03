# CLAUDE.md

Data preprocessing for a book on spelling variation (vowel letters) in the Masoretic Text (MT), the biblical
Dead Sea Scrolls (DSS) and the Samaritan Pentateuch (SP). The README describes the datasets, their columns and the
structure of the code in `preprocess_data/src`.

## Environment (Windows)

- Pipeline and tests: base Anaconda, `~/anaconda3/python.exe` (pandas 2.2.2; versions in `requirements.txt`).
- Notebooks: the conda environment `hebrew_spelling` (has Biopython, which base Anaconda lacks).
- Set `PYTHONIOENCODING=utf-8` when running Text-Fabric outside `main.py`, otherwise its console output crashes.
- The Text-Fabric corpora are in `~/text-fabric-data`; versions are set in `preprocess_data/src/config.py`.

## Running and checking

From `preprocess_data/src`:

    python main.py all --out ../regression_output    # all datasets, ~4.5 minutes; without --out it writes to data/

From the repository root:

    python preprocess_data/compare_datasets.py preprocess_data/regression_output   # compare with data/
    pytest                                                                         # data checks and unit tests
    SPELLING_DATA_DIR=preprocess_data/regression_output pytest                     # tests on the new output

The output is written in a fixed row order, so two runs give byte-identical files.

## Working rules

- A refactoring must leave all output files identical (check with `compare_datasets.py`).
- A fix that changes the data gets its own commit, with a summary of the changed rows in the commit message.
- Only update `data/` after the user has seen the differences; the R models and notebooks for the book read it.
- `tests/test_first_df_mt_dss.py` lists known problem lexemes (`KNOWN_*`); new cases make the tests fail.

## Pitfalls

- `data/pattern_data_mt_dss.json` and `data/pattern_data_sp_<version>.json` hold partly hand-corrected vowel letter
  patterns keyed by Text-Fabric node id. They only fit the corpus versions in `config.py`; the pipeline warns
  when a pattern does not have the length of its word.
- SP node ids overlap with MT ids; in the datasets they are shifted by 100000 (`SP_TF_ID_OFFSET`).
- `data/hiphil_triliteral_with_hireq.csv` is made by `notebooks/aligning_triliteral_hiphil_to_add_hireq.ipynb`
  (run it in the `hebrew_spelling` environment), not by the pipeline. Rerun it when `hiphil_triliteral.csv` changes.
- The R models in `data_analysis/analysis_nouns_adjectives` read `data/nouns_adjectives.csv` and use
  `neigh_vowel_letter` as a predictor, so changes in that file affect results in the book.
- The verb analyses of the book (`Dropbox/monograph_orthography/verbs/analysis_verbs`) read the verb datasets in
  `data/`; a change there can make stored model fits out of date. Mention changed verb datasets to the author.
- `nme` is the ending as written (MT: consonants of BHSA `g_nme`; DSS: `parse_nme_dss`), not the grammatical
  ending. The participle datasets have `nme_type` for that (README, "Nominal endings of the participles").
  Author's rule (2026-10-16): a feminine singular whose written ending is only the last root letter has no ending
  (`remove_root_letter_endings_of_active_participles`).
- Excel locks a CSV that is open; copying to `data/` then fails with "Device or resource busy".

## Consistency of the DSS and SP annotation with MT

MT gets `prs`, `nme`, `hloc` and the stem from the BHSA; the DSS words are segmented by the code in `words.py`
(`DSSWordProcessor`, `parse_nme_dss`). The two must agree, because the book compares MT with the scrolls and
`has_suffix` (= prs or nme or hloc) is a predictor in the models. Rule: **a DSS or SP word with the same consonants as
its MT parallel gets the same segmentation as in the BHSA.**

Check after every change to the segmentation: pair each DSS/SP word with its MT parallel (book, chapter, verse,
lex, occurrence, as `parallel_forms()` in the book's R code; the hiphil also by `mt_match`), keep the pairs with
identical `g_cons`, and compare the columns. On 2026-11-03 `has_vowel_letter`, `vowel_letter`, `type` and
`has_suffix` agreed in all pairs of all datasets. Differences that remain and are expected: empty `ps`/`gn`
against "unknown"; DSS rows of the verbs without `pattern`; SP without verbal stem (`vs`); `prefix`, because
`g_cons` excludes the prefix and the texts differ there (1QIsaa BXRB against MT XRB, Isa 1:20); the DSS stem of
niphal/hiphil/hophal pe-yod verbs keeps the preformative; the final H of lamed-he active participles stays in
the DSS/SP stem (MT: `other_vowel_ending` H); energic nun written with the suffix (`prs` NH against H).

Fixed on 2026-11-03 (all only in the DSS; MT and SP unchanged; no change in `has_vowel_letter` except one form):
- Feminine singular participles: the final H was split off only for adjectives (`parse_nme_dss`), so 24 DSS
  active and 49 passive participles (e.g. NVWJH, Isa 5:25) had no `nme`, while MT has nme H.
  `split_fem_sg_he_of_participle`. Lamed-he: in the active participle the H may be the root letter (ZNH, no
  nme, as in the BHSA); in the passive participle the root H has become J and the final J is consonantal
  (`make_ptc_patterns`: NVWJ, PDWJJ = stem PDWJ + construct J).
- Masculine nouns whose final H is a root letter (JWRH/, MRBH/, R>H/, XZH=/) had nme H: `MASCULINE_ROOT_H_LEXEMES`
  (with >LWH/). Not a gender rule: QVWRH/ is masculine in both corpora and has nme H in the BHSA.
- Verbal suffixes are read from Abegg's morphology (`morpho`, tags at the end: Xn paragogic nun, Xh paragogic
  he, X3fs etc. suffix) in `split_verbal_suffixes`. Before, everything after the morpheme break was prs:
  paragogic nun (TCXTW'N) and the H of the imperative (HGJD'H) were suffixes, and with nun + suffix (J#RTW'N'K)
  the suffix was N instead of K. Paragogic letters go to `uvf_n` and are removed from the stem, as the BHSA
  treats them as verbal endings. In infinitives and participles the Xh is the feminine ending (>HB'H, Deut 10:12):
  nme H, as in the BHSA (these infinitives are then excluded, as in MT).
- `correct_verbal_nme`: finite verbs have no nme (the M of the ending TM, NWTRTM, Isa 30:17, was taken for a
  plural ending); the feminine T of non-qal participles (MXRBT, Isa 51:10) and the WT of non-qal lamed-he
  infinitives (HWDWT, Ps 119:62) are nme, as in the BHSA (the qal forms get these later in the pipeline).
- Row changes from these fixes come from the existing reconstruction filter, which now sees the right syllable:
  ptcp_qal 4 removed and 2 added, hiphil_triliteral 1 removed (2Q5 MPRJST). One spelling change: 4Q82 NCBJM
  (Amos 8:5), whose JM was taken for a plural ending, is now full, like MT.
- After regenerating `hiphil_triliteral.csv`, rerun the notebook for `hiphil_triliteral_with_hireq.csv` (see above).
- Commit on a branch, not on `main`.
