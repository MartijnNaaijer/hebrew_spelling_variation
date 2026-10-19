"""
Checks whether the lexemes of the DSS and SP words in the datasets of the book cohere with the lexemes of their
parallels in the MT (BHSA).

Every verse of every DSS scroll and of the SP is aligned letter by letter with the MT verse, and every word is
paired with the MT word with which it shares the most aligned letters (see src/parallels.py). The check goes in two
directions:
- parallel_to_mt: a DSS or SP word in the dataset, compared with its MT parallel.
- mt_to_parallel: an MT word in the dataset, compared with a DSS or SP parallel that is not in the dataset. A wrong
  lexeme (or part of speech) can keep such a word out of the dataset. Parallels with the same lexeme are not listed.
SP parallels are only checked for the datasets that contain the SP.

Only words with the same text (g_cons) as their MT parallel are compared; sin and shin are not distinguished,
because the DSS does not. The categories are explained in parallels.compare_lexemes. In addition:
- no_parallel: no letter of the word is aligned with a word of the MT.
The output files leave out the categories match, different_text and no_parallel; the summary counts all.

Usage (from preprocess_data):
    python check_lexemes.py [--data DATA_DIR] [--out OUT_DIR]

DATA_DIR defaults to the data folder, OUT_DIR to preprocess_data/lexeme_check_output. Per dataset, the cases that
do not match are written to lexeme_check_<dataset>.csv, the counts of all categories to lexeme_check_summary.csv.
"""
import argparse
import collections
import os
import sys

import pandas as pd

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'src'))

from corpora import load_corpora  # noqa: E402
from parallels import match_words, compare_lexemes  # noqa: E402
from pipelines import SP_TF_ID_OFFSET  # noqa: E402
from special_data import dss_feature  # noqa: E402
from words import keep_consonants, DSSWordProcessor  # noqa: E402

DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'data')
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'lexeme_check_output')

# The datasets used in the book. hiphil_triliteral_with_hireq.csv has the same words as hiphil_triliteral.csv.
DATASETS = ['nouns_adjectives.csv',
            'hiphil_triliteral.csv',
            'infa_qal.csv',
            'infc_qal_lamed_he.csv',
            'infc_qal_triliteral.csv',
            'niph_hiph_pe_yod.csv',
            'ptca_qal.csv',
            'ptcp_qal.csv']

NOT_LISTED = ['match', 'different_text', 'no_parallel']

OUTPUT_COLUMNS = ['direction', 'category', 'corpus', 'scroll', 'book', 'chapter', 'verse',
                  'tf_id', 'g_cons', 'lex', 'sp', 'in_dataset',
                  'mt_tf_id', 'mt_g_cons', 'mt_lex', 'mt_sp', 'mt_in_dataset',
                  'aligned_letters', 'share', 'sp_source']


class Witness:
    """The words of one corpus: per verse a list of (word_id, g_cons, ends_with_space) for the alignment,
    and per word its scroll, section, g_cons, lexeme and part of speech."""
    def __init__(self):
        self.verses = collections.defaultdict(list)
        self.words = {}

    def add(self, verse_key, w, scroll, section, g_cons, ends_with_space, lex, sp, **extra):
        if not g_cons:
            return
        self.verses[verse_key].append((w, g_cons, ends_with_space))
        self.words[w] = dict(scroll=scroll, section=section, g_cons=g_cons, lex=lex or '', sp=sp or '', **extra)


def mt_witness(mt):
    F, L, T = mt.F, mt.L, mt.T
    witness = Witness()
    for v in F.otype.s('verse'):
        bo, ch, ve = T.sectionFromNode(v)
        section = (bo, int(ch), int(ve))
        for w in L.d(v, 'word'):
            witness.add(section, w, 'MT', section, keep_consonants(F.g_cons.v(w) or ''), bool(F.trailer.v(w)),
                        F.lex.v(w), F.sp.v(w))
    return witness


def dss_witness(dss, mt_sections):
    """The words of the DSS in verses that occur in the MT, also those without lexeme. As in words.py, scrolls
    with more than one node are merged and words in fragments without chapter number are left out."""
    F, L, T = dss.F, dss.L, dss.T
    witness = Witness()
    for scr in F.otype.s('scroll'):
        scroll_name = T.scrollName(scr)
        for w in L.d(scr, 'word'):
            bo, ch, ve = F.book_etcbc.v(w), F.chapter.v(w), F.verse.v(w)
            if not all([bo, ch, ve]) or 'f' in ch or not ve.isdigit():
                continue
            section = (bo, int(ch), int(ve))
            if section not in mt_sections:
                continue
            glyphs = DSSWordProcessor.replace_final_characters(F.glyphe.v(w) or '')
            witness.add((scroll_name, section), w, scroll_name, section, keep_consonants(glyphs), bool(F.after.v(w)),
                        dss_feature(F, 'lex_etcbc', w), F.sp_etcbc.v(w))
    return witness


def sp_witness(sp, mt_sections):
    F, L, T = sp.F, sp.L, sp.T
    witness = Witness()
    for v in F.otype.s('verse'):
        bo, ch, ve = T.sectionFromNode(v)
        section = (bo, int(ch), int(ve))
        if section not in mt_sections:
            continue
        for w in L.d(v, 'word'):
            witness.add(('SP', section), w, 'SP', section, keep_consonants(F.g_cons.v(w) or ''), bool(F.trailer.v(w)),
                        F.lex.v(w), F.sp.v(w), sp_source='mt' if F.mt_feat.v(w) else 'prediction')
    return witness


