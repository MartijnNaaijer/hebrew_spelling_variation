"""
Here the harmonization of BHSA and DSS data takes place. These are two different datasets with different conventions.
The overarching class is Corpus. A corpus contains data about all the relevant
biblical manuscripts. A Corpus object contains Scroll objects, and a scroll contains Verse objects and Word objects.

The scrolls include the biblical Dead Sea Scrolls and the Codex Leningradensis, here called MT.

The MT dataset is based on the text-fabric dataset Biblia Hebraica Stuttgartensia Amstelodamensis
(see github.com/etcbc/bhsa).
The DSS dataset is based on the text-fabric dataset DSS (see github.com/etcbc/dss).

TODO: add processing of SP data.
"""
from dataclasses import dataclass, field

from add_hebrew_text_column import HebrewTextAdder
from config import bhsa_version, dss_version, sp_version
from special_data import j_lexemes, fem_end_words

from tf.app import use
DSS = use('etcbc/dss:clone', checkout='clone', version=dss_version, provenanceSpec=dict(moduleSpecs=[]))
Fdss, Ldss, Tdss = DSS.api.F, DSS.api.L, DSS.api.T

SP = use('dt-ucph/sp:clone', checkout='clone', version=sp_version, provenanceSpec=dict(moduleSpecs=[]))
Fsp, Lsp, Tsp = SP.api.F, SP.api.L, SP.api.T

MT = use('etcbc/bhsa', version=bhsa_version)
MT.load(['g_prs', 'g_nme', 'g_pfm', 'g_vbs', 'g_vbe'])
F, L, T = MT.api.F, MT.api.L, MT.api.T


@dataclass
class Word:
    """prefix are concatenated g_cons of words prefixed to a word, often article or prep"""
    tf_word_id: int
    book: str
    chapter_num: int
    verse_num: int
    g_cons: str
    lex: str
    sp: str
    person: str
    number: str
    gender: str
    state: str
    vs: str
    vt: str
    lang: str
    rec_signs: str
    cor_signs: str
    stem: str = None
    prs_cons: str = None
    nme_cons: str = None
    hloc: str = ''
    matres_pattern: str = ''
    prefix: str = None
    heb_g_cons: str = ''
    g_pfm: str = ''
    g_vbs: str = ''
    g_vbe: str = ''


@dataclass
class Verse:
    manuscript: str
    bo: str
    ch: int
    ve: int
    words: list[Word] = field(default_factory=list)


class Scroll:
    scrolls = {}

    def __init__(self, scroll_name):
        self.scroll_name = scroll_name
        self.verses = {}
        self.words = []
        Scroll.scrolls[scroll_name] = self


