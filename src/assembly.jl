using Base.Iterators

const Split = NTuple{2}
const SplitTree = Dict{T, Set{Split{T}}} where T
const Cache = Dict{NTuple{2, Set{T}}, Int} where T

function splittree(s::S) where {S <: AbstractString}
    st = SplitTree{S}()
    stack = [s]
    while !isempty(stack)
        str = pop!(stack)
        st[str] = Set{Split{S}}()
        for i in 1:length(str)-1
            a, b = str[1:i], str[i+1:end]
            push!(st[str], (a, b))
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

function assembly(st::SplitTree{S}, ss::Set{S}, sc::Set{S}, cache::Cache{S}) where {S <: AbstractString}
    if haskey(cache, (ss, sc))
        cache[(ss, sc)]
    else
        cc = typemax(Int)
        components = (st[s] for s in ss)
        for group in product(components...)
            objects = Set(vcat(collect.(group)...))
            complex = filter(!isbasic, objects)
            scs = filter(s -> any(t -> isbelow(s, t), complex), complex)
            union!(scs, sc)
            setdiff!(complex, sc)
            c = isempty(complex) ? 0 : assembly(st, complex, scs, cache)
            cc = min(cc, c)
        end
        cc += length(ss)
        cache[(ss, sc)] = cc
    end
end

function assembly(s::S...; cache::Cache{S}=Cache{S}()) where {S <: AbstractString}
    st = merge(SplitTree{String}(), splittree.(s)...)
    ss = Set(s)
    sc = filter(s -> any(t -> isbelow(s, t), ss), ss)
    setdiff!(ss, sc)
    assembly(st, Set(s), sc, cache)
end

isbelow(s::S, t::S) where {S <: AbstractString} = length(s) != length(t) && !isnothing(findfirst(s, t))

isbasic(s::AbstractString) = length(s) == 1
