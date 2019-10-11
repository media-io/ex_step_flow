defmodule StepFlow.StatusView do
  use StepFlow, :view
  alias StepFlow.StatusView

  def render("index.json", %{status: status}) do
    %{data: render_many(status, StatusView, "state.json")}
  end

  def render("show.json", %{status: status}) do
    %{data: render_one(status, StatusView, "state.json")}
  end

  def render("state.json", %{status: status}) do
    %{
      id: status.id,
      state: status.state,
      description: status.description,
      inserted_at: status.inserted_at
    }
  end
end
