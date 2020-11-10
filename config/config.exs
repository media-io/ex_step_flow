use Mix.Config

config :phoenix, :json_library, Jason

config :step_flow, ecto_repos: [StepFlow.Repo]

config :step_flow, StepFlow,
  exposed_domain_name: {:system, "EXPOSED_DOMAIN_NAME"},
  slack_api_token: {:system, "SLACK_API_TOKEN"}

config :step_flow, StepFlow.WorkflowDefinitions.WorkflowDefinition,
  workflow_schema_url:
    "/home/mathia/work/media-cloud-ai.github.com/standard/1.8/workflow-definition.schema.json"

import_config "#{Mix.env()}.exs"
