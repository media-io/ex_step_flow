use Mix.Config

config :step_flow, StepFlow.Amqp,
  hostname: "localhost",
  port: "5672",
  management_port: "15672",
  username: "mediacloudai",
  password: "mediacloudai",
  virtual_host: "media_cloud_ai_dev"

config :amqp,
  hostname: "localhost",
  port: "5672",
  management_port: "15672",
  username: "mediacloudai",
  password: "mediacloudai",
  virtual_host: "media_cloud_ai_dev"
