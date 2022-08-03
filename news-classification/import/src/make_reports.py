# Authors:     BP
# Maintainers: BP
# Copyright:   2022, HRDAG, GPL v2 or later
# =========================================
# extraction/news-classification/import/src/duplicate_report.py

# dependencies
from pathlib import Path
from sys import stdout
import hashlib
import yaml
import argparse
import logging
import pandas as pd

# support methods
def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--news", default=None)
    parser.add_argument("--output", default=None)
    args = parser.parse_args()
    assert Path(args.news).exists()
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


def write_yaml(filename, data):
    with open(filename, 'w') as f:
        yaml.dump(data, f, default_flow_style=False)
    assert open(filename).read()


def make_sha1(val):
    encoded_val = val.encode()
    hash_obj = hashlib.sha1(encoded_val)
    hexa_value = hash_obj.hexdigest()
    return hexa_value


def get_dupe_groups(news):
    # duplicate non-null content in news.parquet
    dup_news = news.loc[(news.content.notnull()) & (news.duplicated(subset='content'))].content.unique().tolist()
    dup_news_df = news.loc[news.content.isin(dup_news)]
    dup_groups = {}
    for tup in dup_news_df.itertuples():
        con_hash = make_sha1(tup.content)
        if con_hash not in dup_groups:
            dup_groups[con_hash] = [tup.article_id]
        else:
            dup_groups[con_hash].append(tup.article_id)
    groups = [id_list for key,id_list in dup_groups.items()]
    return groups


# main
if __name__ == '__main__':

    # setup logging
    logger = get_logger(__name__, "output/duplicate_report.log")

    # arg handling
    args = get_args()
    news_f = args.news
    output_f = args.output

    # read data
    logger.info("Loading data.")
    news = pd.read_parquet(news_f)
    logger.info("finished loading data.")
    
    # do stuff
    logger.info("preparing groups of duplicate content")
    groups = get_dupe_groups(news)
    logger.info("finished preparing dupe groups")
    
    # save data
    logger.info("saving data as yaml")
    write_yaml(output_f, groups)
    logger.info("group data written to yaml file")
    
    logger.info("done.")
    
# done.