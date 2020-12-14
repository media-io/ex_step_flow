defmodule StepFlow.Updates do
  @moduledoc """
  The Updates context.
  """

  import Ecto.Query, warn: false
  alias StepFlow.Updates.Update
  alias StepFlow.Repo

  @doc """
  Creates an update.

  ## Examples

      iex> create_update(%{field: value})
      {:ok, %Update{}}

      iex> create_update(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_update(attrs \\ %{}) do
    # Something like `if step.is_updatable`
    %Update{}
    |> Update.changeset(attrs)
    |> Repo.insert()

    Update.update_parameter(attrs)
    Job.set_job_status()
  end

  def update_parameter(attrs \\ %{}) do

  end
end
