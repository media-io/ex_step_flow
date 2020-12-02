defmodule StepFlow.Step.LaunchParams do
  @moduledoc """
  The Step launching parameters.
  """
  require Logger

  alias StepFlow.Step.LaunchParams

  defstruct [:workflow, :step, :dates, required_file: nil, segment: nil]

  def new(workflow, step, dates) do
    %LaunchParams{workflow: workflow, step: step, dates: dates}
  end

  def new(workflow, step, dates, required_file) do
    %LaunchParams{workflow: workflow, step: step, dates: dates, required_file: required_file}
  end

  def get_step_id(params) do
    StepFlow.Map.get_by_key_or_atom(params.step, :id)
  end

  def get_step_name(params) do
    StepFlow.Map.get_by_key_or_atom(params.step, :name)
  end

  def get_step_parameter(params, key) do
    StepFlow.Map.get_by_key_or_atom(params.step, :parameters)
    |> Enum.filter(fn param ->
      StepFlow.Map.get_by_key_or_atom(param, :id) == key
    end)
    |> List.first()
  end
end
