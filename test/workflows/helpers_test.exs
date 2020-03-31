defmodule StepFlow.HelpersTest do
  use ExUnit.Case
  use Plug.Test

  require Logger
  alias StepFlow.Amqp.Helpers
  alias StepFlow.Jobs.Status
  alias StepFlow.Workflows
  alias StepFlow.WorkflowDefinitions.WorkflowDefinition

  doctest StepFlow.Step.Helpers

  def port_format(port) when is_integer(port) do
    Integer.to_string(port)
  end

  def port_format(port) do
    port
  end

  defp clean_queue(channel, queue) do
    case AMQP.Basic.get(channel, queue) do
      {:ok, _, %{delivery_tag: delivery_tag}} ->
        AMQP.Basic.ack(channel, delivery_tag)
        clean_queue(channel, queue)

      _ ->
        :ok
    end
  end

  def get_amqp_connection do
    url = Helpers.get_amqp_connection_url()
    {:ok, connection} = AMQP.Connection.open(url)
    {:ok, channel} = AMQP.Channel.open(connection)

    clean_queue(channel, "job_queue_not_found")

    channel
  end

  def validate_message_format(%{"job_id" => job_id, "parameters" => parameters})
      when is_integer(job_id) and is_list(parameters) do
    Enum.map(parameters, fn parameter -> validate_parameter(parameter) end)
    |> Enum.filter(fn x -> x == false end)
    |> length == 0
  end

  def validate_message_format(%{job_id: job_id, parameters: parameters})
      when is_integer(job_id) and is_list(parameters) do
    Enum.map(parameters, fn parameter -> validate_parameter(parameter) end)
    |> Enum.filter(fn x -> x == false end)
    |> length == 0
  end

  def validate_message_format(_), do: false

  defp validate_parameter(%{"id" => id, "type" => "string", "value" => value})
       when is_bitstring(id) and is_bitstring(value) do
    true
  end

  defp validate_parameter(%{id: id, type: "string", value: value})
       when is_bitstring(id) and is_bitstring(value) do
    true
  end

  defp validate_parameter(%{"id" => id, "type" => "credential", "value" => value})
       when is_bitstring(id) and is_bitstring(value) do
    true
  end

  defp validate_parameter(%{id: id, type: "credential", value: value})
       when is_bitstring(id) and is_bitstring(value) do
    true
  end

  defp validate_parameter(%{"id" => id, "type" => "boolean", "value" => value})
       when is_bitstring(id) and is_boolean(value) do
    true
  end

  defp validate_parameter(%{id: id, type: "boolean", value: value})
       when is_bitstring(id) and is_boolean(value) do
    true
  end

  defp validate_parameter(%{"id" => id, "type" => "integer", "value" => value})
       when is_bitstring(id) and is_integer(value) do
    true
  end

  defp validate_parameter(%{id: id, type: "integer", value: value})
       when is_bitstring(id) and is_integer(value) do
    true
  end

  defp validate_parameter(%{"id" => id, "type" => "requirements", "value" => %{"paths" => paths}})
       when is_bitstring(id) and is_list(paths) do
    true
  end

  defp validate_parameter(%{id: id, type: "requirements", value: %{"paths" => paths}})
       when is_bitstring(id) and is_list(paths) do
    true
  end

  defp validate_parameter(%{"id" => id, "type" => "requirements", "value" => %{}})
       when is_bitstring(id) do
    true
  end

  defp validate_parameter(%{id: id, type: "requirements", value: %{}})
       when is_bitstring(id) do
    true
  end

  defp validate_parameter(%{"id" => id, "type" => "array_of_strings", "value" => paths})
       when is_bitstring(id) and is_list(paths) do
    true
  end

  defp validate_parameter(%{id: id, type: "array_of_strings", value: paths})
       when is_bitstring(id) and is_list(paths) do
    true
  end

  defp validate_parameter(%{
         "id" => id,
         "type" => "filter",
         "value" => %{"ends_with" => ends_with}
       })
       when is_bitstring(id) and is_bitstring(ends_with) do
    true
  end

  defp validate_parameter(_) do
    false
  end

  def check(workflow_id, total) do
    all_jobs =
      StepFlow.Jobs.list_jobs(%{
        "workflow_id" => workflow_id |> Integer.to_string(),
        "size" => 50
      })
      |> Map.get(:data)

    assert length(all_jobs) == total
  end

  def check(workflow_id, type, total) do
    all_jobs = get_jobs(workflow_id, type)

    assert length(all_jobs) == total
  end

  def complete_jobs(workflow_id, type) do
    all_jobs = get_jobs(workflow_id, type)

    for job <- all_jobs do
      Status.set_job_status(job.id, Status.state_enum_label(:completed))
    end

    all_jobs
  end

  def get_jobs(workflow_id, type) do
    StepFlow.Jobs.list_jobs(%{
      "job_type" => type,
      "workflow_id" => workflow_id |> Integer.to_string(),
      "size" => 50
    })
    |> Map.get(:data)
  end

  def set_output_files(workflow_id, type, paths) do
    all_jobs =
      StepFlow.Jobs.list_jobs(%{
        "job_type" => type,
        "workflow_id" => workflow_id |> Integer.to_string(),
        "size" => 50
      })
      |> Map.get(:data)

    for job <- all_jobs do
      params =
        job.parameters ++
          [
            %{
              "id" => "destination_paths",
              "type" => "array_of_strings",
              "value" => paths
            }
          ]

      StepFlow.Jobs.update_job(job, %{parameters: params})
    end
  end

  def consume_messages(channel, queue, count) do
    list =
      Enum.map(1..count, fn _x ->
        {:ok, payload, %{delivery_tag: delivery_tag}} = AMQP.Basic.get(channel, queue)
        AMQP.Basic.ack(channel, delivery_tag)
        assert StepFlow.HelpersTest.validate_message_format(Jason.decode!(payload))
        payload |> Jason.decode!()
      end)

    {:empty, %{cluster_id: ""}} = AMQP.Basic.get(channel, queue)
    list
  end

  def workflow_fixture(workflow_definition, attrs \\ %{}) do
    :ok = workflow_definition
      |> Jason.encode!
      |> Jason.decode!
      |> WorkflowDefinition.validate()

    {:ok, workflow} =
      attrs
      |> Enum.into(workflow_definition)
      |> Workflows.create_workflow()

    workflow
  end
end
