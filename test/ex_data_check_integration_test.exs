defmodule ExDataCheck.IntegrationTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExDataCheck.Expectations.Schema

  describe "ExDataCheck.validate/2" do
    test "validates dataset against single expectation" do
      dataset = [
        %{age: 25, name: "Alice"},
        %{age: 30, name: "Bob"}
      ]

      expectations = [
        Schema.expect_column_to_exist(:age)
      ]

      result = ExDataCheck.validate(dataset, expectations)

      assert result.success == true
      assert result.total_expectations == 1
      assert result.expectations_met == 1
      assert result.expectations_failed == 0
    end

    test "validates dataset against multiple expectations" do
      dataset = [
        %{age: 25, name: "Alice", active: true},
        %{age: 30, name: "Bob", active: false}
      ]

      expectations = [
        Schema.expect_column_to_exist(:age),
        Schema.expect_column_to_exist(:name),
        Schema.expect_column_to_be_of_type(:age, :integer),
        Schema.expect_column_to_be_of_type(:name, :string),
        Schema.expect_column_count_to_equal(3)
      ]

      result = ExDataCheck.validate(dataset, expectations)

      assert result.success == true
      assert result.total_expectations == 5
      assert result.expectations_met == 5
      assert result.expectations_failed == 0
    end

    test "returns failed result when any expectation fails" do
      dataset = [
        %{name: "Alice"},
        %{name: "Bob"}
      ]

      expectations = [
        Schema.expect_column_to_exist(:age),
        Schema.expect_column_to_exist(:name)
      ]

      result = ExDataCheck.validate(dataset, expectations)

      assert result.success == false
      assert result.total_expectations == 2
      assert result.expectations_met == 1
      assert result.expectations_failed == 1
    end

    test "includes dataset info in result" do
      dataset = [
        %{age: 25, name: "Alice"},
        %{age: 30, name: "Bob"}
      ]

      expectations = [Schema.expect_column_to_exist(:age)]

      result = ExDataCheck.validate(dataset, expectations)

      assert result.dataset_info.row_count == 2
      assert result.dataset_info.column_count == 2
      assert :age in result.dataset_info.columns
      assert :name in result.dataset_info.columns
    end

    test "includes timestamp in result" do
      dataset = [%{age: 25}]
      expectations = [Schema.expect_column_to_exist(:age)]

      result = ExDataCheck.validate(dataset, expectations)

      assert %DateTime{} = result.timestamp
    end

    test "handles empty expectations list" do
      dataset = [%{age: 25}]
      expectations = []

      result = ExDataCheck.validate(dataset, expectations)

      assert result.success == true
      assert result.total_expectations == 0
    end

    test "handles empty dataset" do
      dataset = []

      expectations = [
        Schema.expect_column_to_exist(:age)
      ]

      result = ExDataCheck.validate(dataset, expectations)

      assert result.success == false
      assert result.dataset_info.row_count == 0
    end

    test "collects all expectation results" do
      dataset = [
        %{age: 25, name: "Alice"},
        %{age: 30, name: "Bob"}
      ]

      expectations = [
        Schema.expect_column_to_exist(:age),
        Schema.expect_column_to_exist(:email),
        Schema.expect_column_to_be_of_type(:age, :integer)
      ]

      result = ExDataCheck.validate(dataset, expectations)

      assert length(result.results) == 3
      assert result.expectations_met == 2
      assert result.expectations_failed == 1
    end

    test "provides access to failed expectations" do
      dataset = [
        %{age: "25", name: "Alice"}
      ]

      expectations = [
        Schema.expect_column_to_exist(:age),
        Schema.expect_column_to_be_of_type(:age, :integer),
        Schema.expect_column_to_exist(:email)
      ]

      result = ExDataCheck.validate(dataset, expectations)
      failed = ExDataCheck.ValidationResult.failed_expectations(result)

      assert length(failed) == 2
      assert Enum.all?(failed, &(&1.success == false))
    end

    test "provides access to passed expectations" do
      dataset = [
        %{age: "25", name: "Alice"}
      ]

      expectations = [
        Schema.expect_column_to_exist(:age),
        Schema.expect_column_to_be_of_type(:age, :integer),
        Schema.expect_column_to_exist(:name)
      ]

      result = ExDataCheck.validate(dataset, expectations)
      passed = ExDataCheck.ValidationResult.passed_expectations(result)

      assert length(passed) == 2
      assert Enum.all?(passed, &(&1.success == true))
    end
  end

  describe "ExDataCheck.validate!/2" do
    test "returns result when validation succeeds" do
      dataset = [%{age: 25}]
      expectations = [Schema.expect_column_to_exist(:age)]

      result = ExDataCheck.validate!(dataset, expectations)

      assert result.success == true
    end

    test "raises when validation fails" do
      dataset = [%{name: "Alice"}]
      expectations = [Schema.expect_column_to_exist(:age)]

      assert_raise ExDataCheck.ValidationError, fn ->
        ExDataCheck.validate!(dataset, expectations)
      end
    end
  end

  property "validate always returns a ValidationResult" do
    check all(dataset <- list_of(map_of(atom(:alphanumeric), integer()))) do
      expectations = [Schema.expect_column_count_to_equal(0)]

      result = ExDataCheck.validate(dataset, expectations)

      assert %ExDataCheck.ValidationResult{} = result
      assert is_boolean(result.success)
      assert is_integer(result.total_expectations)
      assert is_list(result.results)
    end
  end

  property "total expectations equals length of expectations list" do
    check all(
            dataset <- list_of(map_of(atom(:alphanumeric), integer()), max_length: 10),
            count <- integer(0..5)
          ) do
      expectations = List.duplicate(Schema.expect_column_count_to_equal(0), count)

      result = ExDataCheck.validate(dataset, expectations)

      assert result.total_expectations == count
    end
  end

  property "expectations_met + expectations_failed equals total_expectations" do
    check all(
            dataset <- list_of(map_of(atom(:alphanumeric), integer()), max_length: 10),
            count <- integer(1..3)
          ) do
      expectations = List.duplicate(Schema.expect_column_count_to_equal(0), count)

      result = ExDataCheck.validate(dataset, expectations)

      assert result.expectations_met + result.expectations_failed == result.total_expectations
    end
  end
end
