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
    Application.get_env(:step_flow, StepFlow)
    |> Keyword.get(:workflow_definition)
    |> case do
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

  def get_workflows do
    get_workflow_definition_directories()
    |> Enum.map(fn directory ->
      list_workflow_definitions_for_a_directory(directory)
    end)
    |> List.flatten()
  end

  defp get_separator do
    if :os.type() |> elem(0) == :unix do
      ":"
    else
      ";"
    end
  end

  defp list_workflow_definitions_for_a_directory(directory) do
    File.ls!(directory)
    |> Enum.filter(fn filename ->
      String.ends_with?(filename, ".json")
    end)
    |> Enum.map(fn filename ->
      Path.join(directory, filename)
      |> File.read!()
      |> Jason.decode!()
    end)
    |> Enum.filter(fn workflow_definition ->
      if valid?(workflow_definition) do
        true
      else
        errors = validate(workflow_definition)
        Logger.error("Workflow definition not valid: #{inspect(errors)}")
        false
      end
    end)
  end
end
