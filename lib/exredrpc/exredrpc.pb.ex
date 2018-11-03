defmodule Exredrpc.Msg do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          payload: %{String.t() => String.t()},
          meta: %{String.t() => String.t()}
        }
  defstruct [:payload, :meta]

  field :payload, 2, repeated: true, type: Exredrpc.Msg.PayloadEntry, map: true
  field :meta, 3, repeated: true, type: Exredrpc.Msg.MetaEntry, map: true
end

defmodule Exredrpc.Msg.PayloadEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule Exredrpc.Msg.MetaEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule Exredrpc.MessageBus.Service do
  @moduledoc false
  use GRPC.Service, name: "exredrpc.MessageBus"

  rpc :Chat, stream(Exredrpc.Msg), stream(Exredrpc.Msg)
end

defmodule Exredrpc.MessageBus.Stub do
  @moduledoc false
  use GRPC.Stub, service: Exredrpc.MessageBus.Service
end
