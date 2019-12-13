@testset "Readwrite" begin

function generateexamples(f::IO)
    e1 = Example(features=Features(feature=Dict{AbstractString, Feature}("a" => Feature(int64_list=Int64List(value=[1,2,3])))))
    e2 = Example(features=Features(feature=Dict{AbstractString, Feature}("b" => Feature(float_list=FloatList(value=[1.2,3.4,5.6])))))
    e3 = Example(features=Features(feature=Dict{AbstractString, Feature}("c" => Feature(bytes_list=BytesList(value=[Array{UInt8}([100, 101, 102])])))))
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
