"""
Finds the MT parallels of DSS and SP words and compares their lexemes.

The consonantal texts of a verse in two witnesses are aligned letter by letter (longest common subsequence, as the
global alignment without penalties of Biopython's pairwise2.align.globalxx). A word is paired with the word of the
other witness with which it shares the most aligned letters. Sin and shin are both written '#', because the DSS
does not distinguish them.
"""
import numpy as np

WORD_SEPARATOR = ' '


def normalize_text(g_cons):
    return g_cons.replace('C', '#').replace('F', '#')


def verse_text(words):
    """words is a list of (word_id, g_cons, ends_with_space). Returns the text of the verse and, per character,
    the id of its word (None for a space)."""
    chars, owners = [], []
    for word_id, g_cons, ends_with_space in words:
        for ch in normalize_text(g_cons):
            chars.append(ch)
            owners.append(word_id)
        if ends_with_space:
            chars.append(WORD_SEPARATOR)
            owners.append(None)
    return ''.join(chars), owners


def lcs_alignment(text1, text2):
    """Returns the pairs of indices (i, j) of aligned identical characters in a longest common subsequence."""
    n, m = len(text1), len(text2)
    if not n or not m:
        return []
    a = np.frombuffer(text1.encode('utf-32-le'), dtype=np.uint32)
    b = np.frombuffer(text2.encode('utf-32-le'), dtype=np.uint32)
    table = np.zeros((n + 1, m + 1), dtype=np.int32)
    for i in range(1, n + 1):
        prev = table[i - 1]
        diagonal = np.where(b == a[i - 1], prev[:-1] + 1, 0)
        # table[i, j] = max(table[i - 1, j], table[i, j - 1], diagonal): the second term is a running maximum.
        table[i, 1:] = np.maximum.accumulate(np.maximum(prev[1:], diagonal))

    pairs = []
    i, j = n, m
    while i > 0 and j > 0:
        if text1[i - 1] == text2[j - 1] and table[i, j] == table[i - 1, j - 1] + 1:
            pairs.append((i - 1, j - 1))
            i, j = i - 1, j - 1
        elif table[i - 1, j] >= table[i, j - 1]:
            i -= 1
        else:
            j -= 1
    return pairs[::-1]


def match_words(words1, words2):
    """Pairs each word of words1 with the word of words2 with which it shares the most aligned letters.
    Both are lists of (word_id, g_cons, ends_with_space), see verse_text. Returns a dictionary
    {word_id1: (word_id2, number of aligned letters)}; words without aligned letters are left out.
    With equal counts, the first word in words2 is taken."""
    text1, owners1 = verse_text(words1)
    text2, owners2 = verse_text(words2)
    counts = {}
    for i, j in lcs_alignment(text1, text2):
        w1, w2 = owners1[i], owners2[j]
        if w1 is not None and w2 is not None:
            counts.setdefault(w1, {})
            counts[w1][w2] = counts[w1].get(w2, 0) + 1
    order2 = {word_id: idx for idx, (word_id, _, _) in enumerate(words2)}
    return {w1: max(c.items(), key=lambda item: (item[1], -order2[item[0]])) for w1, c in counts.items()}


def strip_markers(lex):
    return lex.replace('=', '').replace('/', '').replace('[', '')


def compare_lexemes(lex, g_cons, mt_lex, mt_g_cons):
    """Classifies the lexeme of a DSS or SP word against that of its MT parallel. Only words with the same text
    as their parallel (sin and shin not distinguished) are compared:
    - different_text: the texts differ, the lexemes are not compared
    - no_lexeme: the word has no lexeme (damaged DSS words)
    - match: identical
    - homograph_marker: only the homograph marker = differs, e.g. XLM=[ and XLM[
    - pos_marker: only the markers / (noun) and [ (verb) differ, possibly with =, e.g. XCK/ and XCK[
    - different_lexeme: other differences"""
    if normalize_text(g_cons) != normalize_text(mt_g_cons):
        return 'different_text'
    if not lex:
        return 'no_lexeme'
    if lex == mt_lex:
        return 'match'
    if lex.replace('=', '') == mt_lex.replace('=', ''):
        return 'homograph_marker'
    if strip_markers(lex) == strip_markers(mt_lex):
        return 'pos_marker'
    return 'different_lexeme'
