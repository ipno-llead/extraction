# Authors:     BP
# Maintainers: BP
# Copyright:   2022, HRDAG, GPL v2 or later
# =========================================
# extraction/news-classification/import/src/import.py

# dependencies
import yaml
import argparse
import logging
from numpy import nan as nan
from math import ceil
import pandas as pd
from sklearn.model_selection import train_test_split

# support methods
def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--included")
    parser.add_argument("--true")
    parser.add_argument("--text")
    parser.add_argument("--output")
    return parser.parse_args()


def get_logging(logname):
        logging.basicConfig(level=logging.DEBUG,
                            format='%(asctime)s %(levelname)s %(message)s',
                            handlers=[logging.FileHandler(logname),
                            logging.StreamHandler()])


def open_gz(f):
    return pd.read_csv(f, compression='gzip')


def read_yaml(filename):
    assert open(filename)
    with open(filename, 'r') as f:
        data = yaml.load(f, Loader=yaml.SafeLoader)
    return data


def pretty_str(label, a, b=False, newline=False):
    if newline:
        if not b:
            return '{:50}{}{}'.format(label, a, '\n')
        else:
            return '{:50}{:10}{:10}{}'.format(label, a, b, '\n')
    if b:
        return '{:50}{:10}{:10}'.format(label, a, b)
    return '{:50}{}'.format(label, a)


def check_asserts(text_df, sen_df, true_df):
    assert text_df.shape == (29707, 12)
    assert sen_df.shape == (10470, 7)
    assert true_df.shape == (735, 3)
    assert all(text_df.columns == ['created_at', 'link', 'guid', 'source_id', \
                                   'updated_at', 'content', 'published_date', 'id', \
                                   'title', 'is_processed', 'author', 'url'])
    assert all(sen_df.columns == ['id', 'created_at', 'updated_at', 'article_id', 
                                   'extracted_keywords', 'text', 'title'])
    assert all(true_df.columns == ['id', 'matchedsentence_id', 'officer_id'])
    most = set(text_df.id.unique())
    mid = set(sen_df.id.unique())
    least = set(true_df.id.unique())
    assert len(least) < len(mid) < len(most)
    assert len(most.intersection(mid)) == 9891
    assert all(true_df.id == true_df.officer_id)   # what does it mean that this is true? will it always?
    pairs = set()
    for tup in true_df.itertuples():
        pairs.add((tup.id, tup.matchedsentence_id))
    assert len(pairs) == true_df.shape[0]
    articles = text_df.id.unique()
    matched = sen_df.article_id.unique()
    assert len(matched) < len(articles)
    assert len(articles) == 29707
    assert len(matched) == 4323
    for match in matched:
        assert match in articles
    matched_sen = sen_df.id.unique()
    true_match_sen = true_df.matchedsentence_id.unique()
    true_match_off = true_df.id.unique()
    assert len(true_match_sen) < len(matched_sen)
    assert len(matched_sen) == 10470
    assert len(true_match_sen) == 479
    for match in true_match_sen:
        assert match in matched_sen


def labels_from_audit(manual_dict):
    return {k: (1 if v == 1 else 0) for k,v in manual_dict.items()}

        
def format_extracted_str(list_str):
    if list_str is not None:
        clean = list_str.replace('[', '').replace(']', '').replace('"', '').lower()
        if ',' in clean:
            return str({val for val in clean.split(',')})
        return str({clean})
    return None


def prep_dfs(text_df, sen_df, true_df):
    less_text = text_df.loc[:, ['id', 'source_id', 'author', 'title', 'content']]
    temp = less_text
    less_text = temp.rename(columns={'id':'article_id'})
    less_sen = sen_df.loc[:, ['id', 'article_id', 'text']]
    temp = less_sen
    less_sen = temp.rename(columns={'id':'matchedsentence_id'})
    less_sen['extracted_keywords'] = sen_df.extracted_keywords.apply(format_extracted_str)
    less_sen['kw_match'] = [1 for val in range(less_sen.shape[0])]
    less_true = true_df.loc[:, ['officer_id', 'matchedsentence_id']]
    less_true['relevant'] = [1 for val in range(less_true.shape[0])]
    return less_text, less_sen, less_true


