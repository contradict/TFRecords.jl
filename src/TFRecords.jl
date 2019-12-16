module TFRecords
using ProtoBuf
using CRC32c: crc32c

export TFRecord, readexample, writeexample, iterate, parse_example, build_example

# run(ProtoBuf.protoc(`-I=~/src/tensorflow/ --julia_out=src/generated ~/src/tensorflow/tensorflow/core/example/example.proto`))
include("generated/tensorflow.jl")

Example = tensorflow.Example
Feature = tensorflow.Feature
Features = tensorflow.Features
BytesList = tensorflow.BytesList
FloatList = tensorflow.FloatList
Int64List = tensorflow.Int64List

struct TFRecord
    filename::String
end

# https://www.tensorflow.org/tutorials/load_data/tfrecord#tfrecords_format_details
masked_crc(crc::UInt32) = ((crc >> 15) | (crc<<17)) + 0xa282ead8

lengthcrc(l::UInt64) = crc32c([x for x in reinterpret(UInt8, [l])])

"""
    readexample(f)

Read one Example proto from an IOStream, verifying checksum along the way.
"""
function readexample(s::IO)
    length = read(s, UInt64)
    length_crc = read(s, UInt32)
    computed_length_crc = masked_crc(lengthcrc(length))
    @assert(computed_length_crc == length_crc)

    data = read(s, length)
    computed_data_crc = masked_crc(crc32c(data))

    data_crc = read(s, UInt32)
    @assert(computed_data_crc == data_crc)

    iob = PipeBuffer(data)
    readproto(iob, Example())
end

"""
    writeexample(s, e)

Write one Example proto to an IOStream in the tfrecord format.
"""
function writeexample(s::IO, e::Example)
    iob = PipeBuffer()
    writeproto(iob, e)
    length = UInt64(iob.size)
    w = write(s, length)
    w += write(s, masked_crc(lengthcrc(length)))
    w += write(s, iob.data)
    w += write(s, masked_crc(crc32c(iob.data)))
end

"""
    iterate(r)

Iterate over a tfrecord file and produce one example at a time.

# Example
```julia-repl
julia> r = TFRecord("data.tfrecord")
TFRecord("data.tfrecord")
julia> records = Base.Iterators.Stateful(r)
Base.Iterators.Stateful{ ...
julia> record = popfirst!(records)
TFRecords.tensorflow.Example(TFRecords.tensorflow.Features(Dict{AbstractString,TFRecords.tensorflow.Feature} ...
```
"""
function Base.iterate(R::TFRecord, state::Union{Nothing,IO}=nothing)
    if state == nothing
        state = open(R.filename)
    end
    try
        (readexample(state), state)
    catch err
        if isa(err, EOFError)
            nothing
        else
            rethrow()
        end
    end
end

"""
    woo(f)

Extract the defined alternative value from the protobuf.
"""
function woo(f::Feature)
    woo = which_oneof(f, :kind)
    if woo == :bytes_list
        f.bytes_list.value
    elseif woo == :int64_list
        f.int64_list.value
    elseif woo == :float_list
        f.float_list.value
    end
end

"""
    parse_example(e)

Convert the ProtoBuf Example into a Dict{String,Array{T, 1}} with an entry for
each defined feature
"""
function parse_example(e::Example)
    feature_keys = e.features.feature.keys
    defined_keys = [feature_keys[i] for i in 1:length(feature_keys) if isassigned(feature_keys, i)]
    Dict(k=>woo(e.features.feature[k]) for k in defined_keys)
end


make_feature(f::Array{Array{UInt8, 1},1}) = Feature(bytes_list=BytesList(value=f))
make_feature(f::Array{Int64, 1}) = Feature(int64_list=Int64List(value=f))
make_feature(f::Array{Float32, 1}) = Feature(float_list=FloatList(value=f))
PossibleFeatureType = Union{Int64, Float32, Array{UInt8, 1}}

"""
    build_example(d)

Convert a dict like the one returned by parse_example into an Example for
serialization to a file
"""
build_example(d::Dict{T, Array{U, 1}} where {T<:AbstractString, U<:PossibleFeatureType}) = Example(features=Features(feature=Dict{AbstractString, Feature}(k => make_feature(v) for (k, v) in d)))

end
