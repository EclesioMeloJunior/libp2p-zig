proto:
	protoc --plugin=zig-protobuf/zig-out/bin/protoc-gen-zig --zig_out=src/crypto/generated src/crypto/proto/key.proto