defmodule StepFlow.Progressions do
  @moduledoc """
  The Jobs context.
  """

  import Ecto.Query, warn: false
  alias StepFlow.Repo

  alias StepFlow.Progressions.Progression

  @doc """
  Creates a progression.

  ## Examples

      iex> create_progression(%{field: value})
      {:ok, %Progression{}}

      iex> create_progression(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_progression(attrs \\ %{}) do
    %Progression{}
    |> Progression.changeset(attrs)
    |> Repo.insert()
  end

 
end
