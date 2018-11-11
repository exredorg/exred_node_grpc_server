defmodule Exred.Node.GrpcServer.MixProject do
  use Mix.Project

  @description "Exred node that sets up a gRPC server. Used with exred_node_grpc_twin"

  def project do
    [
      app: :exred_node_grpc_server,
      version: "0.1.1",
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

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Zsolt Keszthelyi"],
      links: %{
        "GitHub" => "https://github.com/exredorg/exred_node_grpc_twin",
        "Exred" => "http://exred.org"
      },
      files: ["lib", "mix.exs", "README.md", "LICENSE"]
    }
  end
end
