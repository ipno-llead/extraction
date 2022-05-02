# Authors:     BP
# Maintainers: BP
# Copyright:   2022, HRDAG, GPL v2 or later
# =========================================
# extraction/news-classification/import/src/import.py

# dependencies
import argparse
import logging
from numpy import nan as nan
import pandas as pd
from sklearn.model_selection import train_test_split

# support methods
def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--included")    #'input/news_articles_matchedsentence.csv.gz'
    parser.add_argument("--true")        #'input/news_articles_matchedsentence_officers.csv.gz'
    parser.add_argument("--text")        #'input/news_articles_newsarticle.csv.gz'
    parser.add_argument("--output")
    return parser.parse_args()


def get_logging(logname):
        logging.basicConfig(level=logging.DEBUG,
                            format='%(asctime)s %(levelname)s %(message)s',
                            handlers=[logging.FileHandler(logname),
                            logging.StreamHandler()])


def open_gz(f):
    return pd.read_csv(f, compression='gzip')


def pretty_print(label, val, newline=False):
    print('{:50}{}'.format(label, val))
    if newline:
        print()


def check_asserts(text_df, sen_df, true_df):
    # asserts first
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


def prep_dfs(text_df, sen_df, true_df):
    less_text = text_df.loc[:, ['id', 'source_id', 'author', 'content']]
    temp = less_text
    less_text = temp.rename(columns={'id':'article_id'})
    less_sen = sen_df.loc[:, ['id', 'article_id', 'extracted_keywords']]
    temp = less_sen
    less_sen = temp.rename(columns={'id':'matchedsentence_id'})
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


def invert_bool_list(aList):
    mask = [1 if val == 0 else 0 for val in aList]
    return pd.array(mask, dtype="boolean")


# Per TS, starting train/test size should be 500/100
# ASSUMPTION: A 50/50 POS/NEG balance for model is reasonable starting point
# This method builds the POSITIVE cases: keyword matched AND article relevant (per Rajiv)
def prep_pos_train_test(merged, train_n=250, test_n=50):
    id_mask = (merged.officer_id.notnull())
    possible = merged.loc[id_mask].officer_id.unique().tolist()
    train_list, test_list = train_test_split(possible, test_size=test_n, train_size=train_n, shuffle=True)
    assert set(train_list).isdisjoint(set(test_list))
    return train_list, test_list


# This method builds the NEGATIVE cases: keyword matched but not relevant
def prep_neg_train_test(rem_df, train_n=250, test_n=50):
    id_mask = (rem_df.kw_match == 1) & (rem_df.officer_id.isnull())
    possible = rem_df.loc[id_mask].matchedsentence_id.unique().tolist()
    train_list, test_list = train_test_split(possible, test_size=test_n, train_size=train_n, shuffle=True)
    assert set(train_list).isdisjoint(set(test_list))
    return train_list, test_list


def get_train_test_dfs(merged):
    pos_train_idx, pos_test_idx = prep_pos_train_test(merged)
    pos_train_df = merged.loc[merged.officer_id.isin(pos_train_idx)]
    pos_test_df = merged.loc[merged.officer_id.isin(pos_test_idx)]
    # combine train and test indices
    # use combined indices as mask, then invert the mask so T->F, F->T
    # use inverted mask to get remainder data that is not in either train or test sets
    pos_combined = pos_train_idx + pos_test_idx
    assert invert_bool_list([1,1,1,0,0,0]) == [0,0,0,1,1,1]
    mask_to_inv = (merged.officer_id.isin(pos_combined))
    pos_inv_mask = invert_bool_list(mask_to_inv)
    initial_rem_df = merged.loc[pos_inv_mask]
    assert len(pos_train_df.officer_id.unique()) == 250
    assert len(pos_test_df.officer_id.unique()) == 50
    # use remainder data to pad train and test sets with negative cases
    neg_train_idx, neg_test_idx = prep_neg_train_test(initial_rem_df)
    neg_train_df = initial_rem_df.loc[initial_rem_df.matchedsentence_id.isin(neg_train_idx)]
    neg_test_df = initial_rem_df.loc[initial_rem_df.matchedsentence_id.isin(neg_test_idx)]
    neg_train_idx, neg_test_idx = prep_neg_train_test(initial_rem_df)
    neg_combined = neg_train_idx + neg_test_idx
    mask_to_inv = (merged.matchedsentence_id.isin(neg_combined) | merged.officer_id.isin(pos_combined))
    inv_mask = invert_bool_list(mask_to_inv)
    final_rem_df = merged.loc[inv_mask]
    train_df = pd.concat([pos_train_df, neg_train_df])
    test_df = pd.concat([pos_test_df, neg_test_df])
    return train_df, test_df, final_rem_df


