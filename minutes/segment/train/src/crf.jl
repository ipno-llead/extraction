module CRF

using Zygote
using Flux: logsumexp

function log_dot(A, B)
    logsumexp(A .+ B)
end

function log_matmul!(result, log_A, log_B)
    for i in axes(log_A)[1]
        for j in axes(log_B)[2]
            result[i, j] = log_dot(log_A[i, :], log_B[:, j])
        end
    end
end

function log_matmul(log_A, log_B)
    result = Zygote.Buffer(log_A)
    log_matmul!(result, log_A, log_B)
    return copy(result)
end

normalization_factor(M) = foldl(log_matmul, M)[1,end]

function loglikelihood(M, y)
    unnormalized = sum(M[i][y[i], y[i+1]] for i in eachindex(M))
    Z = normalization_factor(M)
    unnormalized - Z
end

function best_path(M)
    T = length(M)
    J = size(M[1], 1)
    δ = zeros(eltype(M[1]), T, J)
    ψ = zeros(Int, T, J)
    δ[1,:] = M[1][1,:]
    ψ[1,:] = ones(eltype(ψ), size(ψ, 2))
    for t in 2:T
        for j in 1:J
            scores = δ[t-1, :] .+ M[t][:, j]
            δ[t,j] = maximum(scores)
            ψ[t,j] = argmax(scores)
        end
    end
    #pstar = maximum(δ[end,:])
    q = zeros(Int, T)
    q[end] = argmax(δ[end,:])
    for t in (T-1):-1:1
        q[t] = ψ[t+1, q[t+1]]
    end
    #return pstar, q
    return q
end

end
