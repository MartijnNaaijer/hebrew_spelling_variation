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

from tf.app import use
DSS = use('etcbc/dss:clone', checkout='clone', version=dss_version, provenanceSpec=dict(moduleSpecs=[]))
Fdss, Ldss, Tdss = DSS.api.F, DSS.api.L, DSS.api.T

#SP = use('dt-ucph/sp:clone', checkout='clone', version=sp_version, provenanceSpec=dict(moduleSpecs=[]))
#Fsp, Lsp, Tsp = SP.api.F, SP.api.L, SP.api.T

MT = use('etcbc/bhsa', version=bhsa_version)
MT.load(['g_prs', 'g_nme', 'g_pfm', 'g_vbs', 'g_vbe'])
F, L, T = MT.api.F, MT.api.L, MT.api.T


@dataclass
class Word:
    """prefix_g_cons are concatenated g_cons of words prefixed to a word, often article or prep"""
    tf_word_id: int
    bo: str
    ch: int
    ve: int
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
    prefix_g_cons: str = None
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
        if suff == '+':
            suff = 'J'
        prs_cons = ''.join([ch for ch in suff if ch in self.prs_chars])
        return prs_cons

    def get_stem(self):
        return ''.join([ch for ch in F.g_lex.v(self.tf_id)
                        if ch in self.consonants])

    def get_nme(self):
        nme_cons = ''.join([ch for ch in F.g_nme.v(self.tf_id) if ch in self.consonants])
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
        self.g_pfm = self.get_pfm()  # So far only for hifil triliteral!!
        self.g_vbs = self.get_vbs()  # So far only for hifil triliteral!!
        self.g_vbe = ''

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
                self.stem = self.glyphs[1:]
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






# class SPWordProcessor:
#     """"""
#
#     def __init__(self, tf_id):
#         self.prs_chars = {'>', 'D', 'H', 'J', 'K', 'M', 'N', 'W'}
#         self.consonants = {'<', '>', 'B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M',
#                            'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'X', 'Y', 'Z', '#'}
#
#         self.tf_id = tf_id
#         self.book = Fsp.book.v(tf_id)
#         self.chapter_num = Fsp.chapter.v(tf_id)
#         self.verse_num = Fsp.verse.v(tf_id)
#         self.lexeme = Fsp.lex.v(tf_id)
#         self.glyphs = Fsp.g_cons.v(tf_id)
#         self.hloc = self.get_he_locale()
#         self.sp = Fsp.sp.v(tf_id)
#         self.number = self.get_number()
#         self.person = Fsp.ps.v(tf_id)
#         self.gender = self.get_gender()
#         self.state = self.get_state()
#         self.vs = None # Todo: implement verbals stem
#         self.vt = Fsp.vt.v(tf_id)
#         self.lang = Fsp.language.v(tf_id)
#         self.rec_signs = ''.join(['n' for char in self.glyphs])
#         self.cor_signs = ''.join(['n' for char in self.glyphs])
#         self.stem = self.get_stem()
#         self.nme = self.get_nme()
#         self.prs = self.get_prs()
#
#     def create_word(self):
#
#         return Word(self.tf_id,
#                     self.book,
#                     self.chapter_num,
#                     self.verse_num,
#                     self.glyphs,
#                     self.lexeme,
#                     self.sp,
#                     self.person,
#                     self.number,
#                     self.gender,
#                     self.state,
#                     self.vs,
#                     self.vt,
#                     self.lang,
#                     self.rec_signs,
#                     self.cor_signs,
#                     stem=self.stem,
#                     prs_cons=self.prs,
#                     nme_cons=self.nme,
#                     hloc=self.hloc)
#
#     def get_number(self):
#         number = Fsp.nu.v(self.tf_id)
#         if number in {'unknown', 'NA'}:
#             return None
#         return number
#
#     def get_gender(self):
#         gender = Fsp.gn.v(self.tf_id)
#         if gender == 'NA':
#             return None
#         return gender
#
#     def get_state(self):
#         """Not implemented yet"""
#         return None
#
#     def get_he_locale(self):
#         """Not implemented yet"""
#         return None
#
#     def get_prs(self):
#         suff = Fsp.g_prs.v(self.tf_id)
#         if suff == '+':
#             suff = 'J'
#         prs_cons = ''.join([ch for ch in suff if ch in self.prs_chars])
#         return prs_cons
#
#     def get_stem(self):
#         """Not implemented yet"""
#         return None
#
#     def get_nme(self):
#         nme_cons = ''.join([ch for ch in Fsp.g_nme.v(self.tf_id) if ch in self.consonants])
#         return nme_cons


class Corpus:
    """"""
    def __init__(self, corpus_name):
        self.corpus_name = corpus_name
        self.scroll_set = set()
        self.scroll_verse_set = set()

        self.add_dss()
        self.add_mt()
        #self.add_sp()

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
                bo, ch, ve = dss_word_object.bo, dss_word_object.ch, dss_word_object.ve

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

    # def add_sp(self):
    #     """
    #     Adds the Samaritan Pentateuch to the corpus.
    #     Note that verses are not converted to integer, because there is a verse '36a' in Genesis.
    #     This could become nasty somewhere. Todo: find solution for this.
    #     """
    #     scroll = Scroll('SP')
    #
    #     for b in Fsp.otype.s('book'):
    #         verses = Lsp.d(b, 'verse')
    #         for v in verses:
    #             bo, ch, ve = Tsp.sectionFromNode(v)
    #             verse = Verse('SP', bo, ch, ve)
    #             scroll.verses[(bo, int(ch), ve)] = verse
    #             words = Lsp.d(v, 'word')
    #             for wo in words:
    #                 word_processor = SPWordProcessor(wo)
    #                 sp_word_object = word_processor.create_word()
    #                 scroll.verses[(bo, int(ch), ve)].words.append(sp_word_object)
