# task description

One of the sources of data flowing into LLEAD is an RSS feed of various
newspapers, filtered for specific keywords such as "police." However, even when
we are able to match these articles to individual officer IDs, many of them are
not relevant to the database. Rajiv has been manually reviewing the articles
and pushing those he determines are relevant to the production database.
Because he has tracked these decisions, we have access to the status of each
reviewed news article (either relevant or not relevant). We'll use this data to
train a text classifier 

# initial task outline

- `import`: should take a snapshot of relevant tables from basedash, and return
  a table with one row per article with a known status, and the associated
  label (1 or 0 for relevant or not relevant). Should categorize a fraction of
  the records as "test" data, not to be used for training.

- `train-baseline-model`: that should be enough to fit the first model, and
  from there we can figure out improvements. At least to start, we'll try using
  the [AWD-LSTM](https://docs.fast.ai/text.models.awdlstm.html#AWD_LSTM) from
  the [fastai](https://docs.fast.ai/) package.

- `classify`: this is where we'll prototype the code that takes in news
  articles that have gone through the initial filter, and the trained model,
  and returns just those articles that the model classifies as being relevant
  to the LLEAD database.
