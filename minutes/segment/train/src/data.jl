module DataPrep

using Flux
#using WordTokenizers, Embeddings
using Word2Vec
using Flux: onehot, onecold

LABELS = [
    "meeting_header",
    "roll_call",
    "other",
    "hearing_header",
    "hearing",
    "START",
    "STOP"
 ]

#feats = DataFrame(Parquet.read_parquet("../features/output/training-data-features.parquet"))

const emtable = wordvectors("../word2vec/output/trained-vectors.txt")
const get_word_index = Dict(word=>ii for (ii,word) in enumerate(emtable.vocab))

function get_embedding(word)
    ind = get_word_index[word]
    em = emtable.vectors[:,ind]
    return convert(Vector{Float32}, em)
end

function line2vec(line)
    sums = convert(Vector{Float32}, zero(emtable.vectors[:, 1]))
    n = 0
    for tk in split(line)
        !haskey(get_word_index, tk) && continue
        n += 1
        sums .+= get_embedding(tk)
    end
    n == 0 && return sums
    return sums
end

function feats2vec(row, cols)
    convert(Vector{Float32}, [row[c] for c in cols])
end

function doc2vec(doc, cols)
    x_wordvecs = [line2vec(l.normtext) for l in eachrow(doc)]
    x_featvecs = [feats2vec(l, cols) for l in eachrow(doc)]
    ys = [onecold(onehot(lab, LABELS))
          for lab in ["START", doc.label..., "STOP"]]
    fileid = unique(doc.fileid)
    pageno = unique(doc.pageno)
    docid = unique(doc.docid)
    docpg = unique(doc.docpg)
    meta = (fileid = fileid, pageno = pageno, docid = docid, docpg = docpg)
    xs = (feats = x_featvecs, topics = x_wordvecs)
    xs, ys, meta
end

end
