class PtcPatternMaker:
    def __init__(self, data):
        self.data = data
        self.make_patterns()

    def make_patterns(self):
        self.data.pattern = [self.make_one_ptc_pattern(stem) for stem in self.data.stem]
        self.data.pattern_g_cons = [self.make_one_ptc_pattern(g_cons) for g_cons in self.data.g_cons]

    @staticmethod
    def make_one_ptc_pattern(ptc_string):
        pattern = ''.join(['C' if char not in {'J', 'W'} else 'M' for char in ptc_string])
        pattern = 'C' + pattern[1:]
        return pattern
