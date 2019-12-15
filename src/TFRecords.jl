module TFRecords
using ProtoBuf
using CRC32c: crc32c

export TFRecord, Example, SequenceExample, BytesList, FloatList, Int64List
export Feature, Features, FeatureList, FeatureLists
export readexample, writeexample, iterate

# run(ProtoBuf.protoc(`-I=~/src/tensorflow/ --julia_out=src/generated ~/src/tensorflow/tensorflow/core/example/example.proto`))
include("generated/tensorflow.jl")

Example = tensorflow.Example
SequenceExample = tensorflow.SequenceExample
BytesList = tensorflow.BytesList
FloatList = tensorflow.FloatList
Int64List = tensorflow.Int64List
Feature = tensorflow.Feature
Features = tensorflow.Features
FeatureList = tensorflow.FeatureList
FeatureLists = tensorflow.FeatureLists

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

end
