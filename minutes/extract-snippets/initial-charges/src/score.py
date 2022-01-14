import pandas as pd
import numpy as np
from fastai.text.all import *

df = pd.read_parquet("output/sents.parquet")

learn = load_learner("output/init-charges-baseline.pkl")

test_dl = learn.dls.test_dl(df.sentence)

preds = learn.get_preds(dl = test_dl)

newcol = [float(p[0]) for p in preds[0]]
df['score'] = newcol

df.to_parquet("output/predictions-all-sents.parquet")
