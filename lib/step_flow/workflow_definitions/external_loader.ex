defmodule StepFlow.WorkflowDefinitions.ExternalLoader do
  @moduledoc """
  Loader for referenced JSON schema implemented through Xema loader.
  """

  @behaviour Xema.Loader

  @spec fetch(binary) :: {:ok, map} | {:error, any}
  def fetch(uri) do
    with {:ok, response} <- get(uri), do: parse_body(response, uri)
  end

  defp get(uri) do
    specification_folder =
      Application.get_env(:step_flow, StepFlow.WorkflowDefinitions.ExternalLoader)[
        :specification_folder
      ]

    if specification_folder do
      File.read(specification_folder <> uri.path)
    else
      case HTTPoison.get(uri) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          {:ok, body}

        {:ok, %HTTPoison.Response{status_code: 404}} ->
          {:error, "Remote schema '#{uri}' not found."}

        {:ok, %HTTPoison.Response{status_code: code}} ->
          {:error, "code: #{code}"}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp parse_body(str, uri) do
    Jason.decode(str)
  rescue
    error -> {:error, %{error | file: URI.to_string(uri)}}
  end
end
