defmodule Exredrpc.Twin.Ex do
  defstruct process: nil

  @type t :: %__MODULE__{
          process: pid()
        }
end

defmodule Exredrpc.Twin.Grpc do
  defstruct in: nil, out: nil

  @type t :: %__MODULE__{
          in: pid(),
          out: GRPC.Server.Stream.t()
        }
end

defmodule Exredrpc.Bond do
  defstruct bond_id: nil, ex_twin: nil, grpc_twin: nil

  @type t :: %__MODULE__{
          bond_id: String.t(),
          ex_twin: Exredrpc.Twin.Ex.t(),
          grpc_twin: Exredrpc.Twin.Grpc.t()
        }
end
