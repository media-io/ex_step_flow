defmodule StepFlow.Plug do
  @moduledoc false

  def init(opts), do: opts

  def call(conn, opts) do
    conn
    |> StepFlow.Router.call(opts)
  end
end
