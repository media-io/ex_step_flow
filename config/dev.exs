use Mix.Config

config :step_flow, Ecto.Repo,
  hostname: "localhost",
  username: "postgres",
  password: "postgres",
  database: "step_flow_dev",
  runtime_poll_size: 10

config :logger, :console, format: "[$level] $message\n"
config :logger, level: :debug
