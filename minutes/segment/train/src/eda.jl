include("src/data.jl")
include("src/model.jl")
include("src/crf.jl")
using .DataPrep
using .CRF
using .Model

using DataFrames
using Parquet
using Flux
using StatsBase

feats = DataFrame(Parquet.read_parquet("../features/output/training-data-features.parquet"));
re_cols = [col for col in names(feats) if contains(col, r"^re_")]
cols = [re_cols..., "caps_pct", "gap1", "gap2"]

labeled = [DataPrep.doc2vec(d, cols) for d in groupby(feats, [:docid])];

trainids = sample(1:length(labeled), 30)
testids = setdiff(1:length(labeled), trainids)

train = labeled[trainids]
test = labeled[testids]

loss(model, x, y) = -CRF.loglikelihood(model(x), y)

pred(model, x) = CRF.best_path(model(x)[1:(end-1)])
function correct(model, x, y)
    pred(model, x) .== y[2:(end-1)]
end

function smry(model, xy)
    x = xy[1]
    y = xy[2][2:(end-1)]
    ŷ = pred(model, x)
    y_uniq = unique(y)
    ŷ_uniq = unique(ŷ)
    uniq = unique(vcat(y_uniq, ŷ_uniq))
    tp = [sum(ŷ .== y .& y .== u) for u in uniq]
    pp = [sum(ŷ .== u) for u in uniq]
    ap = [sum(y .== u) for u in uniq]
    uniqlabs = [DataPrep.LABELS[u] for u in uniq]
    Dict(:tp => Dict(zip(uniqlabs, tp)),
         :pp => Dict(zip(uniqlabs, pp)),
         :ap => Dict(zip(uniqlabs, ap)))
end

function data_smry(model, dat)
    pp = Dict(p => 0 for p in DataPrep.LABELS)
    tp = Dict(p => 0 for p in DataPrep.LABELS)
    ap = Dict(p => 0 for p in DataPrep.LABELS)
    for t in dat
        stats = smry(model, t)
        for lab in DataPrep.LABELS
            pp[lab] += get(stats[:pp], lab, 0)
            tp[lab] += get(stats[:tp], lab, 0)
            ap[lab] += get(stats[:ap], lab, 0)
        end
    end
    return (pp = pp, tp = tp, ap = ap)
end

function rptback(model, test)
    stats = data_smry(model, test)
    println("hearing header (precision || recall): ",
            round(stats.tp["hearing_header"] / stats.pp["hearing_header"],
                  digits=2),
            " || ",
            round(stats.tp["hearing_header"] / stats.ap["hearing_header"],
                  digits=2))
    println("hearing (precision || recall): ",
            round(stats.tp["hearing"] / stats.pp["hearing"],
                  digits=2),
            " || ",
            round(stats.tp["hearing"] / stats.ap["hearing"],
                  digits=2))
    println("meeting header (precision || recall): ",
            round(stats.tp["meeting_header"] / stats.pp["meeting_header"],
                  digits=2),
            " || ",
            round(stats.tp["meeting_header"] / stats.ap["meeting_header"],
                  digits=2))
    println("other (precision || recall): ",
            round(stats.tp["other"] / stats.pp["other"],
                  digits=2),
            " || ",
            round(stats.tp["other"] / stats.ap["other"],
                  digits=2))
end

## MODEL ##
l1_feat = Dense(length(cols), 15)
l1_topix = Dense(100, 10)
l2 = Model.BiEncoder(25, 10)
l2_hid = Dense(20, length(DataPrep.LABELS))
f = Model.CRFLayer(length(DataPrep.LABELS))

function model(xs)
    re_fts = l1_feat.(xs.feats)
    tp_fts = l1_topix.(xs.topics)
    fts = vcat.(re_fts, tp_fts)
    scores = l2_hid.(l2(fts))
    f(scores)
end

myparams = Flux.params(l1_feat, l1_topix, l2, l2_hid, f)
opt = ADAM(.0001)
for i in 1:50
    println("starting ", " iteration ", i)
    Flux.train!((x, y, meta) -> loss(model, x, y), myparams, train, opt)
    println("## TRAIN ##", " (iteration ", i, ")" )
    println("loss (train): ", sum(loss(model, x, y) for (x, y) in train))
    rptback(model, train)
    println("## TEST ##", " (iteration ", i, ")" )
    println("loss (test): ", sum(loss(model, x, y) for (x, y) in test))
    rptback(model, test)
    println("#####")
end

[DataPrep.LABELS[p] for p in pred(model, train[10][1])] |> unique
[DataPrep.LABELS[p] for p in pred(model, test[7][1])] |> print
[DataPrep.LABELS[p] for p in test[7][2]] |> print

filter(row -> row[:fileid] == "10f35fc", feats)[!,[ "caps_pct", "gap1", "gap2"]]