def merge_dfs(less_text, less_sen, less_true):
    less_text = less_text.set_index('article_id')
    less_sen = less_sen.set_index('article_id')
    out = less_text.join(less_sen, on='article_id', how='outer').reset_index().set_index('matchedsentence_id')
    temp = less_true
    less_true = temp.set_index('matchedsentence_id')
    out = out.join(less_true, on='matchedsentence_id', how='outer')
    out = out.reset_index()
    out.kw_match.fillna(value=0, axis=0, inplace=True)
    out.relevant.fillna(value=0, axis=0, inplace=True)
    temp = out
    out['kw_match'] = temp.kw_match.astype(int)
    out['relevant'] = temp.relevant.astype(int)
    return out


# this method is called when relevant_articles and irrelevant_articles are not disjoint sets
# resolves conflict by upgrading all occurances of an article_id in relevant_articles to relevant
# ie. a sentence from an article is matched to an officer and appears in matchedsentence_officers data
#     a different sentence from same article is not matched and deemed irrelevant, appears in matchedsentence data
#     conflict occurs when datasets merged
def correct_relevant(df):
    copy = df.copy()
    relevant = copy.loc[copy.relevant == 1].article_id.unique().tolist()
    copy.loc[copy.article_id.isin(relevant), 'relevant'] = 1
    return copy


# This method builds the POSITIVE cases: keyword matched AND article relevant (per Rajiv)
# TEMPORARY: uses 99% of pos cases for train (when relabeling is done, this should be changed back to 80/20)
def prep_pos_train_test(df, train_perc=0.99, test_perc=0.01):
    id_mask = (df.relevant == 1)
    possible = df.loc[id_mask].article_id.unique().tolist()
    train_list, test_list = train_test_split(possible, test_size=test_perc, train_size=train_perc, shuffle=True)
    assert set(train_list).isdisjoint(set(test_list))
    return train_list, test_list


# This method builds the NEGATIVE cases: keyword matched but not relevant
def prep_neg_train_test(df, pos_rate, curr_train_n, curr_test_n):
    assert 0 < pos_rate <= 0.5
    target_train = ceil(curr_train_n/pos_rate)
    target_test = ceil(curr_test_n/pos_rate)
    needed_train = target_train - curr_train_n
    needed_test = target_test - curr_test_n
    id_mask = (df.kw_match == 1) & (df.relevant == 0) 
    possible = df.loc[id_mask].article_id.unique().tolist()
    assert needed_train + needed_test <= len(possible)
    train_list, test_list = train_test_split(possible, test_size=needed_test, train_size=needed_train, shuffle=True)
    assert set(train_list).isdisjoint(set(test_list))
    return train_list, test_list


def make_train_test_cols(df, pos_rate):
    copy = df.copy()
    # get pos/neg and train/test indice sets
    pos_train_idx, pos_test_idx = prep_pos_train_test(copy)
    neg_train_idx, neg_test_idx = prep_neg_train_test(copy, pos_rate, len(pos_train_idx), len(pos_test_idx))
    # train
    logging.info('train_idx are disjoint: {}'.format(set(pos_train_idx).isdisjoint(set(neg_train_idx))))
    logging.info('train_idx intersect: {}'.format(len(set(pos_train_idx).intersection(set(neg_train_idx)))))
    train_idx = pos_train_idx + neg_train_idx
    logging.info('train size pre col: {}'.format(len(train_idx)))
    logging.info('pos train size pre col: {}'.format(len(copy.loc[(copy.article_id.isin(train_idx)) & (copy.relevant == 1)].article_id.unique())))
    copy['train'] = [1 if val in train_idx else 0 for val in copy.article_id.values]
    logging.info('train size post col: {}'.format(len(copy.loc[copy.train == 1].article_id.unique())))
    logging.info('pos train size post col: {}'.format(len(copy.loc[(copy.train == 1) & (copy.relevant == 1)].article_id.unique())))
    logging.info('train articles lost: {}'.format(copy.loc[(copy.article_id.isin(train_idx)) & (copy.train == 0)].article_id.values))
    # test
    logging.info('test_idx are disjoint: {}'.format(set(pos_test_idx).isdisjoint(set(neg_test_idx))))
    test_idx = pos_test_idx + neg_test_idx
    logging.info('test size pre col: {}'.format(len(test_idx)))
    copy['test'] = [1 if val in test_idx else 0 for val in copy.article_id.values]
    logging.info('test size post col: {}'.format(len(copy.loc[copy.test == 1].article_id.unique())))
    logging.info('pos test size post col: {}'.format(len(copy.loc[(copy.test == 1) & (copy.relevant == 1)].article_id.unique())))
    logging.info('test articles lost: {}'.format(copy.loc[(copy.article_id.isin(test_idx)) & (copy.test == 0)].article_id.values))
    return copy[['article_id', 'matchedsentence_id', 'source_id', 'author', 'title', 'text', \
                'content', 'officer_id', 'extracted_keywords', 'kw_match', 'relevant', 'train', 'test']]