def remake_merged(train_df, test_df, rem_df):
    train_test_df = pd.concat([train_df, test_df])
    train_test_df['train_test'] = [1 for val in range(train_test_df.shape[0])]
    temp = rem_df.copy()
    temp['train_test'] = [0 for val in range(temp.shape[0])]
    return pd.concat([train_test_df, temp])


def make_source_reports(train_df, test_df, rem_df):
    train_vc = train_df.source_id.value_counts().to_dict()
    test_vc = test_df.source_id.value_counts().to_dict()
    rem_vc = rem_df.source_id.value_counts().to_dict()
    sources = set(list(train_vc.keys()) + list(test_vc.keys()) + list(rem_vc.keys()))
    out_data = {source:{} for source in sources}
    for source in sources:
        if source in train_vc:
            out_data[source]['train_df'] = train_vc[source]
        else:
            out_data[source]['train_df'] = nan
        if source in test_vc:
            out_data[source]['test_df'] = test_vc[source]
        else:
            out_data[source]['test_df'] = nan
        if source in rem_vc:
            out_data[source]['rem_df'] = rem_vc[source]
        else:
            out_data[source]['rem_df'] = nan
    return pd.DataFrame.from_dict(out_data).T.reset_index().rename(columns={'index':'source_id'})


def make_author_reports(train_df, test_df, rem_df):
    train_vc = train_df.author.value_counts().to_dict()
    test_vc = test_df.author.value_counts().to_dict()
    rem_vc = rem_df.author.value_counts().to_dict()
    authors = set(list(train_vc.keys()) + list(test_vc.keys()) + list(rem_vc.keys()))
    out_data = {author:{} for author in authors}
    for author in authors:
        if author in train_vc:
            out_data[author]['train_df'] = train_vc[author]
        else:
            out_data[author]['train_df'] = nan
        if author in test_vc:
            out_data[author]['test_df'] = test_vc[author]
        else:
            out_data[author]['test_df'] = nan
        if author in rem_vc:
            out_data[author]['rem_df'] = rem_vc[author]
        else:
            out_data[author]['rem_df'] = nan
    return pd.DataFrame.from_dict(out_data).T.reset_index().rename(columns={'index':'author'})


def make_kw_reports(train_df, test_df, rem_df):
    train_vc = train_df.extracted_keywords.value_counts().to_dict()
    test_vc = test_df.extracted_keywords.value_counts().to_dict()
    rem_vc = rem_df.extracted_keywords.value_counts().to_dict()
    kws = set(list(train_vc.keys()) + list(test_vc.keys()) + list(rem_vc.keys()))
    out_data = {kw:{} for kw in kws}
    for kw in kws:
        if kw in train_vc:
            out_data[kw]['train_df'] = train_vc[kw]
        else:
            out_data[kw]['train_df'] = nan
        if kw in test_vc:
            out_data[kw]['test_df'] = test_vc[kw]
        else:
            out_data[kw]['test_df'] = nan
        if kw in rem_vc:
            out_data[kw]['rem_df'] = rem_vc[kw]
        else:
            out_data[kw]['rem_df'] = nan
    return pd.DataFrame.from_dict(out_data).T.reset_index().rename(columns={'index':'extracted_keywords'})


