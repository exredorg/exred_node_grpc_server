defmodule Exred.Node.GrpcServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :exred_node_grpc_server,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19.0", only: :dev, runtime: false},
      {:exred_library, "~> 0.1"},
      {:stream_split, "~> 0.1.2"},
      {:grpc, github: "tony612/grpc-elixir"},
      {:protobuf, "~> 0.5.3"},
      {:google_protos, "~> 0.1"}
    ]
  end
end
