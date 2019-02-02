use Mix.Config

config :logger,
  level: :debug

config :logger, :console,
  format: "[$level] $metadata$message\n",
  metadata: [:module, :function]

config :grpc, start_server: true
