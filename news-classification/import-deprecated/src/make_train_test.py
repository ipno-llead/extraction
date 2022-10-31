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
    parser.add_argument("--merged", default="output/merged.parquet")
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


def initial_asserts(merged):
    return 1

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
def prep_pos_train_test(df, train_perc=0.80, test_perc=0.20):
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
    logging.info(pretty_str('train_idx are disjoint:', set(pos_train_idx).isdisjoint(set(neg_train_idx))))
    logging.info(pretty_str('train_idx intersect:', len(set(pos_train_idx).intersection(set(neg_train_idx)))))
    train_idx = pos_train_idx + neg_train_idx
    copy['train'] = [1 if val in train_idx else 0 for val in copy.article_id.values]
    logging.info(pretty_str('train articles lost:', copy.loc[(copy.article_id.isin(train_idx)) & (copy.train == 0)].article_id.values))
    # test
    logging.info(pretty_str('test_idx are disjoint:', set(pos_test_idx).isdisjoint(set(neg_test_idx))))
    test_idx = pos_test_idx + neg_test_idx
    copy['test'] = [1 if val in test_idx else 0 for val in copy.article_id.values]
    logging.info(pretty_str('test articles lost:', copy.loc[(copy.article_id.isin(test_idx)) & (copy.test == 0)].article_id.values))
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


def make_final_logs(train_df, test_df):
    logging.info('I/O id summary')
    logging.info('=======================================================================')
    return 1


# main
if __name__ == '__main__':

    # setup logging
    get_logging("output/make-train-test.log")

    # arg handling
    # newsarticle: initial dataset
    #    - has all the data related to the article as it was pulled into feed
    # matchedsentence: initial keyword filter
    #    - has all the data related to every article with at least one sentence matching a keyword
    # matchedsentence_officers: manual filter (Rajiv)
    #    - has select columns linking identified officer badges and articles confirmed relevant by Rajiv
    # NOTE: If an article is not in the manual filter set, it is not relevant
    args = get_args()
    merged_f = args.merged
    output_f = args.output
    
    # load data, initial asserts
    merged = pd.read_parquet(merged_f)
    initial_asserts(merged)

    # report lost columns
    print()
    
    # make sure every article_id has a corresponding 'relevant' value
    relevant_articles = set(merged.loc[merged.relevant == 1].article_id.unique())
    irrelevant_articles = set(merged.loc[merged.relevant != 1].article_id.unique())
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
    # Per TS, starting train/test size should be roughly 500/100
    # ASSUMES initial balance of 50/50 positive/negative
    # proceed with generating training data
    all_ids = set(merged.article_id.unique())
    pos_ids = set(merged.loc[(merged.relevant == 1)].article_id.unique())
    neg_ids = set(merged.loc[(merged.kw_match == 1) & (merged.relevant == 0)].article_id.unique())
    all_kw_ids = set(merged.loc[(merged.kw_match == 1)])
    both_posneg = pos_ids.intersection(neg_ids)
    kw_diff = all_kw_ids.difference(neg_ids)
    logging.info(pretty_str('pos.intersection(neg):', both_posneg))
    logging.info(pretty_str('all_kw_ids.diff(neg):', len(kw_diff)))
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

    assert make_final_logs(train, test)
    
    # save output(s)
    train.to_parquet(args.output)
    test.to_parquet('output/test.parquet')
    logging.info("done.")
    
# done.
