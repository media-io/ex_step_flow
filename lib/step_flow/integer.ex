defmodule StepFlow.Integer do
  @moduledoc false

  @doc ~S"""
  Convert to integer if needed

  ## Examples

      iex> StepFlow.Integer.force("99")
      99

      iex> StepFlow.Integer.force(65)
      65

  """
  def force(param) when is_bitstring(param) do
    param
    |> String.to_integer()
  end

  def force(param) do
    param
  end
end
