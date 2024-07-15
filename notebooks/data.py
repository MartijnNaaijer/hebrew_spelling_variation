import collections

class AllBooks:
    def __init__(self):
        self.data = {}
        

class Book:
    def __init__(self, manuscript, book_name, F, T, L):
        self.manuscript = manuscript
        self.book_name = book_name
        self.F = F
        self.T = T
        self.L = L
        if self.manuscript in {'MT', 'SP'}:
            self.verse_g_cons, self.word2char = self.prepare_book_data()
        else:
            self.verse_g_cons, self.word2char = self.prepare_dss_book_data()
        self.verse_text_dict = self.make_verse_text()
        
    def prepare_book_data(self):
        verse_g_cons = collections.defaultdict(list)
        word2char = collections.defaultdict(list)
    
        for book_node in self.F.otype.s('book'):
            book_name = self.T.sectionFromNode(book_node)[0]
            if book_name != self.book_name:
                continue
            words = self.L.d(book_node, 'word')
            for w in words:
                bo, ch, ve = self.T.sectionFromNode(w)
                g_cons = self.F.g_cons.v(w)
                trailer = self.F.trailer.v(w)
                if trailer:
                    trailer = ' '
                verse_g_cons[(bo, ch, ve)].append(g_cons + trailer)
                for char in g_cons:
                    word2char[(bo, ch, ve)].append(w)
        return verse_g_cons, word2char
    
    def prepare_dss_book_data(self):
        verse_g_cons = collections.defaultdict(list)
        word2char = collections.defaultdict(list)
        
        for scr in self.F.otype.s('scroll'):
            if self.T.scrollName(scr) == self.manuscript:
                words = self.L.d(scr, 'word')
                for w in words:
                    bo = self.F.book_etcbc.v(w)
                    if bo != self.book_name:
                        continue            
                    ch = self.F.chapter.v(w)
                    ve = self.F.verse.v(w)
                
                    g_cons = self.F.g_cons.v(w)
                    after = self.F.after.v(w)

                    if after is None:
                        after = ''
                    if g_cons:
                        verse_g_cons[(bo, int(ch), int(ve))].append(g_cons + after)
                        for char in g_cons:
                            word2char[(bo, int(ch), int(ve))].append(w)
        return verse_g_cons, word2char
    
    def make_verse_text(self):
        return {section : ''.join(g_conss).strip() for (section, g_conss) in self.verse_g_cons.items()}