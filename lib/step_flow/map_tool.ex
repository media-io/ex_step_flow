defmodule StepFlow.Map do
  @moduledoc """
  Extend Map with some additional functions.
  """

  def get_by_key_or_atom(dict, atom, default \\ nil) do
    Map.get_lazy(dict, atom, fn -> Map.get(dict, Atom.to_string(atom), default) end)
  end

  def replace_by_atom(dict, atom, value) when is_atom(atom) do
    dict
    |> Map.delete(Atom.to_string(atom))
    |> Map.delete(atom)
    |> Map.put(atom, value)
  end

  def replace_by_atom(_dict, _atom, _value) do
    raise "Got unsupported key type instead of expected Atom."
  end
end
