ν(n::Int) = sum(digits(n, base=2))
λ(n::Int) = floor(Int, log2(n))

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
    t = if iseven(n)
        factor(n)[2]
    else
        zero(n)
    end

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
retain(bound::Int, aᵢ::Int, aᵢ₋₁::Int) = aᵢ + aᵢ₋₁ ≥ bound

function stackchildren!(stack::Vector{Vector{Int}}, chain::Vector{Int}; verbose=false)
    aᵢ = chain[end]
    segment = Int[]
    for i in 1:length(chain), j in i:length(chain)
        aᵢ₊₁ = chain[i] + chain[j]
        if aᵢ < aᵢ₊₁
            push!(segment, aᵢ₊₁)
        end
    end
    sort!(segment)
    push!(stack, segment[1:end])
    segment[end]
end

function backup(stack::Vector{Vector{Int}}, chain::Vector{Int}; verbose=false)
    while !isempty(stack)
        verbose && @info "Stack is not empty"
        if !isempty(stack[end])
            chain[end] = pop!(stack[end])
            verbose && @info "Stack segment is not empty" popped = chain[end]
            break
        else
            verbose && @info "Stack segment is empty"
            pop!(stack)
            pop!(chain)
        end
    end
end

function shortestchain(n::Int; verbose=false)
    if n ≤ 327_678 || ν(n) ≤ 16
        # We add 1 because Julia indexs from 1
        lb = λ(n) + ceil(Int, log2(ν(n))) + 1
    else
        # We add 1 because Julia indexs from 1
        lb = ceil(Int, log2(n) + log2(ν(n)) - 2.13)
    end

    chain = [1, 2]
    stack = Vector{Int}[]

    loop = 0

    while true
        vertical, slant = if n % 5 != 0
            vertical = bounds(BoundingSequenceC, n, lb)
            vertical, vertical
        else
            vertical = bounds(BoundingSequenceC, n, lb)
            slant = bounds(BoundingSequenceA, n, lb)
            vertical, slant
        end

        i = 2
        verbose && @info "Outer Loop" i lb vertical slant
        while true
            verbose && @info "State" n stack chain i lb loop
            if i ≤ lb
                if chain[i] ≤ n && retain(vertical[i], chain[i]) && retain(slant[i+1], chain[i], chain[i-1])
                    verbose && @info "Retained" chain[i]
                    if chain[end] == n
                        return lb - 1, chain
                    end
                    push!(chain, stackchildren!(stack, chain; verbose))
                    i += 1
                else
                    verbose && @info "Did not retain" chain[i] loop
                    backup(stack, chain; verbose)
                end
            else
                verbose && @info "Reached lower bound" loop
                backup(stack, chain; verbose)
            end
            loop += 1
        end
        lb += 1
    end
end
