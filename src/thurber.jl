using Primes

ν(n::Int) = sum(digits(n, base=2))
λ(n::Int) = floor(Int, log2(n))
function lowerbound(n::Int)
    if n ≤ 327_678 || ν(n) ≤ 16
        # We add 1 because Julia indexs from 1
        λ(n) + ceil(Int, log2(ν(n))) + 1
    else
        # We add 1 because Julia indexs from 1
        ceil(Int, log2(n) + log2(ν(n)) - 2.13)
    end
end

abstract type BoundingSequence end
abstract type BoundingSequenceA <: BoundingSequence end
abstract type BoundingSequenceC <: BoundingSequence end

function bounds(::Type{BoundingSequenceA}, n::Int, lb::Int)
    seq = zeros(Int, lb + 1)
    seq[end] = n
    for i in 1:lb
        seq[end-i] = ceil(Int, seq[end-i+1] / 2)
    end
    seq
end

function bounds(::Type{BoundingSequenceC}, n::Int, lb::Int)
    t = iseven(n) ? factor(n)[2] : zero(n)

    seq = zeros(Int, lb + 1)
    seq[end] = n
    for i in 1:lb-t-1
        seq[i] = ceil(Int, n / (3 * 2^(lb - (i + 1))))
    end
    for i in lb-t:lb
        seq[i] = ceil(Int, n / 2^(lb - (i - 1)))
    end
    seq
end

function bounds(n::Int, lb::Int)
    if n % 5 != 0
        vertical = bounds(BoundingSequenceC, n, lb)
        vertical, vertical
    else
        vertical = bounds(BoundingSequenceC, n, lb)
        slant = bounds(BoundingSequenceA, n, lb)
        vertical, slant
    end
end

retain(bound::Int, aᵢ::Int) = aᵢ ≥ bound
retain(bound::Int, aᵢ₋₁::Int, aᵢ::Int) = aᵢ + aᵢ₋₁ ≥ bound
retain(n::Int, lb::Int, i::Int, aᵢ::Int) = n != 2^(lb - i + 1) * aᵢ

function retain(n::Int, lb::Int, v::Int, s::Int, i::Int, aᵢ₋₁::Int, aᵢ::Int)
    retain(v, aᵢ) && retain(n, lb, i, aᵢ) && retain(s, aᵢ₋₁, aᵢ)
end

function stackchildren!(n::T, stack::Vector{Vector{T}}; verbose=false) where T
    aᵢ = stack[end][end]
    segment = T[]
    for i in 1:length(stack), j in i:length(stack)
        for aᵢ₊₁ in assemble(stack[i][end], stack[j][end])
            if isbelow(aᵢ, aᵢ₊₁) && (isequal(aᵢ₊₁, n) || isbelow(aᵢ₊₁, n))
                push!(segment, aᵢ₊₁)
            end
        end
    end
    unique!(sort!(segment))
    push!(stack, segment)
end

function backup(N::Int, stack::Vector{Vector{T}}; verbose=false) where T
    while length(stack) > N
        pop!(stack[end])
        if isempty(stack[end])
            pop!(stack)
        else
            break
        end
    end
    length(stack) ≤ N
end

function shortestchain(n::T; verbose=false) where T
    if isbasic(n)
        return 0, [1], 0
    end

    stack = Vector{T}[]
    for x in basic(n)
        push!(stack, [x])
    end
    N = length(stack)
    lb = lowerbound(basicsize(n))

    loop = 1
    while true
        if length(stack) == N
            stackchildren!(n, stack)
        end

        vertical, slant = bounds(basicsize(n), lb)
        verbose && @info "Outer Loop" lb vertical slant
        while true
            i = length(stack)
            verbose && @info "State" n stack lb loop
            if i ≤ lb
                aᵢ₋₁, aᵢ = stack[i-1][end], stack[i][end]

                if retain(basicsize(n), lb, vertical[i], slant[i+1], i, basicsize(aᵢ₋₁), basicsize(aᵢ))
                    verbose && @info "Retained" aᵢ
                    if aᵢ == n
                        return lb - 1, last.(stack), loop
                    end
                    stackchildren!(n, stack; verbose)
                else
                    verbose && @info "Did not retain" aᵢ loop
                    if backup(N, stack; verbose)
                        loop += 1
                        break
                    end
                end
            else
                verbose && @info "Reached lower bound" loop
                if backup(N, stack; verbose)
                    loop += 1
                    break
                end
            end
            loop += 1
        end
        lb += 1
    end
end

@inline isbelow(n::Int, m::Int) = isless(n, m)
@inline isbasic(n::Int) = isone(n)
@inline basic(n::Int) = [one(n)]
@inline assemble(n::Int, m::Int) = [n + m]
@inline numbasic(n::Int) = 1
@inline basicsize(n::Int) = n
