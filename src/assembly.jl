using Base.Iterators

const SplitTree = Dict{T, Set{NTuple{2,T}}} where T

function splittree(s::String)
	st = SplitTree{String}()
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

function assembly(st, ss, sc, cache)
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
			c = isempty(complex) ? 0 : assembly(st, complex, scs, cache)
			cc = min(cc, c)
		end
		cc += length(ss)
		cache[(ss, sc)] = cc
	end
end

assembly(st, ss, sc) = assembly(st, ss, sc, Dict{NTuple{2,Set{String}}, Int}())
assembly(st, ss) = assembly(st, ss, Set{String}())

function assembly(s::String...)
	st = merge(Dict{String, Set{NTuple{2,String}}}(), splittree.(s)...)
	ss = Set(s)
	sc = filter(s -> any(t -> s != t && isbelow(s, t), ss), ss)
	ss = setdiff(ss, sc)
	assembly(st, Set(s), sc)
end

isbelow(s::String, t::String) = !isnothing(findfirst(s, t))
