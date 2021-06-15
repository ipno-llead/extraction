module Model
using Flux

struct BiEncoder{T}
    forward::T
    backward::T
end

function BiEncoder(in::Int, out::Int)
    forward = LSTM(in, out)
    backward = LSTM(in, out)
    BiEncoder(forward, backward)
end

function forward(b::BiEncoder, tokens)
    out = b.forward.(tokens)
    Flux.reset!(b.forward)
    out
end

function backward(b::BiEncoder, tokens)
    out = Flux.flip(b.backward, tokens)
    Flux.reset!(b.backward)
    out
end

function (b::BiEncoder)(tokens)
    f2b = forward(b, tokens)
    b2f = backward(b, tokens)
    vcat.(f2b, b2f)
end


struct CRFLayer{T<:AbstractArray}
    transitions::T
end

function (f::CRFLayer)(scores)
    mat = f.transitions
    M = [mat .+ score' for score in scores]
    [M..., mat]
end

function CRFLayer(n_labels::Int)
    CRFLayer(rand(Float32, n_labels, n_labels))
end

Flux.trainable(b::BiEncoder) = Flux.params(b.forward, b.backward)
Flux.trainable(f::CRFLayer) = Flux.params(f.transitions)
end

