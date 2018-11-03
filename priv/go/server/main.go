package main

import (
	"fmt"
	"io"
	"log"
	"net" // "golang.org/x/net/context"
	pb "server/exredrpc"

	"google.golang.org/grpc"
)

type server struct{}

func (s *server) Chat(stream pb.MessageBus_ChatServer) error {
	for {
		in, err := stream.Recv()
		if err == io.EOF {
			fmt.Println("<<< EOF")
			return nil
		}
		if err != nil {
			return err
		}
		fmt.Printf("<<< to: %v from: %v\n", in.To, in.From)
		reply := pb.Msg{
			To:      in.From,
			From:    "server",
			Payload: map[string]string{"reply": "ack"},
		}
		stream.Send(&reply)
	}
}

func main() {
	// ctx := context.Background()

	lis, err := net.Listen("tcp", "localhost:10001")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	s := grpc.NewServer()
	pb.RegisterMessageBusServer(s, &server{})
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
