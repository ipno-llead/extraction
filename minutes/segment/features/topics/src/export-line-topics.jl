# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

using Parquet
using DataFrames
using Word2Vec
using DataFrames
using Parquet

model_file = ARGS[1]
data_file = ARGS[2]
out_file = ARGS[3]

# {{{ line vector = sum of word vectors 
function lines2vec(model, lines)
    inds = 1:length(lines)
    out = [zero(model.vectors[:, 1]) for i in inds]
    for i in inds
        line2vec(model, lines[i], out[i])
    end
    return out
end

function line2vec(model, line, init)
    for word in split(line)
        word in model.vocab || continue
        init .+= get_vector(model, word)
    end
end
# }}}

model = wordvectors(model_file)
corpus = read_parquet(data_file)
lines = corpus.normtext

vecs = lines2vec(model, lines)

# assemble outputs {{{
colname(i) = "t_" * string(i, pad=3)
dimensions = length(vecs[1])

topix = DataFrame(Dict(colname(i) => [v[i] for v in vecs]
                       for i in 1:dimensions))

out = DataFrame(docid = corpus.docid,
                docpg = corpus.docpg,
                lineno = corpus.lineno,
                topic_pos = argmax.(vecs),
                topic_neg = argmin.(vecs)) |> x -> hcat(x, topix)
# }}}

write_parquet(out_file, out)

# done.
