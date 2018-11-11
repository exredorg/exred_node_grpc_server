config :logger, :console,
  format: "[$level] $metadata$message\n",
  metadata: [:module, :function]

config :grpc, start_server: true

config :exred_library, :psql_conn,
  username: "exred_user",
  password: "hello",
  database: "exred_ui_dev",
  hostname: "localhost",
  port: 5432
