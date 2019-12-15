@testset "Readwrite" begin

function generateexamples(f::IO)
    e1 = build_example(Dict("a" => Array{Int64, 1}([1, 2, 3])))
    e2 = build_example(Dict("b" => Array{Float32, 1}([1.2, 3.4, 5.6])))
    e3 = build_example(Dict("c" => [Array{UInt8, 1}([100, 101, 102])]))

    writeexample(f, e1)
    writeexample(f, e2)
    writeexample(f, e3)
    (e1, e2, e3)
end

@testset "Simple round-trip" begin
    pb = PipeBuffer()
    e1, e2, e3 = generateexamples(pb)
    @test readexample(pb) == e1
    @test readexample(pb) == e2
    @test readexample(pb) == e3
end

@testset "iterator" begin
    tmpname, f = mktemp()
    examples = generateexamples(f)
    close(f)
    records = Iterators.Stateful(TFRecord(tmpname))
    for (a, b) in Iterators.zip(records, examples)
        @test a == b
    end
    @test_throws EOFError popfirst!(records)
end

end
