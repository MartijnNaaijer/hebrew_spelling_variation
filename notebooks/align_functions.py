import collections

from Bio import pairwise2
from Bio.Seq import Seq

def align_verses(str_1, str_2):
    seq1 = Seq(str_1)
    seq2 = Seq(str_2)

    alignments = pairwise2.align.globalxx(seq1, seq2)

    seq1_al = (alignments[0][0]).strip(' ')
    seq2_al = (alignments[0][1]).strip(' ')

    return seq1_al, seq2_al


def make_alignments(verse_text1, verse_text2):
    alignments_dict = {}

    for section, text1 in verse_text1.items():
        try:
            text2 = verse_text2[section]
            alignment1, alignment2 = align_verses(text1, text2)
            alignments_dict[section] = (alignment1, alignment2)
        except:
            continue
    return alignments_dict


def collect_matching_words(alignments_dict, word2char1, word2char2):
    man1_man2_dict = collections.defaultdict(list)

    for section, (al1, al2) in alignments_dict.items():
        man1_idx = 0
        man2_idx = 0

        word_chars1 = word2char1[section]
        word_chars2 = word2char2[section]
        for char1, char2 in zip(al1, al2):
            if char1 not in {' ', '-'}:
                man1_word = word_chars1[man1_idx]
                man1_idx += 1

            if char2 not in {' ', '-'}:
                man2_word = word_chars2[man2_idx]
                man2_idx += 1

            if char1 not in {' ', '-'} and char2 not in {' ', '-'}:
                man1_man2_dict[man1_word].append(man2_word)

    return man1_man2_dict


def most_frequent(List):
    return max(set(List), key = List.count)