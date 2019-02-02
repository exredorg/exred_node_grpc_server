defmodule Exredrpc.Server do
  use GRPC.Server, service: Exredrpc.MessageBus.Service
  require Logger

  @spec chat(Enumerable.t(), GRPC.Server.Stream.t()) :: any
  def chat(req_stream, resp_stream) do
    Logger.info("client connected to chat service")
    # GRPC metadata ends up in the request headers. Extract the bond_id the client is sending.
    # TODO why are the headers in the response stream? am I mixing the streams up?
    headers = GRPC.Stream.get_headers(resp_stream)

    case headers do
      %{"bondid" => req_bond_id} ->
        Logger.info("got bond id: #{req_bond_id}")

        # TODO: remove; this is just for debugging
        # send reply back to client
        p = %{"reply" => "trying to bond using id: #{req_bond_id}"}
        r = Exredrpc.Msg.new(to: "client", from: "server", meta: %{}, payload: p)
        GRPC.Server.send_reply(resp_stream, r)
        Logger.info("sent reply: #{inspect(r)}")

        # attempt bonding
        me = %Exredrpc.Twin.Grpc{in: self(), out: resp_stream}
        :ok = Exredrpc.Broker.bond_grpc(req_bond_id, me)

        Logger.info("attempting to bond")

        # receive incoming messages from the stream and send them to the broker
        Enum.each(req_stream, fn req ->
          Logger.info("received: #{inspect(req)}")
          Exredrpc.Broker.msg_from_grpc(req)
        end)

        Logger.info("Chat RPC done")
        :done

      _ ->
        # no bond id in the request -> reject request
        Logger.warn("Client connected without sending \"bondid\" header")
        Logger.warn("Chat RPC done")
        :done
    end
  end
end
