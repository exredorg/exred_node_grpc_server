module rpcserver

require (
	golang.org/x/net v0.0.0-20181023162649-9b4f9f5ad519
	google.golang.org/grpc v1.16.0
	server/exredrpc v0.0.0
)

replace server/exredrpc => ../exredrpc