class MTWordProcessor:
    """"""
    def __init__(self, tf_id):

        self.prs_chars = {'>', 'D', 'H', 'J', 'K', 'M', 'N', 'W'}
        self.consonants = {'<', '>', 'B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M',
                           'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'X', 'Y', 'Z', '#'}

        self.tf_id = tf_id
        self.book = F.book.v(tf_id)
        self.chapter_num = F.chapter.v(tf_id)
        self.verse_num = F.verse.v(tf_id)
        self.lexeme = F.lex.v(tf_id)
        self.glyphs = F.g_cons.v(tf_id)
        self.hloc = self.get_he_locale()
        self.sp = F.sp.v(tf_id)
        self.number = self.get_number()
        self.person = F.ps.v(tf_id)
        self.gender = self.get_gender()
        self.state = self.get_state()
        self.vs = F.vs.v(tf_id)
        self.vt = F.vt.v(tf_id)
        self.lang = F.language.v(tf_id)
        self.rec_signs = ''.join(['n' for char in self.glyphs])
        self.cor_signs = ''.join(['n' for char in self.glyphs])
        self.stem = self.get_stem()
        self.nme = self.get_nme()
        self.prs = self.get_prs()
        self.heb_text_adder = HebrewTextAdder(self.glyphs)
        self.heb_g_cons = self.heb_text_adder.get_hebrew_g_cons()
        self.g_pfm = self.get_pfm()
        self.g_vbs = self.get_vbs()
        self.g_vbe = self.get_vbe()

    def create_word(self):

        return Word(self.tf_id,
                    self.book,
                    self.chapter_num,
                    self.verse_num,
                    self.glyphs,
                    self.lexeme,
                    self.sp,
                    self.person,
                    self.number,
                    self.gender,
                    self.state,
                    self.vs,
                    self.vt,
                    self.lang,
                    self.rec_signs,
                    self.cor_signs,
                    stem=self.stem,
                    prs_cons=self.prs,
                    nme_cons=self.nme,
                    hloc=self.hloc,
                    heb_g_cons=self.heb_g_cons,
                    g_pfm=self.g_pfm,
                    g_vbs=self.g_vbs,
                    g_vbe=self.g_vbe
                    )

    def get_number(self):
        number = F.nu.v(self.tf_id)
        if number in {'unknown', 'NA'}:
            return None
        return number

    def get_gender(self):
        gender = F.gn.v(self.tf_id)
        if gender == 'NA':
            return None
        return gender

    def get_state(self):
        state = F.st.v(self.tf_id)
        if state == 'NA':
            return None
        return state

    def get_he_locale(self):
        if F.uvf.v(self.tf_id) == 'H':
            return 'H'
        return ''

    def get_prs(self):
        suff = F.g_prs.v(self.tf_id)
        # Cases like >DNJ in Genesis 19:2 (masc plural with prs)
        if suff == '+':
            suff = 'J'
        prs_cons = ''.join([ch for ch in suff if ch in self.prs_chars])
        return prs_cons

    def get_stem(self):
        return ''.join([ch for ch in F.g_lex.v(self.tf_id)
                        if ch in self.consonants])

    def get_nme(self):
        g_nme = F.g_nme.v(self.tf_id)
        prs = F.g_prs.v(self.tf_id)
        # According to BHSA H is not nominal ending, but we strip it ad hoc.
        if self.lexeme == 'NGH/' and self.glyphs == 'NGH':
            g_nme = 'H'
            self.stem = 'NG'
        # Cases like >DNJ in Genesis 19:2 (masc plural with prs), decision: no nme, but prs
        if prs == '+':
            g_nme = g_nme.rstrip('J')
        nme_cons = ''.join([ch for ch in g_nme if ch in self.consonants])

        return nme_cons

    def get_vbs(self):
        vbs_cons = ''.join([ch for ch in F.g_vbs.v(self.tf_id) if ch in self.consonants])
        return vbs_cons

    def get_pfm(self):
        pfm_cons = ''.join([ch for ch in F.g_pfm.v(self.tf_id) if ch in self.consonants])
        return pfm_cons

    def get_vbe(self):
        vbe_cons = ''.join([ch for ch in F.g_vbe.v(self.tf_id) if ch in self.consonants])
        return vbe_cons


def parse_nme_dss(stem, lex, state, nu, gn, sp, suff):
    """
    :param stem: initial stem (needs further parsing)
    :param lex: lexeme
    :param state: state a or c
    :param nu: number
    :param gn: gender
    :param sp: part of speech
    :param suff: pronominal suffix
    :return: stem and nme
    """
    nme = ''
    lex_no_special_signs = lex.strip('/').strip('=')

    if lex in j_lexemes:
        if suff and stem.endswith('JJ') and nu == 'pl':
            stem = stem.removesuffix('J')
            nme += 'J'
    else:
        if suff and stem.endswith('J') and nu == 'pl':
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
    elif sp == 'adjv' and lex_no_special_signs[-1] == 'J' and len(lex) > 1 and stem.endswith('J'):
        stem = stem.removesuffix('J')
        nme = 'J' + nme

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
    elif lex not in j_lexemes and stem.endswith('M') and nu in {'du', 'pl'} and len(stem) > 2 and (lex_no_special_signs[-1] != 'M' or lex == '>LHJM/'):
        stem = stem.removesuffix('M')
        nme = 'M' + nme

    if stem.endswith('WT') and nu == 'pl':
        stem = stem.removesuffix('WT')
        nme = 'WT' + nme
    if stem.endswith('WTJ') and nu == 'pl':
        stem = stem.removesuffix('WTJ')
        nme = 'WTJ' + nme
    elif stem.endswith('T') and nu == 'pl' and gn == 'f':
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

    if lex in fem_end_words:
        if nu == 'pl' and stem.endswith('T'):
            stem = stem[:-1]
            nme = 'T' + nme
        elif nu == 'pl' and stem.endswith('WT'):
            stem = stem[:-2]
            nme = 'WT' + nme

    if lex == 'CWCN/' and stem.endswith('H'):
        stem = stem.rstrip('H')
        nme += 'H'

    if lex == 'CLC/' and stem.endswith('H'):
        stem = stem.rstrip('H')
        nme = 'H' + nme

    if lex == 'GDL/' and stem.endswith('H'):
        stem = stem.rstrip('H')
        nme = 'H' + nme

    if lex == 'XV>/' and stem.endswith('H'):
        stem = stem.rstrip('H')
        nme = 'H' + nme

    if lex == 'P<LH/' and stem.endswith('T'):
        stem = stem.rstrip('T')
        nme = 'T' + nme

    if lex == 'XJH/' and stem.endswith('T'):
        stem = stem.rstrip('T')
        nme = 'T' + nme

    if lex == 'TMJM/' and stem.endswith('JMM'):
        stem = stem.rstrip('M')
        nme = 'M' + nme

    if lex == 'BMH/' and stem.endswith('T'):
        stem = stem.rstrip('T')
        nme = 'T' + nme

    if lex in {'HWH/', 'PLJLJH/', 'LJLJT/', '<W<JM/'} and stem.endswith('J'):
        stem = stem.rstrip('J')
        nme = 'J' + nme

    if lex == 'YJH/' and stem.endswith('>'):
        stem = stem.rstrip('>')
        nme = '>' + nme

    return stem, nme


class DSSWordProcessor:
    """"""
    def __init__(self, tf_id):
        self.tf_id = tf_id
        self.book = Fdss.book_etcbc.v(tf_id)
        self.chapter_num = Fdss.chapter.v(tf_id)
        self.verse_num = Fdss.verse.v(tf_id)
        self.lexeme = Fdss.lex_etcbc.v(tf_id)
        self.glyphs = None
        self.hloc = self.get_he_locale()
        self.prs = ''
        self.nme = ''
        self.sp = Fdss.sp_etcbc.v(tf_id)
        self.number = self.get_number()
        self.person = Fdss.ps_etcbc.v(tf_id)
        self.gender = self.get_gender()
        self.state = self.get_state()
        self.vs = Fdss.vs_etcbc.v(tf_id)
        self.vt = Fdss.vt_etcbc.v(tf_id)
        self.lang = Fdss.lang_etcbc.v(tf_id)
        self.rec_signs = None
        self.cor_signs = None
        self.heb_g_cons = ''
        if Fdss.glyphe.v(tf_id):
            self.glyphs = self.preprocess_text()
            self.rec_signs = self.get_reconstructed_signs()
            self.cor_signs = self.get_corrected_signs()
            self.heb_text_adder = HebrewTextAdder(self.glyphs)
            self.heb_g_cons = self.heb_text_adder.get_hebrew_g_cons()
        self.stem = self.glyphs
        if self.stem:
            self.stem = self.stem.removesuffix(self.hloc).removesuffix(self.prs)
            if self.lexeme:
                self.parse_nme()
            if Fdss.morpho.v(self.tf_id):
                if self.sp == 'verb' and Fdss.morpho.v(self.tf_id)[-1] == 'h':
                    self.stem = self.stem.rstrip('H')
        self.g_pfm = self.get_pfm()  # So far only for hifil triliteral!!
        self.g_vbs = self.get_vbs()  # So far only for hifil triliteral!!
        self.g_vbe = self.get_vbe()

    def create_word(self):

        return Word(self.tf_id,
                    self.book,
                    self.chapter_num,
                    self.verse_num,
                    self.glyphs,
                    self.lexeme,
                    self.sp,
                    self.person,
                    self.number,
                    self.gender,
                    self.state,
                    self.vs,
                    self.vt,
                    self.lang,
                    self.rec_signs,
                    self.cor_signs,
                    prs_cons=self.prs,
                    nme_cons=self.nme,
                    hloc=self.hloc,
                    heb_g_cons=self.heb_g_cons,
                    stem=self.stem,
                    g_pfm=self.g_pfm,
                    g_vbs=self.g_vbs,
                    g_vbe=self.g_vbe
                    )

    def preprocess_text(self):
        """
        Remove spaces that occur in data (and also in manuscript!).
        """
        glyphs = Fdss.glyphe.v(self.tf_id)
        if glyphs:
            glyphs = ''.join(glyphs.split())
            glyphs = self.disambiguate_sin_shin(glyphs)
            glyphs = self.replace_final_characters(glyphs)
            glyphs = self.get_pronominal_suffix(glyphs)

        return glyphs

    def get_reconstructed_signs(self):
        """
        Returns string with indication of which signs are reconstructed ("r")
        and which signs are not reconstructed ("n").
        """
        signs = Ldss.d(self.tf_id, 'sign')
        return ''.join(['r' if Fdss.rec.v(s) == 1 else 'n' for s in signs if Fdss.type.v(s) == 'cons'])

    def get_corrected_signs(self):
        """
        Returns string with indication of which signs are corrected:
        0: not a corrected sign
        1: corrected by a modern editor
        2: corrected by an ancient editor
        3: corrected by an ancient editor, supralinear
        """
        signs = Ldss.d(self.tf_id, 'sign')
        return ''.join(['c' if Fdss.cor.v(s) == 1 else 'n' for s in signs if Fdss.type.v(s) == 'cons'])

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
        glyphs = glyphs.replace(u'\xa0', u' ') \
            .replace('k', 'K') \
            .replace('n', 'N') \
            .replace('m', 'M') \
            .replace('y', 'Y') \
            .replace('p', 'P')
        return glyphs

    def get_he_locale(self):
        """
        Retrieve he locale from feature uvf_etcbc.

        """
        if Fdss.uvf_etcbc.v(self.tf_id) == 'H':
            return 'H'
        return ''

    def get_pronominal_suffix(self, glyphs):
        """
        Check for ' in glyphs and check if it is a he locale.
        If not, then it is a pronominal suffix.
        """
        if "'" in glyphs and not self.hloc:
            self.prs = glyphs.split("'")[1]

        glyphs = glyphs.replace("'", '')
        return glyphs

    def parse_nme(self):
        self.stem, self.nme = parse_nme_dss(self.stem, self.lexeme, self.state, self.number, self.gender, self.sp, self.prs)

    def get_number(self):
        """
        Number values are {'NA', 'du', 'pl', 'sg', 'unknown'}.
        We remove the unknowns.
        """
        number = Fdss.nu_etcbc.v(self.tf_id)
        if number == 'unknown':
            return None
        return number

    def get_gender(self):
        gender = Fdss.gn_etcbc.v(self.tf_id)
        if gender not in {'m', 'f'}:
            return None
        return gender

    def get_state(self):
        state = Fdss.st.v(self.tf_id)
        if not state:
            return None
        return state

    def get_vbs(self):
        """So far only implemented for hiphil.
        Check if relevant tense has valid value and glyphs start with H.
        Returns H if present and adapts stem accordingly.
        """
        if self.vs == 'hif' and self.vt in {'perf', 'impv', 'infa', 'infc'} and self.lexeme and self.glyphs:
            if self.lexeme[0] != 'H' and self.glyphs[0] == 'H':
                self.stem = self.stem[1:]
                return 'H'
            else:
                return ''

    def get_pfm(self):
        """Only implemented for hiphil."""
        if self.vs == 'hif' and self.lexeme and self.glyphs:
            if self.vt == 'ptca' and self.glyphs[0] == 'M':
                self.stem = self.stem[1:]
                return 'M'
            elif self.vt in {'impf', 'wayq'}:
                if self.person in {'p2', 'p3'} and self.glyphs[0] == 'T':
                    self.stem = self.stem[1:]
                    return 'T'
                elif self.person == 'p3' and self.glyphs[0] == 'J':
                    self.stem = self.stem[1:]
                    return 'J'
                elif self.person == 'p1' and self.glyphs[0] in {'>', 'N'}:
                    self.stem = self.stem[1:]
                    return self.glyphs[0]
                else:
                    return ''
            else:
                return ''

    def get_vbe(self):
        """Only implemented for hiphil."""
        perf_dict = {
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

        impf_dict = {
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

        impv_dict = {
            ('m', 'sg', 'NA'): '',
            ('f', 'sg', 'NA'): 'J',
            ('m', 'pl', 'NA'): 'W',
            ('f', 'pl', 'NA'): 'NH',
        }

        if self.vs == 'hif' and self.lexeme and self.glyphs:
            if self.book:
                gn, nu, ps = self.gender, self.number, self.person
                if gn in {'', None}:
                    gn = 'unknown'

                if self.vt == 'perf':
                    vbe = perf_dict[(gn, nu, ps)]
                    if (gn, nu, ps) == ('unknown', 'pl', 'p3') and self.stem.endswith('J'):
                        vbe = 'J' # single case in 1Qisaa, tf_id = 1899343
                elif self.vt == 'impf':
                    vbe = impf_dict[(gn, nu, ps)]
                elif self.vt == 'impv':
                    vbe = impv_dict[(gn, nu, ps)]
                    if vbe == 'NH' and self.lexeme[-2] == 'N':
                        vbe = 'H'
                else:
                    vbe = ''
                if self.stem.endswith(vbe):
                    self.stem = self.stem.rstrip(vbe)
                    return vbe
                else:
                    return ''
            else:
                return ''
        return ''


class SPWordProcessor:
    """"""
    def __init__(self, tf_id):
        self.prs_chars = {'>', 'D', 'H', 'J', 'K', 'M', 'N', 'W'}
        self.consonants = {'<', '>', 'B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M',
                           'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'X', 'Y', 'Z', '#'}
        self.tf_id = tf_id
        self.book = Fsp.book.v(tf_id)
        self.chapter_num = Fsp.chapter.v(tf_id)
        self.verse_num = Fsp.verse.v(tf_id)
        self.lexeme = Fsp.lex.v(tf_id)
        self.glyphs = Fsp.g_cons.v(tf_id)
        self.hloc = self.get_he_locale()
        self.sp = Fsp.sp.v(tf_id)
        self.number = self.get_number()
        self.person = Fsp.ps.v(tf_id)
        self.gender = self.get_gender()
        self.state = self.get_state()
        self.vs = None # Todo: implement verbals stem
        self.vt = Fsp.vt.v(tf_id)
        self.lang = Fsp.language.v(tf_id)
        self.rec_signs = ''.join(['n' for char in self.glyphs])
        self.cor_signs = ''.join(['n' for char in self.glyphs])
        self.stem = Fsp.g_lex.v(tf_id)
        self.nme = self.get_nme()
        self.prs = self.get_prs()

    def create_word(self):

        return Word(self.tf_id,
                    self.book,
                    self.chapter_num,
                    self.verse_num,
                    self.glyphs,
                    self.lexeme,
                    self.sp,
                    self.person,
                    self.number,
                    self.gender,
                    self.state,
                    self.vs,
                    self.vt,
                    self.lang,
                    self.rec_signs,
                    self.cor_signs,
                    stem=self.stem,
                    prs_cons=self.prs,
                    nme_cons=self.nme,
                    hloc=self.hloc)

    def get_number(self):
        number = Fsp.nu.v(self.tf_id)
        if number in {'unknown', 'NA'}:
            return None
        return number

    def get_gender(self):
        gender = Fsp.gn.v(self.tf_id)
        if gender == 'NA':
            return None

    def get_state(self):
        """Not implemented yet"""
        return None

    def get_he_locale(self):
        """Not implemented yet"""
        h_loc = ''
        if Fsp.g_uvf == 'H':
            h_loc = 'H'
        return h_loc

    def get_prs(self):
        suff = Fsp.g_prs.v(self.tf_id)
        if suff == '+':
            suff = 'J'
        prs_cons = ''.join([ch for ch in suff if ch in self.prs_chars])
        return prs_cons

    def get_stem(self):
        """Not implemented yet"""
        return None

    def get_nme(self):
        nme_cons = ''.join([ch for ch in Fsp.g_nme.v(self.tf_id) if ch in self.consonants])
        return nme_cons


class Corpus:
    """"""
    def __init__(self, corpus_name):
        self.corpus_name = corpus_name
        self.scroll_set = set()
        self.scroll_verse_set = set()

        self.add_dss()
        self.add_mt()
        self.add_sp()

    def add_dss(self):
        """
        add_dss adds the DSS data to the corpus.
        It creates Scroll objects,
        and adds Verse and WOrds objects to them.
        """
        for scr in Fdss.otype.s('scroll'):
            scroll_name = Tdss.scrollName(scr)
            # Is the if... needed? check: heeft te maken met 11q4 ezekiel/Psalms issue
            if scroll_name not in self.scroll_set:
                scroll = Scroll(scroll_name)
            self.scroll_set.add(scroll_name)

            words = Ldss.d(scr, 'word')
            for wo in words:
                word_processor = DSSWordProcessor(wo)
                dss_word_object = word_processor.create_word()
                bo, ch, ve = dss_word_object.book, dss_word_object.chapter_num, dss_word_object.verse_num

                if not all([bo, ch, ve]) or ('f' in ch) or (dss_word_object.lex in {None, ''}):
                    continue

                scroll_verse = (scroll_name, bo, ch, ve)
                if scroll_verse not in self.scroll_verse_set:

                    verse = Verse(scroll_name, bo, ch, ve)
                    Scroll.scrolls[scroll_name].verses[(bo, int(ch), int(ve))] = verse
                self.scroll_verse_set.add(scroll_verse)
                Scroll.scrolls[scroll_name].verses[(bo, int(ch), int(ve))].words.append(dss_word_object)

    def add_mt(self):
        """
        Does the same as add_dss, but then for the MT data.
        """
        scroll = Scroll('MT')

        for b in F.otype.s('book'):
            verses = L.d(b, 'verse')
            for v in verses:
                bo, ch, ve = T.sectionFromNode(v)
                verse = Verse('MT', bo, ch, ve)
                scroll.verses[(bo, int(ch), int(ve))] = verse
                words = L.d(v, 'word')
                for wo in words:
                    word_processor = MTWordProcessor(wo)
                    mt_word_object = word_processor.create_word()
                    scroll.verses[(bo, int(ch), int(ve))].words.append(mt_word_object)

    def add_sp(self):
        """
        Adds the Samaritan Pentateuch to the corpus.
        Note that verses are not converted to integer, because there is a verse '36a' in Genesis.
        This could become nasty somewhere. Todo: find solution for this.
        """
        scroll = Scroll('SP')

        for b in Fsp.otype.s('book'):
            verses = Lsp.d(b, 'verse')
            for v in verses:
                bo, ch, ve = Tsp.sectionFromNode(v)
                verse = Verse('SP', bo, ch, ve)
                scroll.verses[(bo, int(ch), ve)] = verse
                words = Lsp.d(v, 'word')
                for wo in words:
                    word_processor = SPWordProcessor(wo)
                    sp_word_object = word_processor.create_word()
                    scroll.verses[(bo, int(ch), ve)].words.append(sp_word_object)