def make_train_test_df(df):
    full = df.loc[((df.train == 1) | (df.test == 1)), ['article_id', 'content', 'relevant', 'test']]
    full.drop_duplicates(subset='article_id', inplace=True)
    return full


# Since out.kw_match = out.relevant_count + out.irrelevant_count, and relevant can't be true without kw_match,
# (out.relevant_count) / (out.kw_match) should be the proportion of relevant samples given kw_match for col value
def make_report(df, col):
    kw_match_vc = df.loc[df.kw_match == 1][col].value_counts().to_dict()
    relevant_vc = df.loc[df.relevant == 1][col].value_counts().to_dict()
    irrelevant_match_vc = df.loc[(df.kw_match == 1) & (df.relevant != 1)][col].value_counts().to_dict()
    kws = set(list(kw_match_vc.keys()) + list(relevant_vc.keys()) + list(irrelevant_match_vc.keys()))
    out_data = {kw:{} for kw in kws}
    for kw in kws:
        if kw in kw_match_vc:
            out_data[kw]['kw_match'] = kw_match_vc[kw]
        else:
            out_data[kw]['kw_match'] = 0
        if kw in relevant_vc:
            out_data[kw]['relevant_count'] = relevant_vc[kw]
        else:
            out_data[kw]['relevant_count'] = 0
    out = pd.DataFrame.from_dict(out_data).T.reset_index().rename(columns={'index':col})
    out['relevant_perc'] = round((out.relevant_count) / (out.kw_match), 3)
    return out


def make_final_logs(text_df, sen_df, true_df, train_test_df, merged):
    logging.info('I/O id summary')
    logging.info('=======================================================================')
    logging.info(pretty_str('all kw_match articles in raw data:', True))      # asserted by check_asserts()
    logging.info(pretty_str('all matchedsentences in kw_match data:', True))
    logging.info(pretty_str('unique articles:', len(text_df.id.unique())))
    logging.info(pretty_str('unique articles w/ kw match:', len(sen_df.article_id.unique())))
    logging.info(pretty_str('unique matched sentences:', len(sen_df.id.unique())))
    logging.info(pretty_str('unique matched sentences relevant:', len(true_df.matchedsentence_id.unique())))
    logging.info(pretty_str('unique matched officers relevant:', len(true_df.id.unique())))
    logging.info(pretty_str('unique articles in train_test:', len(train_test_df.article_id.unique()), newline=True))
    return 1


def patch_relevant(df, hand_dict):
    assert len(hand_dict) > 0
    copy = df.copy()
    count = 0
    for article_id, new_label in hand_dict.items():
        copy.loc[copy.article_id == article_id, 'relevant'] = new_label
        count += 1
    assert count == len(hand_dict)
    return copy


