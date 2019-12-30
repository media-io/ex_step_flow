defmodule StepFlow.WorkflowDefinition do
  @moduledoc """
  The WorkflowDefinition context.
  """

  def valid?(definition) do
    get_schema()
    |> ExJsonSchema.Validator.valid?(definition)
  end

  def validate(definition) do
    get_schema()
    |> ExJsonSchema.Validator.validate(definition)
  end

  defp get_schema() do
    "https://media-cloud.ai/workflow-definition.json"
    |> HTTPoison.get!
    |> Map.get(:body)
    |> Jason.decode!
  end

  # defp get_schema() do
  #   schema =
  #     "workflow-definition.json"
  #     |> File.read!
  #     |> Jason.decode!
  # end
end
