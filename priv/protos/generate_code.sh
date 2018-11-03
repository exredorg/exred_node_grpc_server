#!/bin/bash

# generates go and elixir code based on the proto file
#
# this needs the following set up:
# - go: https://github.com/golang/protobuf
# - elixir: https://github.com/tony612/protobuf-elixir

echo -n "Generating elixir code...  "
protoc --elixir_out=plugins=grpc:../../lib/exredrpc/ exredrpc.proto
echo done

echo -n "Generating go code...  "
protoc --go_out=plugins=grpc:../go/exredrpc/ exredrpc.proto
echo done

