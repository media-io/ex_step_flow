defmodule StepFlow.Plug do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def init(opts), do: opts

      def call(conn, opts) do
        conn
        |> StepFlow.Authorization.check()
        |> StepFlow.Router.call(opts)
      end
    end
  end
end
