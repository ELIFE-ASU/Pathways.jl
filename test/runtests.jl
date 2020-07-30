using Pathways, Base.Iterators, Test, Statistics, Printf

const GROUNDTRUTH = joinpath(@__DIR__, "stringpa")
const DISPLAYOFF = "--DisplayOff"
const TMPFILE = joinpath(@__DIR__, "test.txt")
const PATHFILE = joinpath(@__DIR__, "test_pathway.txt")

const CHARS = 'a':'b'

const NUM_PATHS = r"Number of pathways: (\d+)"
const ASSEMBLY_INDEX = r"Assembly Index = (\d+)"

function pathways(str::AbstractString)
    elapsed = @elapsed begin
        actual = assembly(str)
    end
    actual, elapsed
end

function stringpa(str::AbstractString)
    expected = -1

    open(TMPFILE, "w") do io
        println(io, str)
    end

    elapsed = @elapsed run(`$GROUNDTRUTH $TMPFILE $DISPLAYOFF`)

    expected = -1
    for line in readlines(PATHFILE)
        m = match(NUM_PATHS, line)
        if m !== nothing && parse(Int, m[1]) == 0
            expected = length(str) - 1;
            break
        end

        m = match(ASSEMBLY_INDEX, line)
        if m !== nothing
            expected = parse(Int, m[1])
        end
    end

    expected, elapsed
end

outer(f, iter, n) = map(f ∘ collect, product(fill(iter, n)...))
outer(iter, n) = map(collect, product(fill(iter, n)...))

for n in 3:10
    elapsed = []
    for str in outer(join, CHARS, n)
        actual, time1 = pathways(str)
        expected, time2 = stringpa(str)

        push!(elapsed, (n, time1, time2, time1/time2))

		try
        	@test actual == expected
        catch e
        	println(str)
        	rethrow(e)
        end
    end
    (min, max), med, μ = extrema(last.(elapsed)), median(last.(elapsed)), mean(last.(elapsed))
    @printf "%2d %0.5f %0.5f %0.5f %0.5f\n" n min med μ max
end

rm.(["test.txt", "test_pathway.txt"])

