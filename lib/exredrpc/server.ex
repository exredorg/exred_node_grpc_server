defmodule Exredrpc.Server do
  use GRPC.Server, service: Exredrpc.MessageBus.Service
  require Logger

  @spec chat(Enumerable.t(), GRPC.Server.Stream.t()) :: any
  def chat(req_stream, resp_stream) do
    # GRPC metadata ends up in the request headers. Extract the bond_id the client is sending.
    headers = GRPC.Stream.get_headers(resp_stream)
    %{"bondid" => req_bond_id} = headers

    # TODO: remove; this is just for debugging
    # send reply back to client
    p = %{"reply" => "trying to bond using id: #{req_bond_id}"}
    r = Exredrpc.Msg.new(to: "client", from: "server", meta: %{}, payload: p)
    GRPC.Server.send_reply(resp_stream, r)

    # attempt bonding
    me = %Exredrpc.Twin.Grpc{in: self(), out: resp_stream}
    :ok = Exredrpc.Broker.bond_grpc(req_bond_id, me)

    # receive incoming messages from the stream and send them to the broker
    Enum.each(req_stream, fn req ->
      Logger.info("IN  #{inspect(req)}")
      send Exredrpc.Broker, req
    end)

    IO.puts("Chat rpc DONE")
    :ok
  end

end