def find_parallels(witness, mt):
    """Returns {word: (mt_word, number of aligned letters)} for the words of a DSS or SP witness, of which the
    verses are keyed by (scroll, section)."""
    parallels = {}
    for (_, section), words in witness.verses.items():
        parallels.update(match_words(words, mt.verses[section]))
    return parallels


def read_dataset_words(path):
    """Returns the ids of the words of the MT, DSS and SP in a dataset (SP ids without the offset)."""
    df = pd.read_csv(path, sep='\t', usecols=['tf_id', 'scroll'], dtype={'tf_id': int, 'scroll': str})
    df = df.drop_duplicates()
    return {'MT': set(df.tf_id[df.scroll == 'MT']),
            'SP': set(df.tf_id[df.scroll == 'SP'] - SP_TF_ID_OFFSET),
            'DSS': set(df.tf_id[~df.scroll.isin(['MT', 'SP'])])}


def check_dataset(ids, mt, witnesses, parallels):
    """Returns a list of dicts, one per checked word, with the columns in OUTPUT_COLUMNS."""
    corpora = ['DSS', 'SP'] if ids['SP'] else ['DSS']
    rows = []

    def make_row(direction, corpus, w, mt_w, aligned):
        info = witnesses[corpus].words[w]
        row = dict(direction=direction, corpus=corpus, scroll=info['scroll'],
                   book=info['section'][0], chapter=info['section'][1], verse=info['section'][2],
                   tf_id=w + SP_TF_ID_OFFSET if corpus == 'SP' else w,
                   g_cons=info['g_cons'], lex=info['lex'], sp=info['sp'], in_dataset=w in ids[corpus],
                   aligned_letters=aligned, share=0, sp_source=info.get('sp_source', ''))
        if mt_w is None:
            row['category'] = 'no_parallel'
            return row
        mt_info = mt.words[mt_w]
        # The share of the longer of the two words, so that at least half of both words is aligned.
        n_letters = max(len(info['g_cons']), len(mt_info['g_cons']))
        row.update(mt_tf_id=mt_w, mt_g_cons=mt_info['g_cons'], mt_lex=mt_info['lex'], mt_sp=mt_info['sp'],
                   mt_in_dataset=mt_w in ids['MT'], share=round(aligned / n_letters, 2))
        row['category'] = compare_lexemes(info['lex'], info['g_cons'], mt_info['lex'], mt_info['g_cons'])
        return row

    for corpus in corpora:
        for w in sorted(ids[corpus]):
            if w not in witnesses[corpus].words:
                print(f'{corpus} word {w} of the dataset not found in the corpus', file=sys.stderr)
                continue
            mt_w, aligned = parallels[corpus].get(w, (None, 0))
            rows.append(make_row('parallel_to_mt', corpus, w, mt_w, aligned))

        mt_to_words = collections.defaultdict(list)
        for w, (mt_w, aligned) in parallels[corpus].items():
            mt_to_words[mt_w].append((w, aligned))
        for mt_w in sorted(ids['MT']):
            for w, aligned in mt_to_words.get(mt_w, []):
                if w in ids[corpus]:
                    continue
                rows.append(make_row('mt_to_parallel', corpus, w, mt_w, aligned))
    return rows


def parse_args():
    parser = argparse.ArgumentParser(description='Compare the lexemes of DSS and SP words with their MT parallels.')
    parser.add_argument('--data', default=DATA_DIR, help='folder with the datasets (default: the data folder)')
    parser.add_argument('--out', default=OUT_DIR, help='folder for the output files')
    return parser.parse_args()


def main():
    args = parse_args()
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')
    os.makedirs(args.out, exist_ok=True)

    corpora = load_corpora()
    mt = mt_witness(corpora.mt)
    sections = set(mt.verses)
    witnesses = {'DSS': dss_witness(corpora.dss, sections), 'SP': sp_witness(corpora.sp, sections)}
    parallels = {corpus: find_parallels(witness, mt) for corpus, witness in witnesses.items()}
    book_order = {}
    for section in mt.verses:
        book_order.setdefault(section[0], len(book_order))

    summaries = []
    for file_name in DATASETS:
        ids = read_dataset_words(os.path.join(args.data, file_name))
        df = pd.DataFrame(check_dataset(ids, mt, witnesses, parallels), columns=OUTPUT_COLUMNS)
        summary = df.groupby(['direction', 'corpus', 'category']).size().rename('words').reset_index()
        summaries.append(summary.assign(dataset=file_name))

        df = df[~df.category.isin(NOT_LISTED)]
        df = df.assign(_book=df.book.map(book_order)) \
            .sort_values(['direction', 'category', 'corpus', '_book', 'chapter', 'verse', 'scroll', 'tf_id'],
                         kind='stable') \
            .drop(columns='_book')
        df.to_csv(os.path.join(args.out, f'lexeme_check_{file_name}'), sep='\t', index=False)

    summary = pd.concat(summaries)[['dataset', 'direction', 'corpus', 'category', 'words']]
    summary.to_csv(os.path.join(args.out, 'lexeme_check_summary.csv'), sep='\t', index=False)
    print(summary.to_string(index=False))


if __name__ == '__main__':
    main()
