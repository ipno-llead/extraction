import pandas as pd
from fastai.text.all import *

torch.set_num_threads(1)

#lm_df = pd.read_parquet("../import/output/news.parquet")
df = pd.read_parquet("../data-update-sep2022/output/labeled-articles.parquet")

#def get_dls_lm(df):
#    df = pd.read_parquet(args.lm_input)
#    dls_lm = TextDataLoaders.from_df(df, valid_pct=0.1, text_col="content", is_lm=True, num_workers=0)
#    return dls_lm



dls_cm = TextDataLoaders.from_df(
    df,
    valid_pct=0.5,
    text_col='text',
    is_lm=False,
    label_col='relevant',
    #text_vocab=dls_lm.vocab,
    shuffle=True,
    bs=16,
    seq_len=288,
    y_block=CategoryBlock,
)

classifier_model = text_classifier_learner(dls_cm, AWD_LSTM, drop_mult=0.5, metrics=accuracy, pretrained=True, max_len=288*10)
#classifier_model.load_encoder("output/pretrained-encoder.pth")

lr1 = classifier_model.lr_find()
