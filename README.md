# Hebrew Spelling Data

Data and analysis of spelling variation in MT, biblical DSS and SP.

The datasets can be found in the folder "data".

The relevant files are:

nouns_adjectives.csv\
hiphil_triliteral.csv\
infa_qal.csv\
infc_qal_lamed_he.csv\
infc_triliteral.csv\
niph_hiph_pe_yod.csv\
ptca_qal.csv\
ptcp_qal.csv

The files are **tab-separated** and contains one row per analyzed *vowel-letter position* within a word. Most linguistic columns come from the ETCBC/BHSA Text-Fabric encoding of the Hebrew Bible; several are custom columns added for the vowel-letter (mater lectionis) study. Transliteration uses the ETCBC consonantal scheme (e.g. `>` = aleph, `<` = ayin, `C` = shin, `J` = yod, `W` = waw).

## Identification & reference

| Column | Description |
|---|---|
| `tf_id` | Text-Fabric node id of the word. |
| `scroll` | Text witness / source. `MT` = Masoretic Text; other values would be Dead Sea Scrolls (or comparable) witnesses. |
| `book` | Biblical book (e.g. Genesis). |
| `chapter` | Chapter number. |
| `verse` | Verse number. |

## Word form & lexical data

| Column | Description |
|---|---|
| `lex` | Lexeme, consonantal transliteration (the dictionary form). |
| `g_cons` | The word as it occurs in the text, consonantal transliteration. |
| `stem` | The consonantal stem of the word — the base form without nominal ending / suffix, used as the unit for the pattern analysis. |
| `heb_g_cons` | The word in Hebrew script (consonantal, unpointed). |
| `pattern` | Consonant/vowel-letter pattern of the **stem**: `C` = consonant, `M` = mater lectionis. |
| `pattern_g_cons` | Same `C`/`M` pattern but computed over the full word form (`g_cons`). |

## Morphological features

| Column | Description |
|---|---|
| `vs` | Verbal stem (qal, piel, hif, …); `NA` for non-verbs. |
| `vt` | Verbal tense/aspect (perf, impf, wayq, infc, …); `NA` for non-verbs. |
| `nu` | Grammatical number (sg, du, pl, NA, unknown). |
| `gn` | Grammatical gender (m, f, NA, unknown). |
| `ps` | Grammatical person (p1, p2, p3, NA, unknown). |
| `sp` | Part of speech (subs, adjv, verb, nmpr, …). |
| `prs` | Pronominal suffix, consonantal transliteration (`absent` / `n/a` / the suffix letters). |
| `nme` | Nominal ending, consonantal transliteration (`absent` / `n/a` / the ending letters, e.g. `JM`). |
| `hloc` | Directional / locative *he* (the ‎ה‎-locale ending), when present. |
| `prefix` | Proclitic prefix letter(s) attached to the word (article, preposition, conjunction, e.g. `B`, `W`). |

## Manuscript-sign annotations

| Column | Description |
|---|---|
| `rec_signs` | Per-letter flag string for the full word indicating reconstructed signs (one character per letter; `n` = not reconstructed, `r` = reconstructed). Relevant for fragmentary witnesses. |
| `cor_signs` | Per-letter flag string for the full word indicating corrected signs (`n` = not corrected). |
| `rec_signs_stem` | Same as `rec_signs` but restricted to the `stem` portion. |
| `cor_signs_stem` | Same as `cor_signs` but restricted to the `stem` portion. |

## Vowel-letter analysis

| Column | Description |
|---|---|
| `type` | Which vowel-letter position in the word this row describes — `first`, `last` or `single`. |
| `vowel_letter` | The vowel letter (mater lectionis) at this position (`>`, `J`, `W`, …), or empty if none. |
| `has_vowel_letter` | Binary flag (1/0): whether the word has a vowel letter. |
| `neigh_vowel_letter` | Binary flag (1/0) relating to a neighboring/adjacent vowel letter. |
| `has_prs` | Binary flag (1/0): whether the word has a pronominal suffix. |
| `has_prefix` | Binary flag (1/0): whether the word has a prefix. |
| `has_hloc` | Binary flag (1/0): whether the word has a directional/locative *he*. |
| `has_nme` | Binary flag (1/0): whether the word has a nominal ending. |

## Extra columns in hiphil_triliteral_with_hireq.csv

Built from `hiphil_triliteral.csv` by `notebooks/aligning_triliteral_hiphil_to_add_hireq.ipynb`.

| Column | Description |
|---|---|
| `has_hireq` | String. For MT rows `'1'` if the second radical is pointed with ḥireq, `'0'` if with ṣere. DSS rows have no vocalisation of their own: they inherit the value of their MT parallel, and get `'-'` if they have none. |
| `mt_match` | For DSS rows: the `tf_id` of the parallel MT form, or `'-'` if there is none; empty for MT rows. The DSS and MT texts are aligned verse by verse (character alignment). A pair needs the same lexeme, compared without the `=` and `/` homograph markers. Unmatched forms then fall back to a form in the same verse with the same lexeme and `vt`. |
| `qere` | `1` for an MT ketiv/qere form, and for a DSS form whose MT parallel is one; else `0`. In such a form the consonants are the ketiv's and the pointing the qere's, and `has_hireq` (read off the unpointed ketiv lexeme) is always `0`, so these rows should be left out of any analysis that uses the vocalisation. |

## Preprocessing pipeline
The code is in `preprocess_data/src`. The pipeline consists of the following steps:

1. Load the Text-Fabric corpora of the MT, DSS and SP (`corpora.py`).
2. Make a word table per corpus with uniform columns (`words.py`). For the MT, the vowel letters are parsed
   from the vocalized text (`parse_matres_mt.py`). The DSS and SP tables contain the words in verses that also
   occur in the MT.
3. Select the words of a feature, e.g. the qal participles (`selection.py`).
4. Process the selection with a list of steps per dataset (`pipelines.py`). The shared steps are in `steps.py`,
   the steps for specific verbal forms and the particles in `verb_steps.py`. For the nouns and adjectives, the
   vowel letter patterns of the DSS and SP are read from the json files in `data` (partly corrected by hand).
5. Save the datasets (`main.py`).

### Running the pipeline
Run `main.py` from `preprocess_data/src`. It writes the datasets to the folder `data`:

    python main.py                 # nouns and adjectives (default)
    python main.py hiphil infa     # the given datasets
    python main.py all             # all datasets

Available datasets: `nouns`, `ptc`, `infc`, `hiphil`, `niph_hiph_pe_yod`, `particles`, `infa`.

### Checking that the output has not changed
When you change the code, write the datasets to a separate folder and compare them with the datasets in `data`
(row order is ignored):

    cd preprocess_data/src
    python main.py all --out ../regression_output
    cd ..
    python compare_datasets.py regression_output

To compare with another folder than `data`, give it as second argument, e.g.
`python compare_datasets.py regression_output regression_baseline`. The script lists, per dataset, the rows that were removed or added. You can also run the tests on the new output:

    SPELLING_DATA_DIR=preprocess_data/regression_output pytest tests
