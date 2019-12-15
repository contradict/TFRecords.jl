# TFRecords.jl

Read and write `tf.Example` values from a file. The format is described
[here](https://www.tensorflow.org/tutorials/load_data/tfrecord#tfrecords_format_details).

## Install

    ] add https://github.com/contradict/TFRecords.jl

Installation fetches the `.proto` files defining the data format from the github
Tensorflow repository, so network access is needed to build. See `deps/build.jl`
for the gory details.

## Read

    julia> using TFRecords
    julia> tfrecord_file = TFRecord("filename.tfrecord")
    julia> records = Iterators.Stateful(tfrecord_file)
    julia> record = popfirst!(records)

For convenience, `parseexample` will turn the `Example` structure into a
`Dict{String, Array{T, 1}}` for.

    julia> record_dict = parseexample(record)

## Write

    julia> output_file = open("filename.tfrecord")
    julia> e = buildexample(Dict("value" => Array{Int64, 1}([1])))
    julia> writeexample(outputfile, e)

