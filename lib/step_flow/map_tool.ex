defmodule StepFlow.Map do
  @moduledoc """
  Extend Map with some additional functions.
  """

  @doc """
  Get a key matching on an atom or a string.

  Default value can be specified.

  ## Examples

      iex> StepFlow.Map.get_by_key_or_atom(%{key: "value"}, :key)
      "value"

      iex> StepFlow.Map.get_by_key_or_atom(%{"key" => "value"}, :key)
      "value"

      iex> StepFlow.Map.get_by_key_or_atom(%{key: "value"}, "key")
      "value"

      iex> StepFlow.Map.get_by_key_or_atom(%{"key" => "value"}, "key")
      "value"

  """
  def get_by_key_or_atom(dict, atom, default \\ nil)

  def get_by_key_or_atom(dict, atom, default) when is_atom(atom) do
    Map.get_lazy(dict, atom, fn -> Map.get(dict, Atom.to_string(atom), default) end)
  end

  def get_by_key_or_atom(dict, string, default) when is_bitstring(string) do
    Map.get_lazy(dict, string, fn -> Map.get(dict, String.to_atom(string), default) end)
  end

  def get_by_key_or_atom(_, _, _) do
    raise "Got unsupported key type instead of expected Atom or String."
  end

  @doc """
  Replace an item in a map, with atom or string keys.

  ## Examples

      iex> StepFlow.Map.replace_by_atom(%{key: "value"}, :key, "replaced_value")
      %{key: "replaced_value"}

      iex> StepFlow.Map.replace_by_atom(%{"key" => "value"}, :key, "replaced_value")
      %{key: "replaced_value"}

      iex> StepFlow.Map.replace_by_atom(%{"key" => "value"}, "key", "replaced_value")
      %{key: "replaced_value"}

  """
  def replace_by_atom(dict, atom, value) when is_atom(atom) do
    dict
    |> Map.delete(Atom.to_string(atom))
    |> Map.delete(atom)
    |> Map.put(atom, value)
  end

  def replace_by_atom(dict, string, value) when is_bitstring(string) do
    dict
    |> Map.delete(String.to_atom(string))
    |> Map.delete(string)
    |> Map.put(String.to_atom(string), value)
  end

  def replace_by_string(dict, string, value) when is_bitstring(string) do
    dict
    |> Map.delete(String.to_atom(string))
    |> Map.delete(string)
    |> Map.put(string, value)
  end

  def replace_by_atom(_dict, _atom, _value) do
    raise "Got unsupported key type instead of expected Atom or String."
  end
end
