@testset "Integers" begin
    let table = [0, 1, 2, 2, 3, 3, 4, 3, 4, 4,
                 5, 4, 5, 5, 5, 4, 5, 5, 6, 5,
                 6, 6, 6, 5, 6, 6, 6, 6, 7, 6,
                 7, 5, 6, 6, 7, 6, 7, 7, 7, 6,
                 7, 7, 7, 7, 7, 7, 8, 6, 7, 7]

        for (n, expected) in enumerate(table)
            try
                @test assembly(n) == expected
            catch
                @error "Test failed on" n
                rethrow
            end
        end
    end
end

@testset "Strings" begin
    try
        for n in 2:8
            elapsed = []
            for str in outer(join, 'a':'b', n)
                try
                    @test assembly(str) == stringpa(str)
                catch
                    @error "Test failed on" str
                    rethrow
                end
            end
        end
    finally
        rm.(["test.txt", "test_pathway.txt"])
    end
end
