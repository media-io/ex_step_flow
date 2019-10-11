use Mix.Config

config :logger, :console, format: "[$level] $message\n"
config :logger, level: :error

config :plug, :validate_header_keys_during_test, true

config :step_flow, StepFlow.Repo,
  hostname: "localhost",
  username: "postgres",
  password: "postgres",
  database: "step_flow_test",
  pool: Ecto.Adapters.SQL.Sandbox
