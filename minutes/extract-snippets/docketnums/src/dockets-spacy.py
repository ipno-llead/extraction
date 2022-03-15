# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2022, HRDAG, GPL v2 or later
# =========================================

import argparse
import pandas as pd
import spacy

from spacy.matcher import Matcher

def getargs():
    parser = argparse.ArgumentParser()
    parser.add_argument("--hearings")
    parser.add_argument("--output")
    return parser.parse_args()

def getdata(args):
    df = pd.read_parquet(args.hearings)
    df[['hrg_head', 'hrg_text']] = df[['hrg_head', 'hrg_text']].fillna('')
    alltext = zip(df['hrg_head'], df['hrg_text'])
    df['text'] = [' '.join([str(x), str(y)]) for x, y in alltext]
    return df

def extract_dockets(texts, langmod):
    docs = [langmod(t) for t in texts]
    matcher = make_matcher(langmod)
    return [get_matches(doc, matcher)[0] for doc in docs]

def get_matches(doc, matcher):
    matches = matcher(doc)
    spans = [doc[start:end] for _, start, end in matches]
    uniquespans = spacy.util.filter_spans(spans)
    if len(uniquespans) > 0:
        return [s.text.strip() for s in uniquespans]
    else:
        return ['']

def make_matcher(nlp):
    dkt_pattern = [{"LOWER": {"IN": ["docket", "dockets", "dkt", "dkts"]}},
        {"IS_PUNCT": True, "OP": "?"},
        {"LOWER": {"IN": ["no", "number", "nbr",
            "nos", "numbers", "nbrs"]}, "OP": "?"},
        {"IS_PUNCT": True, "OP": "*"},
        {"ORTH": "#", "OP": "?"},
        {"TEXT": {"REGEX": "^[0-9A-Z\-]+$"}, "OP": "+"} ]
    matcher = Matcher(nlp.vocab)
    matcher.add("docket", [dkt_pattern])
    return matcher

if __name__ == '__main__':
    args = getargs()
    df = getdata(args)
    nlp = spacy.load("en_core_web_sm")
    df['docket'] = extract_dockets(df.text, nlp)
    df[['docid', 'hrgno', 'docket']].to_parquet(args.output)

# done.
