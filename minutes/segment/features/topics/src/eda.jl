using Word2Vec

model = wordvectors("output/trained-vectors.txt")
get_vector(model, "item")

cosine_similar_words(model, "force")

cosine_similar_words(model, "unbecoming")
cosine_similar_words(model, "appeal")

cosine_similar_words(model, "#")

cosine_similar_words(model, "termination")
cosine_similar_words(model, "hearing")

cosine_similar_words(model, "JANUARY")
cosine_similar_words(model, "_dd_")
cosine_similar_words(model, "present")

