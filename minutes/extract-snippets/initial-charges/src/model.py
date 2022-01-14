import pandas as pd
from fastai.text.all import *
torch.set_num_threads(11)

df = pd.read_parquet("output/initial-charges.parquet")

dls = TextDataLoaders.from_df(df, path="output", valid_pct = .3,
        text_col='sentence', is_lm=False, seq_len = 72, label_col='label',
        num_workers=0)


#dls.show_batch(max_n=2)

learn = text_classifier_learner(dls, AWD_LSTM, drop_mult=0.5,
        metrics = [accuracy, RocAucBinary()])


lr = learn.lr_find()
plt.show()

learn.fine_tune(2, 1e-2)


learn.export("init-charges-baseline.pkl")
learn.data.add_test(df.sentence)

bx, by = dls.one_batch()
learn.get_preds(dl = [(bx, by)])


#learn.validate()

learn.get_preds()

interp = ClassificationInterpretation.from_learner(learn)
interp.confusion_matrix()
interp.top_losses(3)
