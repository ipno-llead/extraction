import argparse
import pandas as pd
from fastai.text.all import *


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--lm_input")
    parser.add_argument("--cm_input")
    parser.add_argument("--modeloutput")
    return parser.parse_args()


def get_dls_lm(df):
    df = pd.read_parquet(args.lm_input)
    dls_lm = TextDataLoaders.from_df(df, valid_pct=0.1, text_col="content", is_lm=True, num_workers=0)
    return dls_lm


def train_lm(dls_lm):
    # augment the pretrained language model with the unlabeled news articles
    learn_lm = language_model_learner(dls_lm, AWD_LSTM, metrics=[accuracy, Perplexity()], wd=0.1).to_fp16()
    return learn_lm


def save_lm():
    learn_lm.save("../output/learnlm_ftuned")
    learn_lm.save_encoder("../output/learnlm_ftuned_enc")
    return learn_lm


def set_lm_lr(lr): return lr


def get_dls_cm(args):
    df = pd.read_parquet(args.cm_input).astype(str)
    dls_cm = TextDataLoaders.from_df(
        df,
        valid_pct=0.2,
        text_col="content",
        is_lm=False,
        label_col="relevant",
        text_vocab=dls_lm.vocab,
        shuffle=True,
        bs=128,
        seq_len=72,
        y_block=CategoryBlock,
    )
    return dls_cm


def train_cm(dls_cm):
    model = text_classifier_learner(dls_cm, AWD_LSTM, drop_mult=0.5, metrics=accuracy)
    return model
    # metrics=[accuracy_multi, RocAucMulti(), accuracy])


def set_cm_lr(lr): return lr


if __name__ == "__main__":
    args = get_args()

    ##### language model #####
    dls_lm = get_dls_lm(args)
    learn_lm = train_lm(dls_lm)

    # lm_lr = learn_lm.lr_find()

    print("fitting language model")
    lr = set_lm_lr(lr=1e-2)
    learn_lm.fit_one_cycle(2, lr)  # 2 epochs
    learn_lm.unfreeze()
    learn_lm.fit_one_cycle(8, lr)  # 2 epochs
    learn_lm = save_lm()

    ##### classifier model #####
    dls_cm = get_dls_cm(args)
    learn_cm = train_cm(dls_cm)
    # learn_cm.load_encoder("../output/learnlm_finetuned_enc")

    # cm_lr = learn_cm.lr_find()

    print("fitting classifier model")
    lr = set_cm_lr(2e-2)
    learn_cm.fit_one_cycle(1, lr) # 1 epoch
    learn_cm.freeze_to(-2)
    learn_cm.fit_one_cycle(3, slice(lr / (2.6 ** 4), lr)) # 3 epochs
    learn_cm.freeze_to(-3)
    learn_cm.fit_one_cycle(5, slice(lr / 2 / (2.6 ** 4), lr / 2)) # 5 epochs 
    learn_cm.unfreeze()
    learn_cm.fit_one_cycle(10, slice(lr / 10 / (2.6 ** 4), lr / 10)) # 10 epochs

    ##### export classifier model #####
    print("exporting model")
    learn_cm.export(args.modeloutput)
