def make_matching_word_dict(book_name, all_books):

    all_match_dicts = {}

    matching_book = book_name
    matching_manuscripts = [scr for scr, bo in all_books.data.keys() if bo == matching_book]

    for man1 in matching_manuscripts:
        for man2 in matching_manuscripts:
            if man1 != man2:
            
                man1_verse_texts = all_books.data[(man1, matching_book)].verse_text_dict
                man2_verse_texts = all_books.data[(man2, matching_book)].verse_text_dict

                alignments_dict = make_alignments(man1_verse_texts, man2_verse_texts)
    
                man1_word2char = all_books.data[(man1, matching_book)].word2char
                man2_word2char = all_books.data[(man2, matching_book)].word2char
 
                matching_words_dict = collect_matching_words(alignments_dict, man1_word2char, man2_word2char)

                matches = {}
                for man1_word, man2_list in matching_words_dict.items():
                    man2_word = most_frequent(man2_list)
                    matches[man1_word] = man2_word
                all_match_dicts[((man1, matching_book), (man2, matching_book))] = matches
                
    return all_match_dicts, matching_manuscripts


def collect_matching_cases(matching_manuscripts, matching_book, dat):

    all_mater_datasets = {}

    for man in matching_manuscripts:
        mater_data = dat[(dat.book == matching_book) & (dat.scroll == man)]
        all_mater_datasets[(man, matching_book)] = mater_data
        
    return all_mater_datasets


def collect_mater_data(matching_manuscripts, all_match_dicts, all_mater_datasets, matching_book):

    manuscript_mater_match = collections.defaultdict(list)
    manuscripts = set()

    for idx, man in enumerate(matching_manuscripts):
        for idx2, man2 in enumerate(matching_manuscripts):
            if idx < idx2:
            
                matching_ids = all_match_dicts[((man, matching_book), (man2, matching_book))]
                man_data = all_mater_datasets[(man, matching_book)]
                man2_data = all_mater_datasets[(man2, matching_book)]
                for _, row in man_data.iterrows():
                
                    tf_id = row.tf_id
                    lex, typ, has_vl = row.lex, row.type, row.has_vowel_letter
                    g_cons1 = row.g_cons
                    section = (row.book, row.chapter, row.verse)
                    if man == 'SP':
                        tf_id = tf_id - 100000

                    matching_tf_id = matching_ids.get(tf_id, None)
                
                    if not matching_tf_id:
                        continue
                    
                    if man2 == 'SP':
                        matching_tf_id = matching_tf_id + 100000
                
                    man2_row = man2_data[(man2_data.tf_id == matching_tf_id) & (man2_data.lex == lex) & (man2_data.type == typ)]
                    
                    if not man2_row.shape[0]:
                        continue
                    has_vl2 = man2_row.has_vowel_letter.iloc[0]
                    g_cons2 = man2_row.g_cons.iloc[0]
                 
                    mater_data = MaterData(man, man2, section, lex, has_vl, has_vl2, tf_id, matching_tf_id, g_cons1, g_cons2)
                
                    manuscript_mater_match[man].append(mater_data)
                    manuscripts.add(man)
                    manuscripts.add(man2)
                    
    return manuscript_mater_match, manuscripts


def register_similarities_with_mt(manuscripts, mt_ids, manuscript_mater_match):

    mater_value_dict = {0: -1,
                    1: 1}

    mater_match_array = np.zeros((len(manuscripts), len(mt_ids)))

    for dat_object in manuscript_mater_match['MT']:
        
        other_man = dat_object.man2
        mt_tfid = dat_object.tf_id1
        other_man_tfid = dat_object.tf_id2
    
        mt_mater = dat_object.mater_val1
        other_man_mater = dat_object.mater_val2
    
        mt_idx = man2idx['MT']
        other_man_idx = man2idx[other_man]
    
        mt_mater_value = mater_value_dict[mt_mater]
        other_man_mater_value = mater_value_dict[other_man_mater]
    
        mt_tf_id = mt_tf2idx[mt_tfid]
    
        mater_match_array[mt_idx, mt_tf_id] = mt_mater_value
        mater_match_array[other_man_idx, mt_tf_id] = other_man_mater_value
        
    return mater_match_array


def get_parallels(manuscript_mater_match, match_dict):
    for scroll in manuscript_mater_match.keys():
        for dat_object in manuscript_mater_match[scroll]:
            man1 = dat_object.man1
            man2 = dat_object.man2
            if man1 == 'MT' or man2 == 'MT':
            
                match_dict[dat_object.tf_id2] = dat_object.tf_id1
                match_dict[dat_object.tf_id1] = dat_object.tf_id2
        
    return match_dict


def count_parallel_cases(mater_match_array):

    mater_arr = np.zeros((2, mater_match_array.shape[1]))

    for col_idx in range(mater_match_array.shape[1]):
        col = mater_match_array[:, col_idx]
        col_counts = collections.Counter(col)
        with_vowel_count = col_counts.get(1, 0)
        without_vowel_count = col_counts.get(-1, 0)
        mater_arr[0, col_idx] = with_vowel_count
        mater_arr[1, col_idx] = without_vowel_count
        
    return mater_arr


