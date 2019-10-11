use Mix.Config

config :phoenix, :json_library, Jason

config :step_flow, ecto_repos: [StepFlow.Repo]

import_config "#{Mix.env()}.exs"
