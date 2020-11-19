defmodule StepFlow.Controller.Helpers do
  @moduledoc """
  The Helper Controller context.
  """

  @doc """
  Check wether a user is allowed to use a rightable structure
  """
  def check_right(rightable, user, action) do
    rightable
    |> Map.get(:rights)
    |> Enum.find(%{}, fn r -> r.action == action end)
    |> Map.get(:groups, [])
    |> Enum.any?(fn g -> g in user.rights end)
  end
end
