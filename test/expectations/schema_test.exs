defmodule ExDataCheck.Expectations.SchemaTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExDataCheck.Expectations.Schema
  alias ExDataCheck.{Expectation, ExpectationResult}

  describe "expect_column_to_exist/1" do
    test "creates an expectation struct" do
      expectation = Schema.expect_column_to_exist(:age)

      assert %Expectation{} = expectation
      assert expectation.type == :column_exists
      assert expectation.column == :age
      assert is_function(expectation.validator, 1)
    end

    test "validator returns success when column exists" do
      dataset = [
        %{age: 25, name: "Alice"},
        %{age: 30, name: "Bob"}
      ]

      expectation = Schema.expect_column_to_exist(:age)
      result = expectation.validator.(dataset)

      assert %ExpectationResult{} = result
      assert result.success == true
      assert result.expectation =~ "column :age"
      assert result.expectation =~ "exist"
    end

    test "validator returns failure when column doesn't exist" do
      dataset = [
        %{name: "Alice"},
        %{name: "Bob"}
      ]

      expectation = Schema.expect_column_to_exist(:age)
      result = expectation.validator.(dataset)

      assert %ExpectationResult{} = result
      assert result.success == false
      assert result.expectation =~ "column :age"
    end

    test "works with string column names" do
      dataset = [
        %{"age" => 25},
        %{"age" => 30}
      ]

      expectation = Schema.expect_column_to_exist("age")
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "handles empty dataset as failure" do
      dataset = []

      expectation = Schema.expect_column_to_exist(:age)
      result = expectation.validator.(dataset)

      assert result.success == false
    end

    test "succeeds if column exists in any row" do
      dataset = [
        %{age: 25},
        %{name: "Bob"}
      ]

      expectation = Schema.expect_column_to_exist(:age)
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "result includes observed data" do
      dataset = [
        %{age: 25, name: "Alice"},
        %{age: 30, name: "Bob"}
      ]

      expectation = Schema.expect_column_to_exist(:age)
      result = expectation.validator.(dataset)

      assert is_map(result.observed)
      assert result.observed.column == :age
      assert result.observed.exists == true
    end

    test "result includes available columns when column doesn't exist" do
      dataset = [
        %{name: "Alice", email: "alice@example.com"},
        %{name: "Bob", email: "bob@example.com"}
      ]

      expectation = Schema.expect_column_to_exist(:age)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert is_list(result.observed.available_columns)
      assert :name in result.observed.available_columns
      assert :email in result.observed.available_columns
    end
  end

  describe "expect_column_to_be_of_type/2" do
    test "creates an expectation struct" do
      expectation = Schema.expect_column_to_be_of_type(:age, :integer)

      assert %Expectation{} = expectation
      assert expectation.type == :column_type
      assert expectation.column == :age
      assert expectation.metadata.expected_type == :integer
    end

    test "validator returns success when all values are of correct type" do
      dataset = [
        %{age: 25},
        %{age: 30},
        %{age: 35}
      ]

      expectation = Schema.expect_column_to_be_of_type(:age, :integer)
      result = expectation.validator.(dataset)

      assert result.success == true
      assert result.expectation =~ ":age"
      assert result.expectation =~ "integer"
    end

    test "validator returns failure when values are of wrong type" do
      dataset = [
        %{age: "25"},
        %{age: "30"}
      ]

      expectation = Schema.expect_column_to_be_of_type(:age, :integer)
      result = expectation.validator.(dataset)

      assert result.success == false
    end

    test "handles mixed types" do
      dataset = [
        %{age: 25},
        %{age: "30"},
        %{age: 35}
      ]

      expectation = Schema.expect_column_to_be_of_type(:age, :integer)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.total_values == 3
      assert result.observed.incorrect_type_count == 1
    end

    test "supports :integer type" do
      dataset = [%{age: 25}, %{age: 30}]
      expectation = Schema.expect_column_to_be_of_type(:age, :integer)
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "supports :float type" do
      dataset = [%{score: 0.85}, %{score: 0.92}]
      expectation = Schema.expect_column_to_be_of_type(:score, :float)
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "supports :string type" do
      dataset = [%{name: "Alice"}, %{name: "Bob"}]
      expectation = Schema.expect_column_to_be_of_type(:name, :string)
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "supports :boolean type" do
      dataset = [%{active: true}, %{active: false}]
      expectation = Schema.expect_column_to_be_of_type(:active, :boolean)
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "ignores nil values by default" do
      dataset = [
        %{age: 25},
        %{age: nil},
        %{age: 30}
      ]

      expectation = Schema.expect_column_to_be_of_type(:age, :integer)
      result = expectation.validator.(dataset)

      assert result.success == true
    end
  end

  describe "expect_column_count_to_equal/1" do
    test "creates an expectation struct" do
      expectation = Schema.expect_column_count_to_equal(5)

      assert %Expectation{} = expectation
      assert expectation.type == :column_count
      assert expectation.metadata.expected_count == 5
    end

    test "validator returns success when column count matches" do
      dataset = [
        %{a: 1, b: 2, c: 3, d: 4, e: 5}
      ]

      expectation = Schema.expect_column_count_to_equal(5)
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "validator returns failure when column count doesn't match" do
      dataset = [
        %{a: 1, b: 2, c: 3}
      ]

      expectation = Schema.expect_column_count_to_equal(5)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.actual_count == 3
      assert result.observed.expected_count == 5
    end

    test "counts unique columns across all rows" do
      dataset = [
        %{a: 1, b: 2},
        %{a: 1, c: 3},
        %{b: 2, d: 4}
      ]

      expectation = Schema.expect_column_count_to_equal(4)
      result = expectation.validator.(dataset)

      assert result.success == true
      assert result.observed.actual_count == 4
    end
  end

  property "expect_column_to_exist always creates valid expectation" do
    check all(column <- one_of([atom(:alphanumeric), string(:alphanumeric, min_length: 1)])) do
      expectation = Schema.expect_column_to_exist(column)

      assert %Expectation{} = expectation
      assert expectation.column == column
      assert is_function(expectation.validator, 1)
    end
  end
end
