defmodule Exred.Node.GrpcServer.MixProject do
  use Mix.Project

  @description "Exred node that sets up a gRPC server. Used with exred_node_grpc_twin"
  @version File.read!("VERSION") |> String.trim()

  def project do
    [
      app: :exred_node_grpc_server,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      description: @description,
      package: package(),
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
      {:exred_nodeprototype, "~> 0.2"},
      {:exredrpc, "~> 0.1"},
      {:stream_split, "~> 0.1.2"},
      {:grpc, "~> 0.3.1"},
      {:protobuf, "~> 0.5.3"},
      {:google_protos, "~> 0.1"},
      {:exred_nodetest, "~> 0.1.0", only: :test}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Zsolt Keszthelyi"],
      links: %{
        "GitHub" => "https://github.com/exredorg/exred_node_grpc_server.git",
        "Exred" => "http://exred.org"
      },
      files: ["lib", "mix.exs", "README.md", "LICENSE", "VERSION"]
    }
  end
end
