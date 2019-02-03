defmodule Exred.Node.GrpcServerTest do
  use ExUnit.Case
  doctest Exred.Node.GrpcServer

  use Exred.NodeTest, module: Exred.Node.GrpcServer

  setup_all do
    ctx = start_node()
    {:ok, channel} = GRPC.Stub.connect("localhost:#{inspect(ctx[:node].config.port.value)}")
    Keyword.put(ctx, :ch, channel)
  end

  test "create new message" do
    p = Exredrpc.Msg.new(payload: %{"A" => "B"}, meta: %{"C" => "D"})
    assert %Exredrpc.Msg{} = p
  end

  test "get stream", ctx do
    stream = Exredrpc.MessageBus.Stub.chat(ctx.ch)
    log("STREAM: #{inspect(stream)}")
    assert %GRPC.Client.Stream{} = stream
  end

  test "send through stream", ctx do
    msg = Exredrpc.Msg.new(payload: %{"name" => "Joe"}, meta: %{"date" => "2019-12-12"})

    resp_stream =
      ctx.ch
      |> Exredrpc.MessageBus.Stub.chat(metadata: %{"bondid" => "test"})
      |> GRPC.Stub.send_request(msg)
      |> GRPC.Stub.end_stream()

    resp = GRPC.Stub.recv(resp_stream)
    assert {:ok, result_enum} = resp

    result_enum
    |> Enum.each(fn r ->
      log("Received: #{inspect(r)}")
    end)
  end

  test "go client" do
    cmd = Path.join([:code.priv_dir(:exred_node_grpc_server), "go", "client", "rpcclient"])
    {stdout, exit_code} = System.cmd(cmd, [])
    log(stdout)
    assert exit_code == 0
  end
end
