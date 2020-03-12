defmodule StepFlow.Configuration do
  @moduledoc false

  def get_exposed_domain_name do
    case Application.get_env(:step_flow, StepFlow)[:exposed_domain_name] do
      {:system, key} -> System.get_env(key)
      exposed_domain_name -> exposed_domain_name
    end
  end

  def get_slack_token do
    if Application.get_env(:step_flow, StepFlow)[:skip_notification] != true do
      case Application.get_env(:step_flow, StepFlow)[:slack_api_token] do
        {:system, key} -> System.get_env(key)
        token -> token
      end
    else
      nil
    end
  end

  def get_slack_channel do
    case Application.get_env(:step_flow, StepFlow)[:slack_channel] do
      {:system, key} -> System.get_env(key)
      channel -> channel
    end
    |> format_channel
  end

  def format_channel(nil), do: nil
  def format_channel("#" <> _ = channel), do: channel
  def format_channel(channel), do: "#" <> channel
end
