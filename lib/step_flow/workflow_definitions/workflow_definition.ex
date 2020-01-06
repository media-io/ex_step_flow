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

  defp get_schema do
    "https://media-cloud.ai/standard/1.0/workflow-definition.json"
    |> HTTPoison.get!()
    |> Map.get(:body)
    |> Jason.decode!()
  end
end
