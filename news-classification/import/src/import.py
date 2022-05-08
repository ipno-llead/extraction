# Authors:     BP
# Maintainers: BP
# Copyright:   2022, HRDAG, GPL v2 or later
# =========================================
# extraction/news-classification/import/src/import.py

# dependencies
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


def pretty_str(label, val, newline=False):
    if newline:
        return '{:50}{}{}'.format(label, val, '\n')
    return '{:50}{}'.format(label, val)


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


def format_extracted_str(list_str):
    if list_str is not None:
        clean = list_str.replace('[', '').replace(']', '').replace('"', '').lower()
        if ',' in clean:
            return str({val for val in clean.split(',')})
        return str({clean})
    return None


def prep_dfs(text_df, sen_df, true_df):
    less_text = text_df.loc[:, ['id', 'source_id', 'author', 'content']]
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


# This method builds the POSITIVE cases: keyword matched AND article relevant (per Rajiv)
def prep_pos_train_test(df, train_perc=0.80, test_perc=0.20):
    id_mask = (df.officer_id.notnull())
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
    id_mask = (df.kw_match == 1) & (df.officer_id.isnull())
    possible = df.loc[id_mask].article_id.unique().tolist()
    assert needed_train + needed_test <= len(possible)
    train_list, test_list = train_test_split(possible, test_size=needed_test, train_size=needed_train, shuffle=True)
    assert set(train_list).isdisjoint(set(test_list))
    return train_list, test_list


def remake_merged(train_df, test_df, rem_df):
    l_df = train_df.copy()
    l_df['train'] = [1 for val in range(train_df.shape[0])]
    r_df = test_df.copy()
    r_df['test'] = [1 for val in range(test_df.shape[0])]    
    train_test_df = pd.concat([l_df, r_df])
    out = pd.concat([train_test_df, rem_df])
    out.train.fillna(value=0, axis=0, inplace=True)
    out.test.fillna(value=0, axis=0, inplace=True)
    temp = out
    out['train'] = temp.train.astype(int)
    out['test'] = temp.test.astype(int)
    return out


def make_train_test_cols(df, pos_rate):
    copy = df.copy()
    # get pos/neg and train/test indice sets
    pos_train_idx, pos_test_idx = prep_pos_train_test(copy)
    neg_train_idx, neg_test_idx = prep_neg_train_test(copy, pos_rate, len(pos_train_idx), len(pos_test_idx))
    # train
    train_idx = pos_train_idx + neg_train_idx
    copy['train'] = [1 if val in train_idx else 0 for val in copy.article_id.values]
    # test
    test_idx = pos_test_idx + neg_test_idx
    copy['test'] = [1 if val in test_idx else 0 for val in copy.article_id.values]
    return copy[['article_id', 'matchedsentence_id', 'source_id', 'author', 'text', \
                'content', 'officer_id', 'extracted_keywords', 'kw_match', 'relevant', 'train', 'test']]


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


def make_train_test_df(df):
    full = df.loc[((df.train == 1) | (df.test == 1)), ['article_id', 'content', 'relevant', 'test']]
    full.drop_duplicates(subset='article_id', inplace=True)
    return full


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
    out['relevant_perc'] = round((out.relevant_count) / (out.relevant_count + out.kw_match), 3)
    return out


def make_final_logs(text_df, sen_df, true_df, train_test_df, merged):
    logging.info('I/O id summary')
    logging.info('=======================================================')
    logging.info(pretty_str('all kw_match articles in raw data:', True))      # asserted by check_asserts()
    logging.info(pretty_str('all matchedsentences in kw_match data:', True))
    logging.info(pretty_str('unique articles:', len(text_df.id.unique())))
    logging.info(pretty_str('unique articles w/ kw match:', len(sen_df.article_id.unique())))
    logging.info(pretty_str('unique matched sentences:', len(sen_df.id.unique())))
    logging.info(pretty_str('unique matched sentences relevant:', len(true_df.matchedsentence_id.unique())))
    logging.info(pretty_str('unique matched officers relevant:', len(true_df.id.unique())))
    logging.info(pretty_str('unique articles in train_test:', len(train_test_df.article_id.unique()), newline=True))
    return 1


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

    text_df = open_gz(news_text_f)
    sen_df = open_gz(news_included_f)
    true_df = open_gz(news_true_f)
    check_asserts(text_df, sen_df, true_df)
    
    less_text, less_sen, less_true = prep_dfs(text_df, sen_df, true_df)
    merged = merge_dfs(less_text, less_sen, less_true)
    # report lost columns
    print()
    logging.info('columns ignored by import')
    logging.info('=======================================================')
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
    logging.info('=======================================================')
    logging.info(pretty_str('unique relevant articles:', len(relevant_articles)))
    logging.info(pretty_str('unique irrelevant articles:', len(irrelevant_articles)))
    # check for conflicting 'relevant' values, correct if present
    logging.info(pretty_str('relevant and irrelevant disjoint:', overlap == set()))
    if overlap != set():
        logging.info(pretty_str('size of overlap:', len(overlap)))
        temp = merged
        merged = correct_relevant(temp)
        logging.info(pretty_str('amended relevant column:', True, newline=True))
    
    # Per TS, starting train/test size should be roughly 500/100
    # ASSUMES initial balance of 50/50 positive/negative
    # proceed with generating training data
    merged = make_train_test_cols(merged, pos_rate=0.5)
    train_test_df = make_train_test_df(merged)
    logging.info('train_test summary')
    logging.info('=======================================================')
    train = train_test_df.loc[train_test_df.test == 0]
    test = train_test_df.loc[train_test_df.test == 1]
    train_n = train.article_id.count()
    test_n = test.article_id.count()
    assert train_n + test_n == train_test_df.shape[0]
    train_pos = train.loc[train.relevant == 1].article_id.count()
    test_pos = test.loc[test.relevant == 1].article_id.count()
    train_neg = train_n - train_pos
    test_neg = test_n - test_pos
    logging.info(f'{train_n} datapoints available for training with balance: {train_pos}/{train_neg} (pos/neg)')
    logging.info(f'{test_n} datapoints available for testing with balance: {test_pos}/{test_neg} (pos/neg)\n')
    train_test_df.info()
    print()

    assert make_final_logs(text_df, sen_df, true_df, train_test_df, merged)
    
    # generate keyword report (source_id, author also helpful reports)
    kw_report = make_report(merged, 'extracted_keywords')
    logging.info('keyword report')
    logging.info('=======================================================')
    sorted_kw_report = kw_report[['extracted_keywords', 'relevant_perc']].sort_values(by='relevant_perc', ascending=False)
    for tup in sorted_kw_report.itertuples():
        logging.info(pretty_str(tup.extracted_keywords+':', tup.relevant_perc ))
    
    # save output(s)
    train_test_df.to_parquet('output/train-test.parquet')
    
    logging.info("done.")
    
# done.