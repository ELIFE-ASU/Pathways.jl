using DataStructures

const Split = Vector
const SplitTree = Dict{T, Vector{Split{T}}} where T

function splittree(n::S) where S
    st = SplitTree{S}()
    stack = [n]
    while !isempty(stack)
        m = pop!(stack)
        st[m] = Vector{Split{S}}()
        for xs in split(m)
            if xs in st[m]
                continue
            end
            a, b = xs
            push!(st[m], [a, b])
            if !haskey(st, a)
                push!(stack, a)
            end
            if !haskey(st, b)
                push!(stack, b)
            end
        end
    end
    st
end

shortcuts(ss) = filter(s -> any(t -> isbelow(s, t), ss), ss)

function product(components::Vector{Vector{Vector{T}}}) where T
    M = length(components)
    groups = Vector{T}[]
    idx = fill(1, M)
    max = length.(components)
    N = prod(max)
    i = 1
    while i <= N
        a = map(getindex, components, idx)
        push!(groups, vcat(a...))
        for j in 1:M
            if idx[j] < max[j]
                idx[j] += 1
                for k in 1:j-1
                    idx[k] = 1
                end
                break
            end
        end
        i += 1
    end
    groups
end

function assembly(st::SplitTree{S}, ss::Vector{S}, sc::Vector{S}; limit=typemax(Int)) where S
    Q = Queue{Tuple{Vector{S}, Vector{S}, Int}}()
    enqueue!(Q, (ss, sc, length(ss)))
    while !isempty(Q)
        (ss, sc, cc) = dequeue!(Q) :: Tuple{Vector{S}, Vector{S}, Int}
        if cc ≥ limit
            continue
        end
        for objects in product([st[s] for s in ss])
            filter!(!isbasic, objects)
            setdiff!(objects, sc)
            if isempty(objects)
                limit = min(limit, cc)
                break
            elseif cc + length(objects) < limit
                scs = shortcuts(objects)
                union!(scs, sc)
                enqueue!(Q, (objects, scs, cc + length(objects)))
            end
        end
    end
    limit
end

function assembly(s::S...; limit=typemax(Int)) where S
    st = merge(SplitTree{S}(), splittree.(s)...)
    ss = collect(s)
    sc = shortcuts(ss)
    setdiff!(ss, sc)
    assembly(st, ss, sc; limit)
end

function split(str::S) where {S <: AbstractString}
    N = length(str) - 1
    xs = Array{Split{S}}(undef, N)
    for i in 1:N
        a, b = str[1:i], str[i+1:end]
        a, b = a <= b ? (a, b) : (b, a)
        xs[i] = [a, b]
    end
    xs
end

isbelow(s::S, t::S) where {S <: AbstractString} = length(s) != length(t) && !isnothing(findfirst(s, t))
isbasic(s::AbstractString) = length(s) ≤ 1

function split(n::Int)
    xs = Array{Split{Int}}(undef, n ÷ 2)
    for i in eachindex(xs)
        a, b = i, n-i
        a, b = a <= b ? (a, b) : (b, a)
        xs[i] = [a, b]
    end
    xs
end

isbelow(n::Int, m::Int) = n < m
isbasic(n::Int) = n == 1

upperassembly(n::Int) = sum(digits(n; base=2)) + floor(Int, log2(floor(n))) - 1

assembly(n::Int; limit=upperassembly(n)) = assembly(splittree(n), [n], Int[]; limit)

const Cache = Dict{Union{T, NTuple{2,T}}, Int} where T

function upperassembly(x::T; cache=Cache{T}()) where T
    if isbasic(x)
        0
    elseif haskey(cache, x)
        cache[x]
    else
        cc = typemax(Int)
        for (y, z) in split(x)
            cc = min(cc, upperassembly(y, z; cache) + 1)
        end
        cache[x] = cc
    end
end

function upperassembly(x::T, y::T; cache=Cache{T}()) where {T <: AbstractString}
    if haskey(cache, (x, y))
        return cache[(x, y)]
    end

    cache[(x,y)] = if isbasic(x) || isbelow(x, y)
        upperassembly(y; cache)
    elseif isbasic(y) || isbelow(y, x)
        upperassembly(x; cache)
    else
        upperassembly(x; cache) + upperassembly(y; cache)
    end
end
