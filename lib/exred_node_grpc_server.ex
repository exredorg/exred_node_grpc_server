defmodule Exred.Node.GrpcServer do
  @moduledoc """
  This is a daemon to that runs a gRPC server and a message
  broker an external node thorugh gRPC to an internal representation that can be
  placed in a flow.

  The terminology used is that the internal and external nodes are twins
  and they bond using a common bond_id.
  Once the nodes have bonded the broker will start streaming messages between them.
  This means that the internal node can be used in a flow just like any other node but the messages
  will be handled by the external node.
  """

  # this is only used for testing when we need to manually start up the node
  def start do
    children = [
      Exredrpc.Broker,
      {GRPC.Server.Supervisor, {Exredrpc.Server, 10001}}
    ]

    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
  end

  @name "gRPC Server Daemon"
  @category "daemon"
  @info @moduledoc
  @config %{}
  @ui_attributes %{right_icon: "loop"}

  alias Exred.Scheduler.DaemonNodeSupervisor

  use Exred.Library.NodePrototype
  require Logger

  @impl true
  def node_init(state) do
    # start gRPC server
    grpc_server_spec = {GRPC.Server.Supervisor, {Exredrpc.Server, 10001}}

    case DaemonNodeSupervisor.start_child(grpc_server_spec) do
      {:ok, _pid} ->
        Logger.info("started gRPC server on port 10001")
        :ok

      {:error, {:already_started, _pid}} ->
        Logger.warn("tried to start gRPC server: already running on port 10001")
        :ok

      {:error, reason} ->
        error_msg = "failed to start gRPC server: #{inspect(reason)}"
        event = %{node_id: state.node_id, node_name: @name, debug_data: %{msg: error_msg}}
        EventChannelClient.broadcast("notification", event)
    end

    # start message broker
    case DaemonNodeSupervisor.start_child(Exredrpc.Broker) do
      {:ok, _pid} ->
        Logger.info("started RPC Broker")
        :ok

      {:error, {:already_started, _pid}} ->
        Logger.warn("tried to start RPC Broker: already running")
        :ok

      {:error, reason} ->
        error_msg = "failed to start RPC Broker: #{inspect(reason)}"
        event = %{node_id: state.node_id, node_name: @name, debug_data: %{msg: error_msg}}
        EventChannelClient.broadcast("notification", event)
    end

    state
  end
end
