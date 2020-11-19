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

config :step_flow, StepFlow.Amqp,
  hostname: "localhost",
  port: 5672,
  username: "guest",
  password: "guest",
  virtual_host: ""

config :step_flow, StepFlow.WorkflowDefinitions.ExternalLoader, specification_folder: "./test/"

config :step_flow, StepFlow.WorkflowDefinitions.WorkflowDefinition,
  workflow_schema_url: "./test/standard/1.8/workflow-definition.schema.json"