def make_final_logs(text_df, sen_df, true_df, train_df, test_df, rem_df, news_df, log=True):
    if not log:
        #reporting/logging second
        print('                overview of I/O')
        print('=======================================================')
        print('I/O shape')
        print('---------')
        pretty_print('raw article data:', str(text_df.shape))
        pretty_print('matched kw data:', str(sen_df.shape))
        pretty_print('relevant sentence/officer data:', str(true_df.shape))
        pretty_print('train data:', str(train_df.shape))
        pretty_print('test data:', str(test_df.shape))
        pretty_print('remainder data:', str(rem_df.shape))
        pretty_print('full data:', str(news_df.shape))
        print()
        print('I/O columns')
        print('-----------')
        print('raw data cols:\n', str(text_df.columns.tolist()))
        print('kw data cols:\n', str(sen_df.columns.tolist()))
        print('relevant data cols:\n', str(true_df.columns.tolist()))
        print('train cols:\n', str(train_df.columns.tolist()))
        print('test cols:\n', str(test_df.columns.tolist()))
        print('remainder cols:\n', str(rem_df.columns.tolist()))
        print('full data cols:\n', str(news_df.columns.tolist()))
        print()
        print('I/O id summary')
        print('--------------')
        pretty_print('all kw_match articles in raw data:', True)      # asserted by check_asserts()
        pretty_print('all matchedsentences in kw_match data:', True)
        pretty_print('unique articles:', len(text_df.id.unique()))
        pretty_print('unique articles w/ kw match:', len(sen_df.article_id.unique()))
        pretty_print('unique matched sentences:', len(sen_df.id.unique()))
        pretty_print('unique matched sentences relevant:', len(true_df.matchedsentence_id.unique()))
        pretty_print('unique matched officers relevant:', len(true_df.id.unique()))
        print()
    else:
        logging.info('                overview of I/O')
        logging.info('=======================================================')
        logging.info('I/O shape')
        logging.info('---------')
        logging.info('raw article data:', str(text_df.shape))
        logging.info('matched kw data:', str(sen_df.shape))
        logging.info('relevant sentence/officer data:', str(true_df.shape))
        logging.info('train data:', str(train_df.shape))
        logging.info('test data:', str(test_df.shape))
        logging.info('remainder data:', str(news_df.shape))
        logging.info('full data:', str(news_df.shape))
        logging.info()
        logging.info('I/O columns')
        logging.info('-----------')
        logging.info('raw data cols:', str(text_df.columns.tolist()))
        logging.info('kw data cols:', str(sen_df.columns.tolist()))
        logging.info('relevant data cols:', str(true_df.columns.tolist()))
        logging.info('train cols:', str(train_df.columns.tolist()))
        logging.info('test cols:', str(test_df.columns.tolist()))
        logging.info('remainder cols:', str(rem_df.columns.tolist()))
        logging.info('full data cols:', str(news_df.columns.tolist()))
        logging.info()
        logging.info('I/O id summary')
        logging.info('--------------')
        logging.info('all kw_match articles in raw data:', True)      # asserted by check_asserts()
        logging.info('all matchedsentences in kw_match data:', True)
        logging.info('unique articles:', len(text_df.id.unique()))
        logging.info('unique articles w/ kw match:', len(sen_df.article_id.unique()))
        logging.info('unique matched sentences:', len(sen_df.id.unique()))
        logging.info('unique matched sentences relevant:', len(true_df.matchedsentence_id.unique()))
        logging.info('unique matched officers relevant:', len(true_df.id.unique()))
        logging.info()
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
    train_df, test_df, rem_df = get_train_test_dfs(merged)
    src_report = make_source_reports(train_df, test_df, rem_df)
    author_report = make_author_reports(train_df, test_df, rem_df)
    kw_report = make_kw_reports(train_df, test_df, rem_df)
    news_df = remake_merged(train_df, test_df, rem_df)
    less_train = train_df.loc[:, ['article_id', 'content', 'relevant']]
    less_test = test_df.loc[:, ['article_id', 'content', 'relevant']]
                
    # save outputs
    news_df.to_parquet(output_f)
    less_train.to_parquet('output/train.parquet')
    less_test.to_parquet('output/test.parquet')
    src_report.to_parquet('output/source_report.parquet')
    author_report.to_parquet('output/author_report.parquet')
    kw_report.to_parquet('output/keyword_report.parquet')
    
    assert make_final_logs(text_df, sen_df, true_df, train_df, test_df, rem_df, news_df, log=False)
    logging.info("done.")
    
# done.