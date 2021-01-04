defmodule StepFlow.Configuration do
  @moduledoc false

  def get_var_value(module, key, default \\ nil) do
    conf_module = Application.get_env(:step_flow, module)

    case Keyword.get(conf_module, key) do
      {:system, variable} -> System.get_env(variable)
      nil -> default
      value -> value
    end
  end

  def get_exposed_domain_name do
    get_var_value(StepFlow, :exposed_domain_name)
  end

  def get_slack_token do
    if notifications_enabled?() do
      get_var_value(StepFlow, :slack_api_token)
    else
      nil
    end
  end

  def get_slack_channel do
    get_var_value(StepFlow, :slack_api_channel)
    |> format_channel
  end

  def format_channel(nil), do: nil
  def format_channel("#" <> _ = channel), do: channel
  def format_channel(channel), do: "#" <> channel

  def to_string(value) when is_integer(value), do: Integer.to_string(value)
  def to_string(value), do: value

  def to_integer(value) when is_bitstring(value) do
    {value, _} = Integer.parse(value)
    value
  end

  def to_integer(value) when is_integer(value), do: value

  defp notifications_enabled? do
    skip_notification = get_var_value(StepFlow, :skip_notification)

    case skip_notification do
      false -> false
      "false" -> false
      _ -> true
    end
  end

  def metrics_enabled? do
    get_var_value(StepFlow, :enable_metrics, false)
  end
end
