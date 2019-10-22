defmodule StepFlow.AuthenticationBehaviour do
  @doc false
  defmacro __using__(opts) do
    quote do
      def __adapter__ do
        # @adapter
        import unquote(Application.fetch_env!(:step_flow, :authorize))
      end

      # use unquote(Application.fetch_env!(:step_flow, :authorize))

      # toto = unquote(opts)
      # Logger.error("QUOTED #{inspect toto}")
    end
  end

  @callback __adapter__ :: any
end
