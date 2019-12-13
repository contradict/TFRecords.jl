using ProtoBuf

tempdir = mktempdir()
example_path = "tensorflow/core/example"
exampledir = "$tempdir/$example_path"
mkpath(exampledir)
tensorflow_repo_url="https://raw.githubusercontent.com/tensorflow/tensorflow"
tensorflow_tag="v1.15.0"
tensorflow_example_url="$tensorflow_repo_url/$tensorflow_tag/$example_path"
download("$tensorflow_example_url/feature.proto", "$exampledir/feature.proto")
download("$tensorflow_example_url/example.proto", "$exampledir/example.proto")
run(ProtoBuf.protoc(`-I=$tempdir --julia_out=../src/generated $exampledir/example.proto`))
