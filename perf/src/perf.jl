using CSV, DataFrames, Pathways, Statistics

function sa(str::String)
    time = @elapsed begin
        c = assembly(str)
    end
    c, time
end

df = CSV.File("data/str_sa.csv") |> DataFrame
select!(df, :string, :nLetters, :nSeqs, :SA, :nPaths, :runtime)
rename!(df, Dict(:runtime => :runtime_sa))
sort!(df, :nLetters)
filter!(r -> r.nLetters < 17, df)
df.SA .-= Int.(df.nPaths .== 0)

asa = Tuple{Int,Float64}[]
@time for (n, str) in enumerate(df.string)
    println(n, "\t", str)
    push!(asa, sa(str))
end

df.ASA = first.(asa)
df.runtime_asa = last.(asa)

δ = df.SA - df.ASA
@show extrema(δ)
@show mean(δ) std(δ)

CSV.write("data/sa_asa.csv", df)
