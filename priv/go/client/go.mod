module rpcclient

require (
	client/exredrpc v0.0.0
	golang.org/x/net v0.0.0-20181023162649-9b4f9f5ad519
	google.golang.org/grpc v1.16.0
)

replace client/exredrpc => ../exredrpc
