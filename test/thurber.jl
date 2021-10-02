@testset "Integers" begin
    let table = [0, 1, 2, 2, 3, 3, 4, 3, 4, 4,
                 5, 4, 5, 5, 5, 4, 5, 5, 6, 5,
                 6, 6, 6, 5, 6, 6, 6, 6, 7, 6,
                 7, 5, 6, 6, 7, 6, 7, 7, 7, 6,
                 7, 7, 7, 7, 7, 7, 8, 6, 7, 7,
                 7, 7, 8, 7, 8, 7, 8, 8, 8, 7,
                 8, 8, 8, 6, 7, 7, 8, 7, 8, 8,
                 9, 7, 8, 8, 8, 8, 8, 8, 9, 7,
                 8, 8, 8, 8, 8, 8, 9, 8, 9, 8,
                 9, 8, 9, 9, 9, 7, 8, 8, 8, 8]

        for (n, expected) in enumerate(table)
            try
                @test first(shortestchain(n)) == expected
            catch
                @error "Test failed on" n
                rethrow
            end
        end
    end

    let table = [1, 2, 3, 5, 7, 11, 19, 29, 47, 71, 127, 191, 379, 607]
        for (i, n) in enumerate(table)
            expected = i - 1
            try
                @test first(shortestchain(n)) == expected
            catch
                @error "Test failed on" n
                rethrow
            end
        end

        for i in 2:10, n in table[i-1]:table[i]-1
            expected = i - 1
            try
                @test first(shortestchain(n)) < expected
            catch
                @error "Test failed on" n
                rethrow
            end
        end
    end
end
