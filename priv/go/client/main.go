package main

import (
	pb "client/exredrpc"
	"flag"
	"fmt"
	"io"
	"log"
	"math/rand"
	"time"

	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

const (
	address = "localhost:10001"
)

func init() {
	rand.Seed(time.Now().UnixNano())
}

func randWord(n int) string {
	b := make([]rune, n)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}

var (
	letters = []rune("ABCDEFGHIJKLMNO")

	// channel for exit message
	waitc = make(chan struct{})

	// channels for incoming / outgoing messages
	incoming = make(chan pb.Msg)
	outgoing = make(chan pb.Msg)
)

func main() {
	// read command line flags
	sendMode := flag.Bool("send", false, "Run in send mode")
	receiveMode := flag.Bool("receive", false, "Run in receive mode")
	pingpongMode := flag.Bool("pingpong", false, "Run in ping pong mode")
	bondID := flag.String("bondid", "test", "Specify bondId used when connecting to Exred")
	flag.Parse()

	// set up a connection to the grpc server
	conn, err := grpc.Dial(address, grpc.WithInsecure())
	if err != nil {
		log.Fatalf("cound not connect: %v", err)
	}
	defer conn.Close()

	// get a client for the MessageBus service
	client := pb.NewMessageBusClient(conn)

	// create metadata for the RPC request
	md := metadata.New(map[string]string{"bondId": *bondID})
	ctx := metadata.NewOutgoingContext(context.Background(), md)

	// initiate request
	rpcChatStream, err := client.Chat(ctx)
	if err != nil {
		log.Fatalf("could not get stream: %v", err)
	}

	// start sending and receiving goroutines
	// these transfer messages between the RPC streams and the incoming and outgoing channels
	go receiveMsg(incoming, rpcChatStream)
	go sendMsg(outgoing, rpcChatStream)

	// start go routines to handle incoming messages and/or produce outgoing messages
	if *receiveMode {
		go handleIncoming(incoming)
	} else if *sendMode {
		go sendNonStop(outgoing)
	} else if *pingpongMode {
		go pingPong(incoming, outgoing)
	} else {
		go handleIncoming(incoming)
		sendAndClose(outgoing)
	}

	// wait for RPC call end
	<-waitc
	rpcChatStream.CloseSend()
}

// takes messages from the outgoing channel and sends them out on the gRPC stream
func sendMsg(outChan <-chan pb.Msg, stream pb.MessageBus_ChatClient) {
	for {
		msg, ok := <-outChan
		if !ok { // outgoing channel was closed -> closing stream
			stream.CloseSend()
			break
		}
		err := stream.Send(&msg)
		if err != nil {
			log.Fatalf("Failed to send msg: %v\n", msg)
		}
	}
}

// receive messages from the gRPC stream and publish them to the incoming channnel
func receiveMsg(inChan chan<- pb.Msg, stream pb.MessageBus_ChatClient) {
	for {
		in, err := stream.Recv()
		if err == io.EOF {
			fmt.Println("<<< IN EOF")
			close(waitc)
			return
		}
		if err != nil {
			log.Fatalf("Failed to receive a message: %v\n", err)
		}
		inChan <- *in
	}
}

// sends a few test messages to the outgoing channel and then closes the channel
func sendAndClose(outChan chan<- pb.Msg) {
	messages := []*pb.Msg{
		{Payload: map[string]string{"from": "randWord", "password": randWord(10)}},
		{Payload: map[string]string{"from": "randWord", "password": randWord(20)}},
	}

	for _, msg := range messages {
		outChan <- *msg
		time.Sleep(time.Second)
	}
	close(outChan)
}

// continuously send test messages to the outgoing channel
func sendNonStop(outChan chan<- pb.Msg) {
	for {
		message := pb.Msg{Payload: map[string]string{"from": "randWord", "password": randWord(10)}}
		outChan <- message
		time.Sleep(time.Second)
	}
}

// ping pong
func pingPong(inChan <-chan pb.Msg, outChan chan<- pb.Msg) {
	out := pb.Msg{Payload: map[string]string{"data": "ping"}}

	// keep sending pings until we get an answer
	for len(inChan) == 0 {
		outChan <- out
		fmt.Println(">>> sent: ", out)
		time.Sleep(time.Second)
	}

	// send ping after every pong received
	for {
		in := <-inChan
		fmt.Println("<<< received: ", in)
		data, ok := in.Payload["data"]
		if ok && data == "pong" {
			outChan <- out
			fmt.Println(">>> sent: ", out)
		}
	}
}

// handles incoming messages
func handleIncoming(inChan <-chan pb.Msg) {
	for {
		msg := <-inChan
		fmt.Println("<<< received: ", msg)
	}
}
