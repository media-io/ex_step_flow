use Mix.Config

config :logger, :console, format: "[$level] $message\n"
config :logger, level: :error

config :plug, :validate_header_keys_during_test, true

config :step_flow,
  work_dir: "/test_work_dir",
  workflow_definition: "./test/definitions"

config :step_flow, StepFlow.Repo,
  hostname: "localhost",
  username: "postgres",
  password: "postgres",
  database: "step_flow_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :amqp,
  hostname: "192.168.99.101",
  port: "5678",
  username: "mediacloudai",
  password: "mediacloudai",
  virtual_host: "test"
