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

function assembly(st::SplitTree{S}, ss::Set{S}, sc::Set{S}; cache::Cache=Cache()) where S
	stack = Array{Any}(undef, 1024)
	ptr = 1
	stack[ptr] = [ss, sc, typemax(Int), 0, false]

	while ptr > 0
		ss, sc, cc, parent, seen = stack[ptr]
		ptr -= 1
		if haskey(cache, hash((ss, sc)))
			cc = cache[hash((ss, sc))]
			f = stack[parent]
			f[3] = min(f[3], length(f[1]) + cc)
		elseif seen && parent != 0
			f = stack[parent]
			f[3] = min(f[3], length(f[1]) + cc)
			cache[hash((ss, sc))] = cc
		elseif !seen
			ptr += 1
			stack[ptr] = [ss, sc, cc, parent, true]
			parent = ptr
			components = (st[s] for s in ss)
			for group in product(components...)
				objects = Set(vcat(collect.(group)...))
				complex = filter(!isbasic, objects)
				scs = shortcuts(complex)
				union!(scs, sc)
				setdiff!(complex, sc)
				if ptr == length(stack)
					resize!(stack, 2length(stack))
				end
				ptr += 1
				if isempty(complex)
					stack[ptr] = [complex, scs, 0, parent, true]
				else
					stack[ptr] = [complex, scs, typemax(Int), parent, false]
				end
			end
		end
	end
	stack[1][3]
end

function assembly(s::S...; cache::Cache=Cache()) where S
	st = merge(SplitTree{S}(), splittree.(s)...)
	ss = Set(s)
	sc = shortcuts(ss)
	setdiff!(ss, sc)
	assembly(st, ss, sc; cache=cache)
end
