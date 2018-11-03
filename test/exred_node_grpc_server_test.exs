defmodule Exred.Node.GrpcServerTest do
  use ExUnit.Case
  doctest Exred.Node.GrpcServer

  setup_all do
    GRPC.Server.start([Wtf.Server, Exredgrpc.Server], 10002)
    {:ok, channel} = GRPC.Stub.connect("localhost:10002")
    {:ok, %{ch: channel}}
  end

  test "greets the world" do
    assert Exred.Node.GrpcServer.hello() == :world
  end

  test "wtf test unary grpc", state do
    assert Wtf.TestService.Stub.ask(state.ch, Wtf.Request.new(text: "zsolt")) ==
             {:ok, %Wtf.Reply{text: "zsolt"}}
  end

  test "wtf test bidirectional stream", state do
    stream = state.ch |> Wtf.TestService.Stub.chat()

    requests =
      Enum.map(1..5, fn n ->
        Wtf.Request.new(text: "req-#{n}")
      end)

    task =
      Task.async(fn ->
        Enum.reduce(requests, requests, fn _, [req | tail] ->
          opts = if length(tail) == 0, do: [end_stream: true], else: []
          GRPC.Stub.send_request(stream, req, opts)
          tail
        end)
      end)

    # GRPC.Stub.end_stream(stream)

    {:ok, result_enum} = GRPC.Stub.recv(stream)
    Task.await(task)

    IO.inspect(result_enum, label: "client <~~ ")
    assert length(Enum.to_list(result_enum)) == 5
  end

  test "wtf test bidirectional stream (simple)", state do
    stream = state.ch |> Wtf.TestService.Stub.chat()
    # create requests
    requests =
      Enum.map(1..5, fn n ->
        Wtf.Request.new(text: "req-#{n}")
      end)

    # send requests
    Enum.each(requests, fn req ->
      GRPC.Stub.send_request(stream, req)
    end)

    GRPC.Stub.end_stream(stream)

    # get replies
    {:ok, reply_stream} = GRPC.Stub.recv(stream)

    IO.inspect(reply_stream, label: "client <~~ ")
    assert length(Enum.to_list(reply_stream)) == 5
  end

  test "exredgrpc test bidirectional stream (simple)", state do
    stream = state.ch |> Exredgrpc.NodeConnect.Stub.chat()
    # create requests
    requests =
      Enum.map(1..5, fn n ->
        Exredgrpc.NodeMsg.new(to: "req-#{n}")
      end)

    # send requests
    Enum.each(requests, fn req ->
      GRPC.Stub.send_request(stream, req)
    end)

    GRPC.Stub.end_stream(stream)

    # get replies
    {:ok, reply_stream} = GRPC.Stub.recv(stream)

    IO.inspect(reply_stream, label: "CLIENT <~~ ")
    replies = Enum.to_list(reply_stream)
    Enum.each(replies, &IO.inspect(&1, label: "CLIENT <<< "))
    assert length(replies) == 1
  end
end
