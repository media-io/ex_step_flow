use Mix.Config

config :logger, :console, format: "[$level] $message\n"
config :logger, level: :error

config :plug, :validate_header_keys_during_test, true

config :step_flow, StepFlow,
  workers_work_directory: "/test_work_dir",
  workflow_definition: "./test/definitions"

config :step_flow, StepFlow.Repo,
  hostname: "localhost",
  port: 5432,
  username: "postgres",
  password: "postgres",
  database: "step_flow_test",
  pool_size: 10,
  pool: Ecto.Adapters.SQL.Sandbox

# config :step_flow, StepFlow.Amqp,
#   hostname: "localhost",
#   port: 5672,
#   username: "guest",
#   password: "guest",
#   virtual_host: ""

config :step_flow, StepFlow.Amqp,
  hostname: "192.168.99.101",
  port: 5678,
  username: "mediacloudai",
  password: "mediacloudai",
  virtual_host: "media_cloud_ai_dev"
