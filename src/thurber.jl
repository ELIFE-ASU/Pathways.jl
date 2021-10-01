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

retain(bound::Int, aᵢ::Int) = aᵢ ≥ bound
retain(bound::Int, aᵢ₋₁::Int, aᵢ::Int) = aᵢ + aᵢ₋₁ ≥ bound
retain(n::Int, lb::Int, i::Int, aᵢ::Int) = n != 2^(lb - i + 1) * aᵢ

function retain(n::Int, lb::Int, v::Int, s::Int, i::Int, aᵢ₋₁::Int, aᵢ::Int)
    retain(v, aᵢ) && retain(n, lb, i, aᵢ) && retain(s, aᵢ₋₁, aᵢ)
end

function stackchildren!(n::Int, stack::Vector{Vector{Int}}; verbose=false)
    aᵢ = stack[end][end]
    segment = Int[]
    for i in 1:length(stack), j in i:length(stack)
        aᵢ₊₁ = stack[i][end] + stack[j][end]
        if aᵢ < aᵢ₊₁ ≤ n
            push!(segment, aᵢ₊₁)
        end
    end
    unique!(sort!(segment))
    push!(stack, segment)
end

function backup(stack::Vector{Vector{Int}}; verbose=false)
    while length(stack) > 2
        pop!(stack[end])
        if isempty(stack[end])
            pop!(stack)
        else
            break
        end
    end
    length(stack) == 2
end

function shortestchain(n::Int; verbose=false)
    if n < one(n)
        error("no chains defined for integers less than 1")
    elseif isone(n)
        return 0, [1], 0
    end

    stack = Vector{Int}[[1],[2]]
    lb = lowerbound(n)

    loop = 1
    while true
        vertical, slant = if n % 5 != 0
            vertical = bounds(BoundingSequenceC, n, lb)
            vertical, vertical
        else
            vertical = bounds(BoundingSequenceC, n, lb)
            slant = bounds(BoundingSequenceA, n, lb)
            vertical, slant
        end

        verbose && @info "Outer Loop" lb vertical slant
        while true
            i = length(stack)
            verbose && @info "State" n stack lb loop
            if i ≤ lb
                aᵢ₋₁, aᵢ = stack[i-1][end], stack[i][end]

                if retain(n, lb, vertical[i], slant[i+1], i, aᵢ₋₁, aᵢ)
                    verbose && @info "Retained" aᵢ
                    if aᵢ == n
                        return lb - 1, last.(stack), loop
                    end
                    stackchildren!(n, stack; verbose)
                else
                    verbose && @info "Did not retain" aᵢ loop
                    if backup(stack; verbose)
                        loop += 1
                        break
                    end
                end
            else
                verbose && @info "Reached lower bound" loop
                if backup(stack; verbose)
                    loop += 1
                    break
                end
            end
            loop += 1
        end
        lb += 1
    end
end
