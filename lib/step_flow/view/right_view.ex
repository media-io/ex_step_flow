defmodule StepFlow.RightView do
  use StepFlow, :view
  alias StepFlow.RightView

  def render("index.json", %{rights: rights}) do
    %{data: render_many(rights, RightView, "right.json")}
  end

  def render("show.json", %{right: right}) do
    %{data: render_one(right, RightView, "right.json")}
  end

  def render("right.json", %{right: right}) do
    %{
      id: right.id,
      action: right.action,
      groups: right.groups,
      inserted_at: right.inserted_at
    }
  end
end
