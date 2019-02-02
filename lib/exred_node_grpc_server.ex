defmodule Exred.Node.GrpcServer do
  @moduledoc """
  This is a daemon to that runs a gRPC server and a message
  broker. An external node can connect to the broker via gRPC and handle the messages sent
  to a node placed in a flow.

  The terminology used is that the internal and external nodes are twins
  and they bond using a common bond_id.
  Once the nodes have bonded the broker will start streaming messages between them.
  This means that the internal node can be used in a flow just like any other node but the messages
  will be handled by the external node.
  """

  @name "gRPC Server Daemon"
  @category "daemon"
  @info @moduledoc
  @config %{
    port: %{
      info: "Port that the gRPC server listens on",
      type: "number",
      value: 10001,
      attrs: %{min: 1000, max: 65535}
    }
  }
  @ui_attributes %{right_icon: "loop"}

  use Exred.NodePrototype

  @impl true
  def daemon_child_specs(config) do
    [
      # {GRPC.Server.Supervisor, {Exredrpc.Server, config.port.value}},
      {GRPC.Server.Supervisor, {Exredrpc.Server, 10001}},
      Exredrpc.Broker
    ]
  end

  @doc """
  start/0 is only used for testing when we need to manually start up the node
  """
  def start do
    children = [
      Exredrpc.Broker,
      {GRPC.Server.Supervisor, {Exredrpc.Server, 10001}}
    ]

    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
  end
end
