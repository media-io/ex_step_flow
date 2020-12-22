# Step Flow

[![travis-ci.org](https://travis-ci.org/media-io/ex_step_flow.svg?branch=master)](https://travis-ci.org/media-io/ex_step_flow)
[![hex.pm](https://img.shields.io/hexpm/v/step_flow.svg)](https://hex.pm/packages/step_flow)
[![hexdocs.pm](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ex_step_flow/)
[![hex.pm](https://img.shields.io/hexpm/dt/step_flow.svg)](https://hex.pm/packages/step_flow)
[![hex.pm](https://img.shields.io/hexpm/l/step_flow.svg)](https://hex.pm/packages/step_flow)
[![coveralls.io](https://coveralls.io/repos/github/media-io/ex_step_flow/badge.svg?branch=master)](https://coveralls.io/github/media-io/ex_step_flow?branch=master)

Step flow manager for Elixir applications.

## Usage

Add AMQP as a dependency in your `mix.exs` file.

```elixir
def deps do
  [
    {:step_flow, "~> 0.1.0"}
  ]
end
```

And add into extra applications:

```elixir
  def application do
    [
      mod: {MyApplication.Application, []},
      extra_applications: [
        :step_flow
      ]
    ]
  end
```

## Configurations to start

### PostgreSQL configuration

Add into configuration files:

```elixir
config :step_flow, Ecto.Repo,
  hostname: "localhost",
  username: "postgres",
  password: "postgres",
  database: "step_flow_dev",
  runtime_pool_size: 10
```

It can also be used with environment variables:

```elixir
config :step_flow, Ecto.Repo,
  hostname: {:system, "DATABASE_HOSTNAME"},
  username: {:system, "DATABASE_USERNAME"},
  password: {:system, "DATABASE_PASSWORD"},
  database: {:system, "DATABASE_NAME"},
  runtime_pool_size: {:system, "DATABASE_POOL_SIZE"}
```

### RabbitMQ configuration

Add into configuration files:

```elixir
config :step_flow, StepFlow.Amqp,
  hostname: "localhost",
  port: 5672,
  username: "guest",
  password: "guest",
  virtual_host: ""
```

It can also be used with environment variables:

```elixir
config :step_flow, StepFlow.Amqp,
  hostname: {:system, "RABBITMQ_HOSTNAME"},
  port: {:system, "RABBITMQ_PORT"},
  username: {:system, "RABBITMQ_USERNAME"},
  password: {:system, "RABBITMQ_PASSWORD"},
  virtual_host: {:system, "RABBITMQ_VIRTUAL_HOST"},
```

### Slack integration (optional)

Configuring the Slack integration enable notification to Slack channel.
It's used to:
- send notification when job is in error
- send a notification via a Step

To enable integration, update configuration files:
```
config :step_flow, StepFlow,
  exposed_domain_name: {:system, "EXPOSED_DOMAIN_NAME"},
  slack_api_token: {:system, "SLACK_API_TOKEN"},
  slack_api_channel: {:system, "SLACK_API_CHANNEL"}
```

Remarks: the `slack_api_channel` configure the channel for error jobs notification.
The message contains also a link to the workflow, so `exposed_domain_name` configure the hostname of the hosted application.

### Expose StepFlow REST API

Step Flow provides the REST API to manage Workflows and Jobs.

Create a module with:

```elixir
defmodule MyApplicationWeb.StepFlow.Plug do
  @moduledoc false

  use StepFlow.Plug
end
```

Then in Phoenix router redirect the API part to the module:

```elixir
defmodule MyApplicationWeb.Router do
  use MyApplicationWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", MyApplicationWeb do
    pipe_through(:api)

    scope "/step_flow", StepFlow do
      forward("/", Plug)
    end

    # add other routes here
  end
end

```

To enable authentication checks over Step Flow API configure callbacks in configuration:

```elixir
config :step_flow, StepFlow,
  authorize: [
    module: MyApplicationWeb.Authorize,
    get_jobs: [:user_check, :right_technician_check],
    get_workflows: [:user_check, :right_technician_check],
    post_workflows: [:user_check, :right_technician_check],
    put_workflows: [:user_check, :right_technician_check],
    delete_workflows: [:user_check, :right_technician_check],
    post_workflows_events: [:user_check, :right_technician_check],
    get_definitions: [:user_check, :right_technician_check],
    post_worker_definitions: [:user_check, :right_technician_check],
    get_worker_definitions: [:user_check, :right_technician_check],
    get_workflows_statistics: [:user_check]
  ]
```

### Enable StepFlow live notification to WebSocket

StepFlow can be configured to send messages on job updates (to enable refresh of UI via WebSocket for example).
To broadcast messages, the application endpoint needs to be configured.

```elixir
config :step_flow, StepFlow,
  endpoint: MyApplicationWeb.Endpoint
```

### Configuration of the default working directory for workers

Each workers works with big data files, mostly on shared storage.
The default access point need to be configured using:

```elixir
config :step_flow, StepFlow,
  workers_work_directory: "/data/mount/point"
```

### Configuration of the default stepflow schema

A workflow follows a schema definition, this definition can be overloaded with:

```elixir
config :step_flow, StepFlow.WorkflowDefinitions.ExternalLoader, specification_folder: "./mediacloudai/"

config :step_flow, StepFlow.WorkflowDefinitions.WorkflowDefinition,
  workflow_schema_url: "./mediacloudai/standard/1.8/workflow-definition.schema.json"
```

### Prometheus exporter

Configure [prometheus_plugs](https://hexdocs.pm/prometheus_plugs/Prometheus.PlugExporter.html#module-configuration) to export stepflow metrics:
- number of workflows per identifier created in the last 24 hours
- execution time of worflows per identifier of ended worflow in the last 24 hours

```elixir
config :prometheus, StepFlow.Metrics.PrometheusExporter,
  path: "/metrics",
  format: :auto, ## or :protobuf, or :text
  registry: :default,
  auth: false
```

Export endpoint can be optionally secured using HTTP Basic Authentication:

```elixir
  auth: {:basic, "username", "password"}
```

Metrics can be configured with
```elixir
config :step_flow, StepFlow.Metrics,
  scale: "day", # "year", "month", "week", "day", "hour", "minute", "second", "millisecond", and "microsecond"
  delta: -1
```