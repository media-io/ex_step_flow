defmodule StepFlow.Plug do
  @moduledoc false

  def init(opts), do: opts

  def call(conn, opts) do
    conn
    |> Plug.Conn.assign(:name, Keyword.get(opts, :name, "Step Flow"))
    |> StepFlow.Router.call(opts)
  end
end
