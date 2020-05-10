using Base.Iterators

function stringtree(s::String)
	st = Dict{String, Set{Tuple{String,String}}}()
	stack = [s]
	while !isempty(stack)
		str = pop!(stack)
		st[str] = Set{Tuple{String,String}}()
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

assembly(s::String) = coassembly(stringtree(s), Set([s]))

function coassembly(st, ss, sc, cache)
	if haskey(cache, (ss, sc))
		cache[(ss, sc)]
	else
		cc = typemax(Int)
		components = (st[s] for s in ss)
		for group in product(components...)
			objects = Set(vcat(collect.(group)...))
			complex = filter(s -> length(s) > 1, objects)
			scs = filter(s -> any(t -> s != t && isbelow(s, t), complex), complex)
			scs = union(sc, scs)
			complex = setdiff(complex, sc)
			c = isempty(complex) ? 0 : coassembly(st, complex, scs, cache)
			cc = min(cc, c)
		end
		cc += length(ss)
		cache[(ss, sc)] = cc
	end
end

coassembly(st, ss) = coassembly(st, ss, Set{String}(), Dict{Tuple{Set{String},Set{String}},Int}())

isbelow(s::String, t::String) = !isnothing(findfirst(s, t))
