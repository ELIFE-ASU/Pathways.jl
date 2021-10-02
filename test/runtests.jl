using Pathways, Base.Iterators, Test, Statistics, Printf

const GROUNDTRUTH = joinpath(@__DIR__, "stringpa")
const DISPLAYOFF = "--DisplayOff"
const TMPFILE = joinpath(@__DIR__, "test.txt")
const PATHFILE = joinpath(@__DIR__, "test_pathway.txt")

const NUM_PATHS = r"Number of pathways: (\d+)"
const ASSEMBLY_INDEX = r"Assembly Index = (\d+)"

function stringpa(str::AbstractString)
    expected = -1

    open(TMPFILE, "w") do io
        println(io, str)
    end

    run(`$GROUNDTRUTH $TMPFILE $DISPLAYOFF`)

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

    expected
end

outer(f, iter, n) = map(f ∘ collect, product(fill(iter, n)...))
outer(iter, n) = map(collect, product(fill(iter, n)...))

@time @testset "Assembly" begin
    include("assembly.jl")
end

@time @testset "Shortest Chain" begin
    include("thurber.jl")
end
