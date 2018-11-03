defmodule Exredrpc.Broker do
  @moduledoc """
  handles inbound messages from the grpc chat stream
  (a gRPC client connects to the MessageBus service and calls the Chat rpc)
  """

  use GenServer
  require Logger

  #########################
  # API
  #########################

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec bond_ex(String.t(), Exredrpc.Twin.Ex.t()) :: :ok | {:error, term()}
  def bond_ex(bond_id, %Exredrpc.Twin.Ex{} = twin) do
    GenServer.call(__MODULE__, {:bond_ex, bond_id, twin})
  end

  @spec bond_grpc(String.t(), Exredrpc.Twin.Grpc.t()) :: :ok | {:error, term()}
  def bond_grpc(bond_id, %Exredrpc.Twin.Grpc{} = twin) do
    GenServer.call(__MODULE__, {:bond_grpc, bond_id, twin})
  end

  @doc """
  Incoming message from the elixir side.
  Look up the bond struct based on the pid (from)
  and forward message to the GRPC outgoing stream
  """
  @spec msg_from_ex(term) :: term
  def msg_from_ex(msg) do
    GenServer.call(__MODULE__, {:ex_incoming, msg})
  end

  @doc """
  Incoming message from the gRPC side.
  Look up the bond struct based on the pid (from)
  and forward message to the exred node (ex_twin)
  """
  @spec msg_from_ex(Exredrpc.Msg.t()) :: term
  def msg_from_grpc(msg) do
    GenServer.call(__MODULE__, {:grpc_incoming, msg})
  end

  def get_bonds() do
    GenServer.call(__MODULE__, :get_bonds)
  end

  #########################
  # callbacks
  #########################

  @impl true
  def init(_args) do
    Logger.info("Starting Broker...")
    bonds = %{}
    {:ok, bonds}
  end

  @impl true
  def handle_call({:bond_ex, bond_id, ex_twin} = req, _from, bonds) do
    Logger.info("bond request: #{inspect(req)}")
    # find existing bond or create new one
    updated_bond =
      case Map.fetch(bonds, bond_id) do
        {:ok, existing_bond} ->
          # TODO: reject if there's already a valid ex_twin with a pid()
          existing_bond |> Map.put(:ex_twin, ex_twin)

        :error ->
          %Exredrpc.Bond{bond_id: bond_id, ex_twin: ex_twin}
      end

    {:reply, :ok, Map.put(bonds, bond_id, updated_bond)}
  end

  # NOTE: keeping ex and grpc bond calls separate, grpc side will probably have to do
  # authentication and authorization checks
  def handle_call({:bond_grpc, bond_id, grpc_twin} = req, _from, bonds) do
    Logger.info("bond request: #{inspect(req)}")
    # find existing bond or create new one
    updated_bond =
      case Map.fetch(bonds, bond_id) do
        {:ok, existing_bond} ->
          # TODO: reject if there's already a valid ex_twin with a pid()
          existing_bond |> Map.put(:grpc_twin, grpc_twin)

        :error ->
          %Exredrpc.Bond{bond_id: bond_id, grpc_twin: grpc_twin}
      end

    {:reply, :ok, Map.put(bonds, bond_id, updated_bond)}
  end

  def handle_call(:get_bonds, _from, bonds) do
    {:reply, bonds, bonds}
  end

  def handle_call({:ex_incoming, msg}, {from, _ref}, bonds) do
    # TODO: we need a better data structure to store bonds, this lookup takes too long
    IO.inspect(from, label: :from)

    bond =
      bonds
      |> Map.to_list()
      |> Enum.find(fn {_id, b} ->
        b.ex_twin.process == from
      end)

    reply =
      case bond do
        nil ->
          {:error, :nonex_bond}

        {_bond_id, %Exredrpc.Bond{grpc_twin: nil}} ->
          {:error, :nonex_twin}

        {_bond_id, %Exredrpc.Bond{grpc_twin: %Exredrpc.Twin.Grpc{out: grpc_out_stream}}} ->
          # TODO: convert msg to %Exredrpc.Msg{}
          rpcmsg = msg
          GRPC.Server.send_reply(grpc_out_stream, rpcmsg)
          {:ok, :sent}
      end

    {:reply, reply, bonds}
  end

  def handle_call({:grpc_incoming, %Exredrpc.Msg{} = msg}, {from, _ref}, bonds) do
    bond =
      bonds
      |> Map.to_list()
      |> Enum.find(fn {_id, b} ->
        b.grpc_twin.in == from
      end)

    reply =
      case bond do
        nil ->
          {:error, :nonex_bond}

        {_, %Exredrpc.Bond{ex_twin: nil}} ->
          {:error, :nonex_twin}

        {_, %Exredrpc.Bond{ex_twin: %Exredrpc.Twin.Ex{process: ex_node_pid}}} ->
          rpcmsg = msg |> Enum.into(%{})
          send(ex_node_pid, rpcmsg)
          {:ok, :sent}
      end

    {:reply, reply, bonds}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.info("#{inspect(msg)}")
    {:noreply, state}
  end
end
