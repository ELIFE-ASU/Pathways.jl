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
            push!(st[m], xs)
            for x in xs
                if !haskey(st, x)
                    push!(stack, x)
                end
            end
        end
    end
    st
end

shortcuts(ss::Vector{T}) where T = convert(Vector{T}, filter(s -> any(t -> isbelow(s, t), ss), ss))

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

function project(ϕ, st::SplitTree)
    T = typeof(ϕ(first(keys(st))))

    ϕ̂(x) = sort(map(ϕ, x))
    tree = SplitTree{T}()
    for (node, leaves) in st
        new_node = ϕ(node)
        new_leaves = unique!(map(ϕ̂, leaves))
        if haskey(tree, new_node)
            union!(tree[new_node], new_leaves)
        else
            tree[new_node] = new_leaves
        end
    end
    tree
end
project(T, ϕ) = st -> project(T, ϕ, st)

function assembly(ϕ::Function, s::S...; limit=typemax(Int)) where S
    st = merge(SplitTree{S}(), splittree.(s)...)
    ss = collect(s)
    sc = shortcuts(ss)::Vector{S}

    ssp = unique!(map(ϕ, ss))
    scp = convert(typeof(ssp), unique!(map(ϕ, sc)))

    setdiff!(ssp, scp)
    assembly(project(ϕ, st), ssp, scp; limit)
end

function split(str::S) where {S <: AbstractString}
    N = length(str) - 1
    xs = Array{Split{S}}(undef, N)
    for i in 1:N
        xs[i] = [str[1:i], str[i+1:end]]
    end
    xs
end

isbelow(s::S, t::S) where {S <: AbstractString} = length(s) != length(t) && !isnothing(findfirst(s, t))
isbasic(s::AbstractString) = length(s) ≤ 1

function formula(s::AbstractString; chars=sort(unique(collect(s))))
    d = Dict(c => 0 for c in chars)
    merge!(d, counter(collect(s)))
    last.(sort(collect(d); by=first))
end

function split(n::Int)
    xs = Array{Split{Int}}(undef, n ÷ 2)
    for i in eachindex(xs)
        xs[i] = [i, n-i]
    end
    xs
end

isbelow(n::Int, m::Int) = n < m
isbasic(n::Int) = n == 1

limit(n::Int) = sum(digits(n; base=2)) + floor(Int, log2(floor(n))) - 1

assembly(n::Int; limit=limit(n)) = assembly(splittree(n), [n], Int[]; limit)

function split(v::AbstractVector{Int})
    a = fill(0, length(v))
    a[1] = min(1, v[1])
    b = v .- a

    M = length(v)

    xs = Vector{Vector{Int}}[]
    i = 1
    while any(a .< v)
        if any(a .!= 0)
            x = (a < b) ? [a, b] : [b, a]
            push!(xs, deepcopy(x))
        end
        for j in 1:M
            if a[j] < v[j]
                a[j] += 1
                b[j] -= 1
                for k in 1:j-1
                    a[k] = 0
                    b[k] = v[k]
                end
                break
            end
        end
    end
    xs
end

isbelow(v::V, w::V) where {V <: AbstractVector} = v != w && all(v .≤ w)
isbasic(v::AbstractVector{Int}) = all(v .≥ 0) && sum(v) == 1
