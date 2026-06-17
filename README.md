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

## Preprocessing pipeline
The preprocessing pipeline consists of the following steps:

1. Uniformize data from different Hebrew sub-corpora (MT, DSS and SP) using classes in data_classes.py.
2. Parse the vowel letters in the MT (parse_matres_mt.py).
3. Parse vowel letters in DSS.
