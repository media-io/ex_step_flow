use Mix.Config

config :logger, :console, format: "[$level] $message\n"
config :logger, level: :error

config :plug, :validate_header_keys_during_test, true

config :step_flow, StepFlow,
  workers_work_directory: "/test_work_dir",
  workflow_definition: "./test/definitions",
  enable_metrics: true

config :step_flow, StepFlow.Metrics,
  scale: "day",
  delta: -1

config :step_flow, StepFlow.Repo,
  hostname: "localhost",
  port: 5432,
  username: "postgres",
  password: "postgres",
  database: "step_flow_test",
  pool_size: 10,
  pool: Ecto.Adapters.SQL.Sandbox

config :step_flow, StepFlow.Amqp,
  hostname: "localhost",
  port: 5672,
  username: "guest",
  password: "guest",
  virtual_host: ""

config :step_flow, StepFlow.Workflows, time_interval: 1
