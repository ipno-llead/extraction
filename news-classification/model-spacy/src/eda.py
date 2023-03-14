import pandas as pd
import numpy as np
import spacy
#from spacy.training import Example
import random

nlp = spacy.load("en_core_web_sm")

def lab2dict(lab):
    if lab == "a_relevant":
        return {'relevant': 1}
    else:
        return {'not_relevant': 1}

td = pd.read_parquet("../import/output/labeled-articles.parquet")
td['keep'] = ((td.relevant == "a_relevant") | (np.random.uniform(0, 1, len(td)) > .5))
traindata = td.loc[td.keep].copy()
traindata.relevant.value_counts()
traindata['split'] = [random.choice(['train', 'dev']) for _ in range(len(traindata))]

train_db = spacy.tokens.DocBin()
dev_db = spacy.tokens.DocBin()
for text, lab, split in zip(traindata.text, traindata.relevant, traindata.split):
    doc = nlp.make_doc(text)
    doc.cats = lab2dict(lab)
    if split == 'train':
        train_db.add(doc)
    else:
        dev_db.add(doc)

train_db.to_disk('output/train.spacy')
dev_db.to_disk('output/dev.spacy')

textcat = spacy.load("output/model/model-best")

piped = textcat.pipe(traindata.text)
traindata['predicted'] = [p.cats['relevant'] for p in piped]
traindata['predclass'] = traindata.predicted > .5
traindata[['predclass', 'relevant']].value_counts()
traindata[['relevant', 'predclass']].value_counts()
