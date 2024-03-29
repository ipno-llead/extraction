# Authors:     BP
# Maintainers: BP
# Copyright:   2022, HRDAG, GPL v2 or later
# =========================================
# extraction/news-classification/import/src/patch_relevant.py

# dependencies
import argparse
from pathlib import Path
from sys import stdout
import logging
import yaml
import pandas as pd

# support methods
def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", default='../output/merged.parquet')
    parser.add_argument("--p1", default='../hand/review_random.yml')
    parser.add_argument("--p2", default='../hand/review_testdf.csv')
    parser.add_argument("--p3", default='../hand/to_label_ai.xlsx')
    parser.add_argument("--output")
    args = parser.parse_args()
    assert Path(args.input).exists()
    assert Path(args.p1).exists()
    assert Path(args.p2).exists()
    assert Path(args.p3).exists()
    return args


def get_logger(sname, file_name=None):
    logger = logging.getLogger(sname)
    logger.setLevel(logging.DEBUG)
    formatter = logging.Formatter("%(asctime)s - %(levelname)s " +
                                  "- %(message)s", datefmt='%Y-%m-%d %H:%M:%S')
    stream_handler = logging.StreamHandler(stdout)
    stream_handler.setFormatter(formatter)
    logger.addHandler(stream_handler)
    if file_name:
        file_handler = logging.FileHandler(file_name)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
    return logger


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


def labels_from_audit(manual_audit):
    labels = {key:(1 if val == True else 0) for key,val in manual_audit.items()}
    return labels


def prep_df(df):
    if 'actual_relevancy' in df.columns:
        return df.rename(columns={'actual_relevancy':'relevant'})#.set_index('article_id')
    return df.rename(columns={'new_label':'relevant'})#.set_index('article_id')


def update_from_dict(raw, p1):
    copy = raw.copy()
    artids = list(p1.keys())
    for artid in artids:
        copy.loc[copy.article_id == artid, 'relevant'] = p1[artid]
    return copy


def update_from_df(raw, new):
    copy = raw.copy()
    artids = new.article_id.unique().tolist()
    for artid in artids:
        copy.loc[copy.article_id == artid, 'relevant'] = new.loc[new.article_id == artid, 'relevant']
    return copy


def update(l, r):
    if type(r) is dict:
        return update_from_dict(l, r)
    return update_from_df(l, r)


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


# main
if __name__ == '__main__':

    # setup logging
    logger = get_logger("output/patch_relevant.log")
    
    # arg handling
    args = get_args()
    
    # load data
    logger.info('loading data')
    raw = pd.read_parquet(args.input)
    p1_dict = labels_from_audit(read_yaml(args.p1))
    p2_df = prep_df(pd.read_csv(args.p2, usecols=['article_id', 'actual_relevancy']))
    p3_df = prep_df(pd.read_excel(args.p3, usecols=['article_id', 'new_label']))
    
    logger.info('merging hand-labeled data')
    new = pd.concat([p3_df, p2_df]).drop_duplicates(subset='article_id')
    
    p2_true = set(p2_df.loc[(p2_df.relevant == 1), 'article_id'].unique())
    p3_true = set(p3_df.loc[(p3_df.relevant == 1), 'article_id'].unique())
    new_true = set(new.loc[(new.relevant == 1), 'article_id'].unique())
    
    logger.info('verifying no true records lost from merge')
    assert len(p2_true.difference(new_true)) == len(p3_true.difference(new_true)) == 0
    logger.info('all true records present after merge')
    logger.info('implementing updated records')
    out = update(raw, p1_dict)
    out = update(out, new)

    # generate keyword report (source_id, author also helpful reports)
    kw_report = make_report(out, 'extracted_keywords')
    logger.info('keyword report')
    logger.info('=======================================================================')
    logger.info('{:50}{:15}{:10}'.format('extracted_keywords', 'relevant_perc', 'kw_match'))
    sorted_kw_report = kw_report[['extracted_keywords', 'relevant_perc', 'kw_match']].sort_values(by='relevant_perc', ascending=False)
    for tup in sorted_kw_report.itertuples():
        logger.info(pretty_str(tup.extracted_keywords+':', tup.relevant_perc, b=tup.kw_match))

    out.to_parquet(args.output)
    logger.info(f'updated records and saved to {args.output}')
    logger.info('done')

# done.
