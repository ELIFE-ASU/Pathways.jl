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

mutable struct Thurber
    n::Int
    lb::Int
    vertical::Vector{Int}
    slant::Vector{Int}
    stack::Vector{Vector{Int}}
    function Thurber(n::Int)
        lb = lowerbound(n)
        vertical, slant = bounds(n, lb)
        new(n, lb, vertical, slant, [[1], [2]])
    end
end
Base.length(thurber::Thurber) = length(thurber.stack)
Base.getindex(thurber::Thurber, idx) = getindex(thurber.stack, idx)[end]
Base.lastindex(thurber::Thurber) = lastindex(thurber.stack)
chain(thurber::Thurber) = last.(thurber.stack)
function Base.push!(thurber::Thurber, segment::Vector{Int})
    push!(thurber.stack, segment)
    thurber
end
Base.pop!(thurber::Thurber) = pop!(thurber.stack)

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

function bounds!(thurber::Thurber)
    thurber.vertical, thurber.slant = bounds(thurber.n, thurber.lb)
    thurber
end

function bump!(thurber::Thurber)
    thurber.lb += 1
    bounds!(thurber)
    thurber
end

function retain(thurber::Thurber)
    i = length(thurber)
    aᵢ₋₁, aᵢ = thurber[end-1], thurber[end]
    retain(thurber.n, thurber.lb, thurber.vertical[i], thurber.slant[i+1], i, aᵢ₋₁, aᵢ)
end

function stackchildren!(thurber::Thurber)
    aᵢ = thurber[end]
    segment = Int[]
    for i in 1:length(thurber), j in i:length(thurber)
        aᵢ₊₁ = thurber[i] + thurber[j]
        if aᵢ < aᵢ₊₁ ≤ thurber.n
            push!(segment, aᵢ₊₁)
        end
    end
    unique!(sort!(segment))
    push!(thurber, segment)
end

function backup!(thurber::Thurber)
    while length(thurber) > 2
        pop!(thurber.stack[end])
        if isempty(thurber.stack[end])
            pop!(thurber)
        else
            break
        end
    end
    length(thurber) == 2
end

found(thurber::Thurber) = thurber[end] == thurber.n
ispartial(thurber::Thurber) = length(thurber) ≤ thurber.lb

function shortestchain(n::Int)
    if n < one(n)
        error("no chains defined for integers less than 1")
    elseif isone(n)
        return 0
    end

    thurber = Thurber(n)

    loop = 1
    while true
        while true
            if ispartial(thurber)
                if found(thurber)
                    return length(thurber) - 1, chain(thurber), loop
                elseif retain(thurber)
                    stackchildren!(thurber)
                elseif backup!(thurber)
                    loop += 1
                    break
                end
            elseif backup!(thurber)
                loop += 1
                break
            end
            loop += 1
        end
        bump!(thurber)
    end
end
