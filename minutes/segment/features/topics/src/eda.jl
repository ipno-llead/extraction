using Word2Vec

model = wordvectors("output/trained-vectors.txt")
get_vector(model, "item")

cosine_similar_words(model, "force")

cosine_similar_words(model, "unbecoming")
cosine_similar_words(model, "appeal")

cosine_similar_words(model, "#")

cosine_similar_words(model, "termination")
get_vector(model, "termination")

cosine_similar_words(model, "hearing")

cosine_similar_words(model, "_MONTH_")
cosine_similar_words(model, "minutes")

cosine_similar_words(model, "joke")



cosine_similar_words(model, "_dd_")
cosine_similar_words(model, "_d_")

cosine_similar_words(model, "present")

