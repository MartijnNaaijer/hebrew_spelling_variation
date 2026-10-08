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
