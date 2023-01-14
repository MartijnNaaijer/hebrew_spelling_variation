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

from config import bhsa_version, dss_version, sp_version

from tf.app import use
DSS = use('etcbc/dss:clone', checkout='clone', version=dss_version, provenanceSpec=dict(moduleSpecs=[]))
Fdss, Ldss, Tdss = DSS.api.F, DSS.api.L, DSS.api.T

SP = use('dt-ucph/sp:clone', checkout='clone', version=sp_version, provenanceSpec=dict(moduleSpecs=[]))
Fsp, Lsp, Tsp = SP.api.F, SP.api.L, SP.api.T

MT = use('etcbc/bhsa', version=bhsa_version)
MT.load(['g_prs', 'g_nme'])
F, L, T = MT.api.F, MT.api.L, MT.api.T


class Word:
    """prefix_g_cons are concatenated g_cons of words prefixed to a word, often article or prep"""

    def __init__(self, tf_word_id, bo, ch, ve, g_cons, lex,
                 sp, person, number, gender, state,
                 vs, vt, lang, rec_signs, cor_signs,
                 stem=None, prs_cons=None, nme_cons=None,
                 hloc='', matres_pattern='', prefix_g_cons=None):
        self.tf_word_id = tf_word_id
        self.bo = bo
        self.ch = ch
        self.ve = ve
        self.g_cons = g_cons
        self.lex = lex
        self.sp = sp
        self.person = person
        self.number = number
        self.gender = gender
        self.state = state
        self.vs = vs
        self.vt = vt
        self.lang = lang
        self.rec_signs = rec_signs
        self.cor_signs = cor_signs
        self.stem = stem
        self.prs_cons = prs_cons
        self.nme_cons = nme_cons
        self.hloc = hloc
        self.matres_pattern = matres_pattern
        self.prefix_g_cons = prefix_g_cons


class Verse:
    def __init__(self, manuscript, bo, ch, ve):
        self.manuscript = manuscript
        self.bo = bo
        self.ch = ch
        self.ve = ve
        self.string_sequence = ''
        self.characters = []
        self.words = []
        self.alignments = {}

    def __str__(self):
        return f'{self.manuscript} {self.bo} {self.ch} {self.ve}'


class Scroll:
    def __init__(self, scroll_name):
        self.scroll_name = scroll_name
        self.verses = {}
        self.words = []


class MTWordProcessor:
    """"""

    def __init__(self, tf_id):

        self.prs_chars = {'>', 'D', 'H', 'J', 'K', 'M', 'N', 'W'}
        self.consonants = {'<', '>', 'B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M',
                           'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'X', 'Y', 'Z', '#'}
        #self.h_lexemes = {'MKSH=/', 'M<FH/', 'MR>H/', 'PH/', 'MCTH/'}

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
        self.rec_signs = ''.join(['0' for char in self.glyphs])
        self.cor_signs = ''.join(['0' for char in self.glyphs])
        self.stem = self.get_stem()
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
        return None

    def get_prs(self):
        suff = F.g_prs.v(self.tf_id)
        if suff == '+':
            suff = 'J'
        prs_cons = ''.join([ch for ch in suff if ch in self.prs_chars])
        return prs_cons

    def get_stem(self):
        return ''.join([ch for ch in F.g_lex.v(self.tf_id) if ch in self.consonants])

    def get_nme(self):
        nme_cons = ''.join([ch for ch in F.g_nme.v(self.tf_id) if ch in self.consonants])
        return nme_cons


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
        self.prs = None
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

        if Fdss.glyphe.v(tf_id):
            self.glyphs = self.preprocess_text()
            self.rec_signs = self.get_reconstructed_signs()
            self.cor_signs = self.get_corrected_signs()

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
                    hloc=self.hloc
                    )

    def preprocess_text(self):
        """
        -remove spaces that occur in data (and also in manuscript!)
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
        returns string with indication of which signs are reconstructed (1)
        and which signs are visible (0)
        """
        signs = Ldss.d(self.tf_id, 'sign')
        return ''.join([str(Fdss.rec.v(s)) if Fdss.rec.v(s) == 1 else '0' for s in signs if Fdss.type.v(s) == 'cons'])

    def get_corrected_signs(self):
        """
        returns string with indication of which signs are corrected:
        0: not a corrected sign
        1: corrected by a modern editor
        2: corrected by an ancient editor
        3: corrected by an ancient editor, supralinear
        """
        signs = Ldss.d(self.tf_id, 'sign')
        return ''.join([str(Fdss.cor.v(s)) if Fdss.cor.v(s) == 1 else '0' for s in signs if Fdss.type.v(s) == 'cons'])

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
        Retrieve he locale from morpho string
        """
        if Fdss.morpho.v(self.tf_id) and Fdss.morpho.v(self.tf_id).endswith('Xd'):
            return 'H'
        return None

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


class SPWordProcessor:
    """"""

    def __init__(self, tf_id):

        self.prs_chars = {'>', 'D', 'H', 'J', 'K', 'M', 'N', 'W'}
        self.consonants = {'<', '>', 'B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M',
                           'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'X', 'Y', 'Z', '#'}
        #self.h_lexemes = {'MKSH=/', 'M<FH/', 'MR>H/', 'PH/', 'MCTH/'}

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
        self.rec_signs = ''.join(['0' for char in self.glyphs])
        self.cor_signs = ''.join(['0' for char in self.glyphs])
        self.stem = self.get_stem()
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
        return gender

    def get_state(self):
        """Not implemented yet"""
        return None

    def get_he_locale(self):
        """Not implemented yet"""
        return None

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
        self.scrolls = {}
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
            if scroll_name not in self.scroll_set:
                scroll = Scroll(scroll_name)
                self.scrolls[scroll_name] = scroll
            self.scroll_set.add(scroll_name)

            words = Ldss.d(scr, 'word')
            for wo in words:
                word_processor = DSSWordProcessor(wo)
                dss_word_object = word_processor.create_word()

                bo = dss_word_object.bo
                ch = dss_word_object.ch
                ve = dss_word_object.ve

                if not all([bo, ch, ve]) or ('f' in ch) or (dss_word_object.lex in {None, ''}):
                    continue

                scroll_verse = (scroll_name, bo, ch, ve)
                if scroll_verse not in self.scroll_verse_set:

                    verse = Verse(scroll_name, bo, ch, ve)
                    self.scrolls[scroll_name].verses[(bo, int(ch), int(ve))] = verse
                self.scroll_verse_set.add(scroll_verse)
                self.scrolls[scroll_name].verses[(bo, int(ch), int(ve))].words.append(dss_word_object)

    def add_mt(self):
        """
        Does the same as add_dss, but then for the MT data.
        """
        scroll = Scroll('MT')
        self.scrolls['MT'] = scroll

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
        self.scrolls['SP'] = scroll

        for b in Fsp.otype.s('book'):
            verses = Lsp.d(b, 'verse')
            for v in verses:
                bo, ch, ve = Tsp.sectionFromNode(v)
                print(bo, ch, ve)
                verse = Verse('SP', bo, ch, ve)
                scroll.verses[(bo, int(ch), ve)] = verse
                words = Lsp.d(v, 'word')
                for wo in words:
                    print(wo)
                    word_processor = SPWordProcessor(wo)
                    sp_word_object = word_processor.create_word()
                    print(sp_word_object)
                    scroll.verses[(bo, int(ch), ve)].words.append(sp_word_object)




