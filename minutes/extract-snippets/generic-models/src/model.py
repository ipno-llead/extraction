import argparse
import pandas as pd
from fastai.text.all import *

def getargs():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", default="../import/output/phase2-all-labels.parquet")
    parser.add_argument("--modelout", default="snippet-classifier.pkl")
    return parser.parse_args()

def get_dls(args):
    df = pd.read_parquet(args.input)
    dls = TextDataLoaders.from_df( df, path="output", valid_pct = .5,
            text_col='sentence', is_lm=False, seq_len = 72,
            label_col='label', y_block=MultiCategoryBlock, label_delim=' ',
            num_workers=0)
    return dls

def construct_model(dls):
    model = text_classifier_learner(dls, AWD_LSTM, drop_mult=0.5,
            metrics=accuracy_multi)
    return model
    #metrics=[accuracy_multi, RocAucMulti()])

if __name__ == '__main__':
    args = getargs()
    dls = get_dls(args)
    learn = construct_model(dls)
    #lr = learn.lr_find()
    print("fitting model")
    learn.fine_tune(5, 5e-3)
    print("exporting model")
    learn.export(args.modelout)
