defmodule StepFlow.WorkflowDefinitions.WorkflowDefinition do
  @moduledoc """
  The WorkflowDefinition context.
  """

  require Logger

  defstruct(
    identifier: "",
    parameters: []
  )

  def valid?(definition) do
    get_schema()
    |> ExJsonSchema.Validator.valid?(definition)
  end

  def validate(definition) do
    get_schema()
    |> ExJsonSchema.Validator.validate(definition)
  end

  defp get_schema do
    "https://media-cloud.ai/standard/1.0/workflow-definition.schema.json"
    |> HTTPoison.get!()
    |> Map.get(:body)
    |> Jason.decode!()
  end

  def get_workflow_definition_directories do
    case Application.get_env(:step_flow, :workflow_definition) do
      {:system, key} ->
        System.get_env(key)
        |> String.split(get_separator())

      key when is_list(key) ->
        key

      key when is_bitstring(key) ->
        [key]

      key ->
        Logger.info("unable to use #{inspect(key)} to list directory")
        []
    end
  end

  defp get_separator do
    if :os.type() |> elem(0) == :unix do
      ":"
    else
      ";"
    end
  end
end
