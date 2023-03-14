class UselessRootsInfAbsRemover:
    def __init__(self, data):
        self.data = data
        self.data_no_hollow_roots = self.remove_hollow_roots()
        self.no_ayin_ayin_data = self.remove_ayin_ayin_verbs()
        self.no_lamed_he = self.remove_lamed_he_verbs()

    def remove_hollow_roots(self):
        data_copy = self.data.copy()
        return data_copy[~data_copy.lex.str[1].isin(['W', 'J'])]

    def remove_ayin_ayin_verbs(self):
        """Remove ayin ayin verbs where last consonant has dropped"""
        data_no_hollow_copy = self.data_no_hollow_roots.copy()
        return data_no_hollow_copy[~((data_no_hollow_copy.lex.str[1] == data_no_hollow_copy.lex.str[2]) &
                                     (data_no_hollow_copy.stem.str.len == 2))]

    def remove_lamed_he_verbs(self):
        no_ayin_ayin_copy = self.no_ayin_ayin_data.copy()
        return no_ayin_ayin_copy[no_ayin_ayin_copy.lex.str[2] != 'H']