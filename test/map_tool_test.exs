defmodule StepFlow.MapToolTest do
  use ExUnit.Case

  doctest StepFlow.Map

  test "get_by_key_or_atom" do
    source_1 = %{
      key_1: "value_1"
    }

    source_2 = %{
      "key_2" => "value_2"
    }

    assert StepFlow.Map.get_by_key_or_atom(source_1, :key_1) == "value_1"
    assert StepFlow.Map.get_by_key_or_atom(source_2, :key_2) == "value_2"
  end

  test "replace_by_atom" do
    source_1 = %{
      key_1: "value_1"
    }

    source_2 = %{
      "key_2" => "value_2"
    }

    assert StepFlow.Map.replace_by_atom(source_1, :key_1, "new_value_1") == %{
             key_1: "new_value_1"
           }

    assert StepFlow.Map.replace_by_atom(source_2, :key_2, "new_value_2") == %{
             key_2: "new_value_2"
           }
  end

  test "get_by_key_or_atom with bad type" do
    assert_raise(
      RuntimeError,
      "Got unsupported key type instead of expected Atom or String.",
      fn ->
        StepFlow.Map.get_by_key_or_atom(%{"key" => "value"}, %{bad: :format}, "replaced_value")
      end
    )
  end

  test "replace_by_atom with bad type" do
    assert_raise(
      RuntimeError,
      "Got unsupported key type instead of expected Atom or String.",
      fn ->
        StepFlow.Map.replace_by_atom(%{"key" => "value"}, %{bad: :format}, "replaced_value")
      end
    )
  end
end
