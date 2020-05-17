using Base.Iterators

const Split = NTuple{2}
const SplitTree = Dict{T, Set{Split{T}}} where T
const Cache = Dict{UInt, Int}

isbelow(s::S, t::S) where {S <: AbstractString} = length(s) != length(t) && !isnothing(findfirst(s, t))

isbasic(s::AbstractString) = length(s) == 1

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

shortcuts(ss::Set) = filter(s -> any(t -> isbelow(s, t), ss), ss)

mutable struct Frame{S}
    ss::Set{S}
    sc::Set{S}
    cc::Int
    parent::Int
    seen::Bool

    Frame(ss::Set{S}, sc::Set{S}, cc::Int, parent::Int, seen::Bool) where S = new{S}(ss, sc, cc, parent, seen)
end

Base.hash(f::Frame, salt::UInt) = salt ⊻ hash((f.ss, f.sc))

function assembly(st::SplitTree{S}, ss::Set{S}, sc::Set{S}; cache::Cache=Cache()) where S
	stack = Array{Any}(undef, 1024)
    ptr = 1
	stack[ptr] = Frame(ss, sc, typemax(Int), 0, false)

	while ptr > 0
        frame = stack[ptr]
		ptr -= 1
		if haskey(cache, hash(frame))
			cc = cache[hash(frame)]
			f = stack[frame.parent]
			f.cc = min(f.cc, length(f.ss) + cc)
		elseif frame.seen && frame.parent != 0
			f = stack[frame.parent]
			f.cc = min(f.cc, length(f.ss) + frame.cc)
			cache[hash(frame)] = frame.cc
		elseif !frame.seen
			stack[ptr += 1].seen = true
			parent = ptr
			components = (st[s] for s in frame.ss)
			for group in product(components...)
				objects = Set(vcat(collect.(group)...))
				complex = filter(!isbasic, objects)
				scs = shortcuts(complex)
				union!(scs, frame.sc)
				setdiff!(complex, frame.sc)
				if ptr == length(stack)
					resize!(stack, 2length(stack))
				end
				if isempty(complex)
					stack[ptr += 1] = Frame(complex, scs, 0, parent, true)
				else
					stack[ptr += 1] = Frame(complex, scs, typemax(Int), parent, false)
				end
			end
		end
	end
    stack[1].cc
end

function assembly(s::S...; cache::Cache=Cache()) where S
	st = merge(SplitTree{S}(), splittree.(s)...)
	ss = Set(s)
	sc = shortcuts(ss)
	setdiff!(ss, sc)
	assembly(st, ss, sc; cache=cache)
end