# main
if __name__ == '__main__':

    # setup logging
    get_logging("output/import.log")

    # arg handling
    # newsarticle: initial dataset
    #    - has all the data related to the article as it was pulled into feed
    # matchedsentence: initial keyword filter
    #    - has all the data related to every article with at least one sentence matching a keyword
    # matchedsentence_officers: manual filter (Rajiv)
    #    - has select columns linking identified officer badges and articles confirmed relevant by Rajiv
    # NOTE: If an article is not in the manual filter set, it is not relevant
    args = get_args()
    news_included_f = args.included
    news_true_f = args.true
    news_text_f = args.text
    output_f = args.output
    # adding support for reading manually re-labeled relevant data
    hand_f = 'hand/review_random.yml'
    hand_dict = read_yaml(hand_f)
    hand_labels = labels_from_audit(hand_dict)
    
    text_df = open_gz(news_text_f)
    sen_df = open_gz(news_included_f)
    true_df = open_gz(news_true_f)
    check_asserts(text_df, sen_df, true_df)
    
    less_text, less_sen, less_true = prep_dfs(text_df, sen_df, true_df)
    merged = merge_dfs(less_text, less_sen, less_true)
    # report lost columns
    print()
    logging.info('columns ignored by import')
    logging.info('=======================================================================')
    all_cols = set(text_df.columns.tolist() + sen_df.columns.tolist() + true_df.columns.tolist())
    kept = set(merged.columns)
    not_kept = all_cols.difference(kept)
    not_kept.remove('id')
    logging.info(str(not_kept)+'\n')
    
    # make sure every article_id has a corresponding 'relevant' value
    all_ids = set(merged.article_id.unique())
    relevant_articles = set(merged.loc[(merged.relevant == 1)].article_id.unique())
    irrelevant_articles = set(merged.loc[(merged.relevant == 0)].article_id.unique())
    rel_vals = relevant_articles.union(irrelevant_articles)
    assert all_ids.difference(rel_vals) == set()
    overlap = relevant_articles.intersection(irrelevant_articles)
    logging.info('relevant && irrelevant articles check')
    logging.info('=======================================================================')
    logging.info(pretty_str('unique relevant articles:', len(relevant_articles)))
    logging.info(pretty_str('unique irrelevant articles:', len(irrelevant_articles)))
    # check for conflicting 'relevant' values, correct if present
    logging.info(pretty_str('relevant and irrelevant disjoint:', overlap == set()))
    if overlap != set():
        logging.info(pretty_str('size of overlap:', len(overlap)))
        merged = correct_relevant(merged)
        logging.info(pretty_str('amended relevant column:', True, newline=True))
    logging.info(pretty_str('updated labels exist:', len(hand_labels) > 0))
    if len(hand_labels) > 0:
        logging.info(pretty_str('count to update:', len(hand_labels)))
        merged = patch_relevant(merged, hand_labels)
        logging.info(pretty_str('relevant labels updated:', True, newline=True))
        logging.info(pretty_str('unique relevant articles:', len(set(merged.loc[(merged.relevant == 1)].article_id.unique()))))
    # Per TS, starting train/test size should be roughly 500/100
    # ASSUMES initial balance of 50/50 positive/negative
    # proceed with generating training data
    all_ids = set(merged.article_id.unique())
    pos_ids = set(merged.loc[(merged.relevant == 1)].article_id.unique())
    neg_ids = set(merged.loc[(merged.kw_match == 1) & (merged.relevant == 0)].article_id.unique())
    all_kw_ids = set(merged.loc[(merged.kw_match == 1)])
    both_posneg = pos_ids.intersection(neg_ids)
    kw_diff = all_kw_ids.difference(neg_ids)
    logging.info('pos.intersection(neg): {}'.format(both_posneg))
    logging.info('all_kw_ids.diff(neg): {}'.format(len(kw_diff)))
    merged = make_train_test_cols(merged, pos_rate=0.5)
    train_test_df = make_train_test_df(merged)
    logging.info('train, test summary')
    logging.info('=======================================================================')
    train = train_test_df.loc[train_test_df.test == 0, ['article_id', 'content', 'relevant']]
    test = train_test_df.loc[train_test_df.test == 1, ['article_id', 'content', 'relevant']]
    train_n = train.article_id.count()
    test_n = test.article_id.count()
    assert train_n + test_n == train_test_df.shape[0]
    train_pos = train.loc[train.relevant == 1].article_id.count()
    test_pos = test.loc[test.relevant == 1].article_id.count()
    train_neg = train_n - train_pos
    test_neg = test_n - test_pos
    logging.info(f'{train_n} datapoints available for training with balance: {train_pos}/{train_neg} (pos/neg)')
    logging.info(f'{test_n} datapoints available for testing with balance: {test_pos}/{test_neg} (pos/neg)\n')
    print('train info')
    print('=======================================================================')
    train.info()
    print('\ntest info')
    print('=======================================================================')
    test.info()
    print()

    # writing a subset of merged to use as pre-training data
    temp = merged.loc[:, ['article_id', 'title', 'content']].drop_duplicates(subset='article_id')
    assert len(temp.article_id.unique()) == temp.shape[0]
    news = temp.sample(temp.shape[0]).reset_index(drop=True)
    
    assert make_final_logs(text_df, sen_df, true_df, train_test_df, merged)
    
    # generate keyword report (source_id, author also helpful reports)
    kw_report = make_report(merged, 'extracted_keywords')
    logging.info('keyword report')
    logging.info('=======================================================================')
    logging.info('{:50}{:15}{:10}'.format('extracted_keywords', 'relevant_perc', 'kw_match'))
    sorted_kw_report = kw_report[['extracted_keywords', 'relevant_perc', 'kw_match']].sort_values(by='relevant_perc', ascending=False)
    for tup in sorted_kw_report.itertuples():
        logging.info(pretty_str(tup.extracted_keywords+':', tup.relevant_perc, b=tup.kw_match))
    
    # save output(s)
    train.to_parquet('output/train.parquet')
    test.to_parquet('output/test.parquet')
    news.to_parquet(output_f)
    merged.to_parquet('output/merged.parquet')
    logging.info("done.")
    
# done.
