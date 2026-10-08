"""
Here the harmonization of the MT, DSS and SP data takes place. These are three different datasets with different
conventions. For each corpus, a word table is made with one row per word and the columns in WORD_COLUMNS.

The MT is the Codex Leningradensis, based on the text-fabric dataset BHSA (see github.com/etcbc/bhsa).
The DSS dataset is based on the text-fabric dataset DSS (see github.com/etcbc/dss).
The SP dataset is based on the text-fabric dataset SP (see github.com/dt-ucph/sp).

The DSS and SP tables only contain words in verses that also occur in the MT.
"""
import pandas as pd

from parse_matres_mt import get_matres_patterns_and_prefixes
from special_data import j_lexemes, fem_end_words, fem_ending_numbers, relevant_wt_words

WORD_COLUMNS = ['tf_id', 'scroll',
                'book', 'chapter',
                'verse', 'lex',
                'g_cons', 'stem',
                'pattern', 'pattern_g_cons',
                'vs', 'vt',
                'nu', 'gn',
                'ps', 'sp',
                'prs', 'nme',
                'hloc', 'prefix',
                'rec_signs', 'cor_signs',
                'heb_g_cons']

CONSONANTS = {'<', '>', 'B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M',
              'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'X', 'Y', 'Z', '#'}
PRS_CHARS = {'>', 'D', 'H', 'J', 'K', 'M', 'N', 'W'}

LATIN_TO_HEBREW = {'>': 'א', 'B': 'ב', 'G': 'ג', 'D': 'ד', 'H': 'ה', 'W': 'ו', 'Z': 'ז', 'X': 'ח', 'V': 'ט',
                   'J': 'י', 'K': 'כ', 'L': 'ל', 'M': 'מ', 'N': 'נ', 'S': 'ס', '<': 'ע', 'P': 'פ', 'Y': 'צ',
                   'Q': 'ק', 'R': 'ר', 'F': 'ש', 'C': 'ש', 'T': 'ת'}
LATIN_TO_HEBREW_FINAL = {**LATIN_TO_HEBREW, 'K': 'ך', 'M': 'ם', 'N': 'ן', 'P': 'ף', 'Y': 'ץ'}


def to_hebrew(g_cons):
    """Converts consonantal ETCBC transliteration to Hebrew script, with final forms at the end of the word.
    Unknown characters inside the word become '_'; an unknown final character gives an empty string."""
    if not g_cons:
        return ''
    final_char = LATIN_TO_HEBREW_FINAL.get(g_cons[-1])
    if final_char is None:
        return ''
    return ''.join([LATIN_TO_HEBREW.get(c, '_') for c in g_cons[:-1]]) + final_char


def keep_consonants(text):
    return ''.join([ch for ch in text if ch in CONSONANTS])


def get_prs(g_prs):
    # Cases like >DNJ in Genesis 19:2 (masc plural with 1ps sg prs)
    if g_prs == '+':
        g_prs = ''
    return ''.join([ch for ch in g_prs if ch in PRS_CHARS])


class MTWordProcessor:
    def __init__(self, F, tf_id):
        self.F = F
        self.tf_id = tf_id
        self.lexeme = F.lex.v(tf_id)
        self.glyphs = F.g_cons.v(tf_id)
        self.number = self.get_number()
        self.nme = self.get_nme()
        self.stem = self.get_stem()

    def row(self, book, chapter, verse, matres_pattern, prefix):
        F, tf_id = self.F, self.tf_id
        return {'tf_id': tf_id, 'scroll': 'MT', 'book': book, 'chapter': chapter, 'verse': verse,
                'lex': self.lexeme, 'g_cons': self.glyphs, 'stem': self.stem,
                'pattern': get_stem_matres_pattern(self.glyphs, self.stem, matres_pattern),
                'pattern_g_cons': matres_pattern,
                'vs': F.vs.v(tf_id), 'vt': F.vt.v(tf_id),
                'nu': self.number, 'gn': self.get_gender(), 'ps': F.ps.v(tf_id), 'sp': F.sp.v(tf_id),
                'prs': get_prs(F.g_prs.v(tf_id)), 'nme': self.nme, 'hloc': 'H' if F.uvf.v(tf_id) == 'H' else '',
                'prefix': prefix, 'rec_signs': 'n' * len(self.glyphs), 'cor_signs': 'n' * len(self.glyphs),
                'heb_g_cons': to_hebrew(self.glyphs)}

    def get_number(self):
        number = self.F.nu.v(self.tf_id)
        if number in {'unknown', 'NA'}:
            return None
        return number

    def get_gender(self):
        gender = self.F.gn.v(self.tf_id)
        if gender == 'NA':
            return None
        return gender

    def get_stem(self):
        stem = keep_consonants(self.F.g_lex.v(self.tf_id))
        if self.lexeme in relevant_wt_words and self.number == 'sg' \
                and not stem.endswith('T') and self.nme.startswith('T'):
            stem += 'T'
            self.nme = self.nme.lstrip('T')
        elif self.lexeme in fem_ending_numbers:
            stem = stem[:-1]
            self.nme = 'T' + self.nme
        return stem

    def get_nme(self):
        g_nme = self.F.g_nme.v(self.tf_id)
        # According to BHSA H is not nominal ending, but we strip it ad hoc.
        if self.lexeme == 'NGH/' and self.glyphs == 'NGH':
            g_nme = 'H'
        return keep_consonants(g_nme)


def get_stem_matres_pattern(g_cons, stem, matres_pattern):
    if g_cons and stem and matres_pattern:
        stem_start_idx = g_cons.find(stem)
        return matres_pattern[stem_start_idx:stem_start_idx + len(stem)]
    return ''


def parse_nme_dss(stem, lex, state, nu, gn, sp, prs):
    """
    :param stem: initial stem (needs further parsing)
    :param lex: lexeme
    :param state: state a or c
    :param nu: number
    :param gn: gender
    :param sp: part of speech
    :param prs: pronominal suffix
    :return: stem and nme
    """
    nme = ''
    lex_no_special_signs = lex.strip('/').strip('=')

    if lex in j_lexemes:
        if prs and stem.endswith('JJ') and nu == 'pl':
            stem = stem.removesuffix('J')
            nme += 'J'
    else:
        if prs and stem.endswith('J') and nu == 'pl':
            stem = stem.removesuffix('J')
            nme += 'J'

    if sp == 'adjv' and len(lex) > 1 and stem.endswith('H') and lex_no_special_signs[-1] != 'H':
        stem = stem.removesuffix('H')
        nme += 'H'
    elif sp == 'adjv' and len(lex) > 1 and stem.endswith('T') and lex_no_special_signs[-1] != 'T' and nu == 'sg':
        stem = stem.removesuffix('T')
        nme += 'T'
    elif sp == 'adjv' and len(lex) > 1 and stem.endswith('TJ') and lex_no_special_signs[-2:] != 'TJ' and nu == 'sg':
        stem = stem.removesuffix('TJ')
        nme += 'TJ'
    elif sp == 'adjv' and lex_no_special_signs[-1] == 'J' and len(lex) > 1 and stem.endswith('JM'):
        stem = stem.removesuffix('JM')
        nme += 'JM'
    elif sp == 'adjv' and lex_no_special_signs[-1] == 'J' and len(lex) > 1 and stem.endswith('JN'):
        stem = stem.removesuffix('JN')
        nme += 'JN'
    elif sp == 'adjv' and lex_no_special_signs[-1] == 'J' and len(lex) > 1 and stem.endswith('WT'):
        stem = stem.removesuffix('WT')
        nme += 'WT'
    elif sp == 'adjv' and lex_no_special_signs[-1] == 'J' and len(lex) > 1 and stem.endswith('T'):
        stem = stem.removesuffix('T')
        nme += 'T'

    if (stem.endswith('J') and state == 'c' and nu in {'du', 'pl'} and lex not in j_lexemes) or \
            (stem.endswith('J') and sp == 'prep'):
        stem = stem.removesuffix('J')
        nme += 'J'
    elif stem.endswith('W') and sp == 'prep':
        stem = stem.removesuffix('W')
        nme += 'W'
    elif lex in j_lexemes and stem.endswith('JJM') and len(stem) > 3:
        stem = stem.removesuffix('JM')
        nme = 'JM' + nme
    elif lex in j_lexemes and stem.endswith('JM') and len(stem) > 2:
        stem = stem.removesuffix('M')
        nme = 'M' + nme
    elif lex not in j_lexemes and stem.endswith('JM') and nu in {'du', 'pl'} and len(stem) > 2:
        stem = stem.removesuffix('JM')
        nme = 'JM' + nme
    elif lex not in j_lexemes and stem.endswith('M') and nu in {'du', 'pl'} and len(stem) > 2 and \
            (lex_no_special_signs[-1] != 'M' or lex == '>LHJM/'):
        stem = stem.removesuffix('M')
        nme = 'M' + nme

    if stem.endswith('WT') and nu == 'pl' and lex != '>LMNWT/':
        stem = stem.removesuffix('WT')
        nme = 'WT' + nme
    if stem.endswith('WTJ') and nu == 'pl' and lex != '>LMNWT/':
        stem = stem.removesuffix('WTJ')
        nme = 'WTJ' + nme
    elif stem.endswith('T') and nu == 'pl' and gn == 'f' and lex != '>LMNWT/':
        stem = stem.removesuffix('T')
        nme = 'T' + nme

    if lex_no_special_signs[-1] == 'H' and nu == 'sg':
        if stem.endswith('TJ'):
            stem = stem.removesuffix('TJ')
            nme = 'TJ' + nme
        elif stem[-1] == 'T':
            stem = stem.removesuffix('T')
            nme = 'T' + nme
        elif stem[-1] == 'H' and lex != '>LWH/':
            stem = stem.removesuffix('H')
            nme = 'H' + nme

    # Ugly ad hoc solution for Jer 17:18 in 4Q70. Better solution?
    if lex == 'CBRWN/' and stem == 'CBRWNM':
        stem = 'CBRWN'
        nme = 'M'

    # Aramaic plural
    if stem.endswith('JN') and gn == 'm' and nu == 'pl' and not nme:
        stem = stem[:-2]
        nme = 'JN'

    # Ugly hardcoded solution for H/> exchange
    if lex in {'DBWRH/', 'GBWRH/', 'PLJVH/', 'MNWSH/', 'MBWSH/', 'PH/', 'DWD=/'} and stem.endswith('>'):
        stem = stem[:-1]
        nme = '>' + nme

    if lex in fem_ending_numbers:
        if stem.endswith('T'):
            stem = stem[:-1]
            nme = 'T' + nme

    if lex in fem_end_words:
        if nu == 'pl' and stem.endswith('T'):
            stem = stem[:-1]
            nme = 'T' + nme
        elif nu == 'pl' and stem.endswith('WT'):
            stem = stem[:-2]
            nme = 'WT' + nme

    if lex in {'GDL/', 'XV>/', 'CLC/', 'CWCN/'} and stem.endswith('H'):
        stem = stem.rstrip('H')
        nme = 'H' + nme

    if lex in {'P<LH/', 'XJH/', 'BMH/'} and stem.endswith('T'):
        stem = stem.rstrip('T')
        nme = 'T' + nme

    if lex == 'TMJM/' and stem.endswith('JMM'):
        stem = stem.rstrip('M')
        nme = 'M' + nme

    if lex in {'HWH/', 'LJLJT/', '<W<JM/', '>LMNWT/'} and stem.endswith('J'):
        stem = stem.rstrip('J')
        nme = 'J' + nme

    if lex == 'YJH/' and stem.endswith('>'):
        stem = stem.rstrip('>')
        nme = '>' + nme

    return stem, nme


# Verbal endings of the hiphil, by (gender, number, person).
HIPHIL_PERF_ENDINGS = {
    ('m', 'sg', 'p3'): '',
    ('m', 'sg', 'p2'): 'T',
    ('f', 'sg', 'p3'): 'H',
    ('f', 'sg', 'p2'): 'T',
    ('unknown', 'sg', 'p1'): 'TJ',
    ('unknown', 'pl', 'p3'): 'W',
    ('m', 'pl', 'p3'): 'W',
    ('m', 'pl', 'p2'): 'TM',
    ('f', 'pl', 'p2'): 'TN',
    ('unknown', 'pl', 'p1'): ''
}

HIPHIL_IMPF_ENDINGS = {
    ('m', 'sg', 'p3'): '',
    ('m', 'sg', 'p2'): '',
    ('f', 'sg', 'p3'): '',
    ('f', 'sg', 'p2'): 'J',
    ('unknown', 'sg', 'p1'): '',
    ('m', 'pl', 'p3'): 'W',
    ('m', 'pl', 'p2'): 'W',
    ('f', 'pl', 'p3'): 'NH',
    ('f', 'pl', 'p2'): 'NH',
    ('unknown', 'pl', 'p1'): ''
}

HIPHIL_IMPV_ENDINGS = {
    ('m', 'sg', 'NA'): '',
    ('f', 'sg', 'NA'): 'J',
    ('m', 'pl', 'NA'): 'W',
    ('f', 'pl', 'NA'): 'NH',
}


class DSSWordProcessor:
    def __init__(self, F, L, tf_id):
        self.F = F
        self.L = L
        self.tf_id = tf_id
        self.book = F.book_etcbc.v(tf_id)
        self.chapter_num = F.chapter.v(tf_id)
        self.verse_num = F.verse.v(tf_id)
        self.lexeme = F.lex_etcbc.v(tf_id)
        self.glyphs = None
        self.hloc = 'H' if F.uvf_etcbc.v(tf_id) == 'H' else ''
        self.uvf_n = ''
        self.prs = ''
        self.nme = ''
        self.sp = F.sp_etcbc.v(tf_id)
        self.number = self.get_number()
        self.person = F.ps_etcbc.v(tf_id)
        self.gender = self.get_gender()
        self.state = F.st.v(tf_id) or None
        self.vs = F.vs_etcbc.v(tf_id)
        self.vt = F.vt_etcbc.v(tf_id)
        self.lang = F.lang_etcbc.v(tf_id)
        self.rec_signs = None
        self.cor_signs = None
        self.heb_g_cons = ''
        if F.glyphe.v(tf_id):
            self.glyphs = self.preprocess_text()
            self.rec_signs = self.get_sign_flags(F.rec, 'r')
            self.cor_signs = self.get_sign_flags(F.cor, 'c')
            self.heb_g_cons = to_hebrew(self.glyphs)
        self.stem = self.glyphs
        if self.stem:
            self.stem = self.stem.removesuffix(self.hloc).removesuffix(self.prs).removesuffix(self.uvf_n)
            if self.lexeme:
                self.stem, self.nme = parse_nme_dss(self.stem, self.lexeme, self.state, self.number, self.gender,
                                                    self.sp, self.prs)
                self.correct_nme_prs()
            morpho = F.morpho.v(tf_id)
            if morpho and self.sp == 'verb' and morpho[-1] == 'h':
                self.stem = self.stem.rstrip('H')
        if self.sp == 'verb':
            # These remove the verbal prefix and endings from the stem. So far only implemented for the hiphil.
            self.strip_preformative()
            self.strip_he_of_hiphil()
            self.strip_verbal_ending()
        self.prefix = self.get_prefix()

    def row(self, scroll, book, chapter, verse):
        return {'tf_id': self.tf_id, 'scroll': scroll, 'book': book, 'chapter': chapter, 'verse': verse,
                'lex': self.lexeme, 'g_cons': self.glyphs, 'stem': self.stem, 'pattern': '', 'pattern_g_cons': '',
                'vs': self.vs, 'vt': self.vt, 'nu': self.number, 'gn': self.gender, 'ps': self.person,
                'sp': self.sp, 'prs': self.prs, 'nme': self.nme, 'hloc': self.hloc, 'prefix': self.prefix,
                'rec_signs': self.rec_signs, 'cor_signs': self.cor_signs, 'heb_g_cons': self.heb_g_cons}

    def preprocess_text(self):
        """
        Remove spaces that occur in data (and also in manuscript!).
        """
        glyphs = self.F.glyphe.v(self.tf_id)
        glyphs = ''.join(glyphs.split())
        glyphs = self.disambiguate_sin_shin(glyphs)
        glyphs = self.replace_final_characters(glyphs)
        glyphs = self.get_pronominal_suffix(glyphs)
        return glyphs

    def get_sign_flags(self, feature, flag):
        """
        Returns a string with one character per consonant: flag if the feature has value 1 for the sign, else "n".
        For the feature rec (reconstructed signs) the flag is "r", for cor (corrected signs) "c".
        The feature cor has the values:
        0: not a corrected sign
        1: corrected by a modern editor
        2: corrected by an ancient editor
        3: corrected by an ancient editor, supralinear
        Only value 1 is flagged.
        """
        signs = self.L.d(self.tf_id, 'sign')
        return ''.join([flag if feature.v(s) == 1 else 'n' for s in signs if self.F.type.v(s) == 'cons'])

    def disambiguate_sin_shin(self, glyphs):
        """
        The consonant '#' is used for both 'C' and 'F'. We check in the lexeme
        to which of the two alternatives it should be converted. This appproach is crude,
        but works generally well. There is only one word with both F and C in the lexeme:
        >RTX##T> >AR:T.AX:CAF:T.:> in 4Q117
        """
        if '#' in glyphs:
            # hardcode the single word with both 'C' and 'F' in the lexeme.
            if glyphs == '>RTX##T>':
                glyphs = '>RTXCFT>'
            elif 'F' in self.lexeme:
                glyphs = glyphs.replace('#', 'F')
            else:
                glyphs = glyphs.replace('#', 'C')
        return glyphs

    @staticmethod
    def replace_final_characters(glyphs):
        """
        - Replaces space '\xa0' with ' '.
        - Replaces special final characters with ordinary characters in ETCBC transcription.
        """
        return glyphs.replace(u'\xa0', u' ') \
            .replace('k', 'K') \
            .replace('n', 'N') \
            .replace('m', 'M') \
            .replace('y', 'Y') \
            .replace('p', 'P')

    def get_pronominal_suffix(self, glyphs):
        """
        Check for ' in glyphs and check if it is a he locale.
        If not, then it is a pronominal suffix.
        """
        if "'" in glyphs and not self.hloc:
            if self.lexeme == '<WD/' and "'N" in glyphs:
                self.prs = glyphs.split("'N")[1]
                self.uvf_n = 'N'
            else:
                self.prs = glyphs.split("'")[1]
        return glyphs.replace("'", '')

    def correct_nme_prs(self):
        """
        Cases like elohaj (masc plural + 1 ps sg prs) are considered to have a nme J and prs ''.
        The prs has been assimilated completely to the nme. That is corrected here.
        """
        if self.gender == 'm' and self.number == 'pl' and self.prs == 'J' and self.nme == '':
            self.nme = 'J'
            self.prs = ''

    def get_number(self):
        """
        Number values are {'NA', 'du', 'pl', 'sg', 'unknown'}.
        We remove the unknowns.
        """
        number = self.F.nu_etcbc.v(self.tf_id)
        if number == 'unknown':
            return None
        return number

    def get_gender(self):
        gender = self.F.gn_etcbc.v(self.tf_id)
        if gender not in {'m', 'f'}:
            return None
        return gender

    def strip_he_of_hiphil(self):
        """Removes the H of the hiphil from the stem in the relevant tenses."""
        if self.vs == 'hif' and self.vt in {'perf', 'impv', 'infa', 'infc'} and self.lexeme and self.glyphs:
            if self.lexeme[0] != 'H' and self.glyphs[0] == 'H':
                self.stem = self.stem[1:]

    def strip_preformative(self):
        """Removes the preformative of the hiphil participle and imperfect from the stem."""
        if self.vs == 'hif' and self.lexeme and self.glyphs:
            if self.vt == 'ptca' and self.glyphs[0] == 'M':
                self.stem = self.stem[1:]
            elif self.vt in {'impf', 'wayq'}:
                if self.person in {'p2', 'p3'} and self.glyphs[0] == 'T':
                    self.stem = self.stem[1:]
                elif self.person == 'p3' and self.glyphs[0] == 'J':
                    self.stem = self.stem[1:]
                elif self.person == 'p1' and self.glyphs[0] in {'>', 'N'}:
                    self.stem = self.stem[1:]

    def strip_verbal_ending(self):
        """Removes the verbal ending of the hiphil from the stem."""
        if self.vs == 'hif' and self.lexeme and self.glyphs and self.book:
            gn, nu, ps = self.gender, self.number, self.person
            if gn in {'', None}:
                gn = 'unknown'

            if self.vt == 'perf':
                vbe = HIPHIL_PERF_ENDINGS[(gn, nu, ps)]
                if (gn, nu, ps) == ('unknown', 'pl', 'p3') and self.stem.endswith('J'):
                    vbe = 'J'  # single case in 1Qisaa, tf_id = 1899343
            elif self.vt in {'impf', 'wayq'}:
                vbe = HIPHIL_IMPF_ENDINGS.get((gn, nu, ps), '')
            elif self.vt == 'impv':
                vbe = HIPHIL_IMPV_ENDINGS[(gn, nu, ps)]
                if vbe == 'NH' and self.lexeme[-2] == 'N':
                    vbe = 'H'
            else:
                vbe = ''
            if self.stem.endswith(vbe):
                self.stem = self.stem.rstrip(vbe)

    def get_prefix(self):
        """Concatenated g_cons of the words prefixed to this word, often article or preposition."""
        prefix = ''
        previous_word_id = self.tf_id - 1
        while self.F.after.v(previous_word_id) is None:
            prev_word_g_cons = self.F.g_cons.v(previous_word_id)
            if prev_word_g_cons is None:
                prev_word_g_cons = ''
            prefix = prev_word_g_cons + prefix
            previous_word_id = previous_word_id - 1
        return prefix


class SPWordProcessor:
    def __init__(self, F, tf_id, sp_word_nodes):
        self.F = F
        self.tf_id = tf_id
        self.sp_word_nodes = sp_word_nodes
        self.lexeme = F.lex.v(tf_id)
        self.glyphs = F.g_cons.v(tf_id)
        self.number = self.get_number()
        self.nme = self.get_nme()
        self.stem = self.get_stem()

    def row(self, book, chapter, verse):
        F, tf_id = self.F, self.tf_id
        return {'tf_id': tf_id, 'scroll': 'SP', 'book': book, 'chapter': chapter, 'verse': verse,
                'lex': self.lexeme, 'g_cons': self.glyphs, 'stem': self.stem, 'pattern': '', 'pattern_g_cons': '',
                'vs': None,  # Todo: implement verbal stem
                'vt': F.vt.v(tf_id), 'nu': self.number, 'gn': self.get_gender(), 'ps': F.ps.v(tf_id),
                'sp': F.sp.v(tf_id), 'prs': get_prs(F.g_prs.v(tf_id)), 'nme': self.nme,
                'hloc': 'H' if F.g_uvf.v(tf_id) == '~H' else '', 'prefix': self.get_prefix(),
                'rec_signs': 'n' * len(self.glyphs), 'cor_signs': 'n' * len(self.glyphs),
                'heb_g_cons': to_hebrew(self.glyphs)}

    def get_number(self):
        number = self.F.nu.v(self.tf_id)
        if number in {'unknown', 'NA'}:
            return None
        return number

    def get_gender(self):
        gender = self.F.gn.v(self.tf_id)
        if gender == 'NA':
            return None

    def get_stem(self):
        stem = self.F.g_lex.v(self.tf_id)
        if self.lexeme in relevant_wt_words and self.number == 'sg' \
                and not stem.endswith('T'):
            if self.nme.startswith('T'):
                stem += 'T'
                self.nme = self.nme.lstrip('T')
            elif self.nme.startswith('WT'):
                stem += 'WT'
                self.nme = self.nme.lstrip('WT')
        elif self.lexeme in fem_ending_numbers:
            stem = stem[:-1]
            self.nme = 'T' + self.nme

        if self.lexeme == 'MR>CWT/':  # ad hoc action to make stem identical to MT.
            stem = 'MR>C'
        return stem

    def get_nme(self):
        if self.lexeme == 'MR>CWT/':  # ad hoc action to make stem identical to MT.
            return 'JT'
        return keep_consonants(self.F.g_nme.v(self.tf_id))

    def get_prefix(self):
        prefix = ''
        previous_word_id = self.tf_id - 1

        while not self.F.trailer.v(previous_word_id):
            prev_word_g_cons = self.F.g_cons.v(previous_word_id)
            if not prev_word_g_cons:
                prev_word_g_cons = ''
            prefix = prev_word_g_cons + prefix
            previous_word_id = previous_word_id - 1
            if previous_word_id not in self.sp_word_nodes:
                break
        return prefix


def make_table(rows):
    return pd.DataFrame(rows, columns=WORD_COLUMNS + ['lang'], dtype=object)


def build_mt_table(mt):
    """All words of the MT, with the vowel letter patterns parsed from the vocalized text.
    Ketiv/qere forms get no pattern."""
    F, L, T = mt.F, mt.L, mt.T
    patterns_and_prefixes = get_matres_patterns_and_prefixes(F, L)
    rows = []
    for v in F.otype.s('verse'):
        bo, ch, ve = T.sectionFromNode(v)
        for w in L.d(v, 'word'):
            matres_pattern, prefix = patterns_and_prefixes.get(w, ('', ''))
            row = MTWordProcessor(F, w).row(bo, int(ch), int(ve), matres_pattern, prefix)
            row['lang'] = F.language.v(w)
            rows.append(row)
    return make_table(rows)


def build_dss_table(dss, mt_sections):
    """All words of the biblical DSS in verses that also occur in the MT.
    Words without book, chapter, verse or lexeme, and words in fragments, are left out."""
    F, L, T = dss.F, dss.L, dss.T
    rows = []
    for scr in F.otype.s('scroll'):
        # Some scrolls consist of more than one node with the same name, e.g. 11Q5. These are merged.
        scroll_name = T.scrollName(scr)
        for w in L.d(scr, 'word'):
            word = DSSWordProcessor(F, L, w)
            bo, ch, ve = word.book, word.chapter_num, word.verse_num
            if not all([bo, ch, ve]) or ('f' in ch) or (word.lexeme in {None, ''}):
                continue
            section = (bo, int(ch), int(ve))
            if section in mt_sections:
                row = word.row(scroll_name, *section)
                row['lang'] = word.lang
                rows.append(row)
    return make_table(rows)


def build_sp_table(sp, mt_sections):
    """All words of the SP in verses that also occur in the MT."""
    F, L, T = sp.F, sp.L, sp.T
    sp_word_nodes = set(F.otype.s('word'))
    rows = []
    for v in F.otype.s('verse'):
        bo, ch, ve = T.sectionFromNode(v)
        section = (bo, int(ch), ve)
        if section not in mt_sections:
            continue
        for w in L.d(v, 'word'):
            row = SPWordProcessor(F, w, sp_word_nodes).row(*section)
            row['lang'] = F.language.v(w)
            rows.append(row)
    return make_table(rows)


def mt_sections(mt_table):
    return set(zip(mt_table.book, mt_table.chapter, mt_table.verse))
