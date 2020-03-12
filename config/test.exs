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
  hostname: "localhost",
  username: "guest",
  password: "guest",
  virtual_host: ""