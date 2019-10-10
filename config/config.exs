use Mix.Config

config :phoenix, :json_library, Jason

config :step_flow, Ecto.Repo,
  hostname: "localhost",
  username: "postgres",
  password: "postgres",
  database: "step_flow_dev",
  pool_size: 10
