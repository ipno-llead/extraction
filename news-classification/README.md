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

---
## `import`

### Ouput
- writes "train.parquet", "test.parquet", with columns:
  - `article_id`: unique identifier for the article instance.
  - `content`: full text of the article.
  - `relevant`: boolean indicator for article presence in the manually approved set.
- writes "import.log", which captures some summary characteristics of the data as well as a few reports for transparency.
- creates but does not write "merged.parquet", the combined dataframe representing all 3 snapshots from basedash.
- with `make_report(df, col)`, can generate a summary of `col`'s prevalence in keyword matched and relevant data. A sample report using `extracted_keywords` is generated with train-test data.

### Columns added/modified
Added:
- `kw_match`: boolean indicator for keyword presence in article content.
- `relevant`: boolean indicator for article presence in the manually approved set.
- `train`, `test`: boolean indicator for article inclusion in train or test set. The train, test dataframes are a slice of the merged dataframe based on these columns.

Modified:
- `extracted_keywords`: Values in this col are case-sensitive lists represented as strings, and are modified to be case-insensitive sets of unique vals represented as strings. These results aren't written but can be seen in `make_report(merged, 'extracted_keywords')` which is logged by default.

### Maintaining distinctness of train/test
- Positive cases are defined by an article's relevance to the LLEAD database given that keywords were identified in the article content. Roughly 300 positive cases are available for initial training. By default, `train_size=0.80` and `test_size=0.20`, so about 250 articles are assigned to training and 50 are reserved for testing.
- Negative cases are defined by an article's _irrelevance_ to the LLEAD database despite keywords being identified. A few thousand of these points exist, so in the interest of our initial 500/100 goal, we use `pos_rate=0.50` to pad the training and test sets. Importantly, this is a significant overestimate of the real-world positive rate, which based on this data could be as low as 15%.
- Each time articles are assigned to train or test, `assert set(train_list).isdisjoint(set(test_list))` is run to make sure no overlap between them exists.

#### Comments/Questions
- Because the manually approved dataset goes by matched sentences and not by articles, the possibility exists for an article to have one sentence deemed relevant and a second deemed irrelevant. Because we intend to use unique articles and not unique sentences, the import task checks for overlap between relevant and irrelevant articles _before creating train/test data_ and then corrects the values so that any article with at least one sentence assigned True shows True for each instance of that article. 
  - Note: The same issue does not happen with the kw_match col, all of these values are linked back to their corresponding articles and in this case, `match.intersection(no_match)` is the empty set.
- We have a number of cases where it looks like two different sources posted the same article (same content, title, and author), and yet each was processed as a completely unique article by the current pipeline. The duplicates could be pulled from the dataset as a shortterm solution but a longterm fix would be adjusting the upstream handling of articles so that we are only taking in unique content or documenting additional URLs in a new field. Some of these cases are in the train-test data as they were marked relevant, and these articles will not be dropped with other duplicates since they have distinct ids.
  - matchedsentence_id appears to be unique to instance of a sentence in an article, so the text column which captures the specific sentence where a kw was matched shows the same pattern of overlap where a distinct id is assigned to a value we know. 
- Is it worth adding an assert for the `pos_rate` to make sure the data produced is within 5-10% of the specified rate?
- `pos_rate` could also be written in as an arg so that we could dispatch multiple train-test datasets at different positivity rates from makefile, which could be a good way to challenge/aid model performance.
- The article_id and matchedsentence_id generation are similar enough that there is overlap between these unique lists
- A couple of articles are actually TV show reviews, like one for The Flash season 8 (which also ends up being duplicated content as two different sources posted the author's review). We may want to consider a blacklist of words or some other solution to filter out crime-related TV articles!
- Upon looking at the article and content `merged.loc[merged.extracted_keywords == "{'terminated', 'officer', 'police'}"]`, it appears some articles that are irrelevant with keywords matched actually matched because the title of a suggested article was captured as content and that title contained keywords, whereas none of the sentences in the true article content match.

_outgoing train_test asserts I'm adding:_
1. No article_id or content is missing from either train or test sets
2. No article_id or content appears in both train AND test sets, or more than once in either
3. Every article_id has a relevant, test value

---
