@testset "Parsebuild" begin

using TFRecords: Example, Feature, Features, Int64List, FloatList, BytesList

@testset "int64" begin
    e = Example(features=Features(feature=Dict{AbstractString, Feature}("a" => Feature(int64_list=Int64List(value=[1,2,3])))))
    d = Dict("a" => Array{Int64, 1}([1, 2, 3]))
    @test e == build_example(d)
    @test d == parse_example(e)
end

@testset "float" begin
    e = Example(features=Features(feature=Dict{AbstractString, Feature}("b" => Feature(float_list=FloatList(value=[1.2,3.4,5.6])))))
    d = Dict("b" => Array{Float32, 1}([1.2, 3.4, 5.6]))
    @test e == build_example(d)
    @test d == parse_example(e)
end

@testset "bytes" begin
    e = Example(features=Features(feature=Dict{AbstractString, Feature}("c" => Feature(bytes_list=BytesList(value=[Array{UInt8}([100, 101, 102])])))))
    d = Dict("c" => [Array{UInt8, 1}([100, 101, 102])])
    @test e == build_example(d)
    @test d == parse_example(e)
end 

end
