defmodule ExDataCheck.ExpectationTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExDataCheck.Expectation

  describe "Expectation struct" do
    test "creates an expectation with all required fields" do
      validator_fn = fn _dataset -> :ok end

      expectation = %Expectation{
        type: :value_range,
        column: :age,
        validator: validator_fn,
        metadata: %{min: 0, max: 120}
      }

      assert expectation.type == :value_range
      assert expectation.column == :age
      assert is_function(expectation.validator, 1)
      assert expectation.metadata == %{min: 0, max: 120}
    end

    test "allows column to be atom or string" do
      validator_fn = fn _dataset -> :ok end

      expectation_atom = %Expectation{
        type: :column_exists,
        column: :age,
        validator: validator_fn
      }

      expectation_string = %Expectation{
        type: :column_exists,
        column: "age",
        validator: validator_fn
      }

      assert expectation_atom.column == :age
      assert expectation_string.column == "age"
    end

    test "defaults metadata to empty map" do
      validator_fn = fn _dataset -> :ok end

      expectation = %Expectation{
        type: :not_null,
        column: :name,
        validator: validator_fn
      }

      assert expectation.metadata == %{}
    end
  end

  describe "new/4" do
    test "creates an expectation using constructor function" do
      validator_fn = fn _dataset -> :ok end

      expectation =
        Expectation.new(
          :value_range,
          :age,
          validator_fn,
          %{min: 0, max: 120}
        )

      assert %Expectation{} = expectation
      assert expectation.type == :value_range
      assert expectation.column == :age
      assert is_function(expectation.validator, 1)
      assert expectation.metadata == %{min: 0, max: 120}
    end

    test "creates expectation with default metadata" do
      validator_fn = fn _dataset -> :ok end

      expectation = Expectation.new(:not_null, :name, validator_fn)

      assert expectation.metadata == %{}
    end
  end

  property "expectation type is always an atom" do
    check all(
            type <- atom(:alphanumeric),
            column <- one_of([atom(:alphanumeric), string(:alphanumeric)])
          ) do
      validator_fn = fn _dataset -> :ok end

      expectation = Expectation.new(type, column, validator_fn)

      assert is_atom(expectation.type)
    end
  end

  property "validator is always a function" do
    check all(column <- one_of([atom(:alphanumeric), string(:alphanumeric)])) do
      validator_fn = fn _dataset -> :ok end

      expectation = Expectation.new(:test, column, validator_fn)

      assert is_function(expectation.validator, 1)
    end
  end
end
