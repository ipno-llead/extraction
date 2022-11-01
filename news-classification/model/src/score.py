import argparse
import pandas as pd
import numpy as np
from fastai.text.all import *


def getargs():
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", default = "../import/output/all-candidates.parquet")
    parser.add_argument("--model", default = "frozen/trained-classifier-exported.zip")
    parser.add_argument("--scores")
    return parser.parse_args()


def getdata(args):
    return pd.read_parquet(args.data)


def getdls(df, model):
    return model.dls.test_dl(df.text)


def getmodel(args):
    return load_learner(args.model)


def scoredata(model, dl):
    return model.get_preds(dl=dl)


def makeexport(data, preds, vocab):
    for i, v in enumerate(vocab):
        data["score_" + v] = [float(p[i]) for p in preds[0]]
    return data


if __name__ == "__main__":
    args = getargs()
    learn = getmodel(args)
    df = getdata(args)
    dl = getdls(df, learn)
    preds = learn.get_preds(dl=dl)

    output = makeexport(df, preds, learn.dls.vocab[1])
    output.to_parquet(args.scores, index=False)
