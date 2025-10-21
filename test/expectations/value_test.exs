defmodule ExDataCheck.Expectations.ValueTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExDataCheck.Expectations.Value
  alias ExDataCheck.Expectation

  describe "expect_column_values_to_be_between/3" do
    test "creates an expectation struct" do
      expectation = Value.expect_column_values_to_be_between(:age, 0, 120)

      assert %Expectation{} = expectation
      assert expectation.type == :value_range
      assert expectation.column == :age
      assert expectation.metadata.min == 0
      assert expectation.metadata.max == 120
    end

    test "validates when all values are within range" do
      dataset = [
        %{age: 25},
        %{age: 30},
        %{age: 35}
      ]

      expectation = Value.expect_column_values_to_be_between(:age, 0, 120)
      result = expectation.validator.(dataset)

      assert result.success == true
      assert result.observed.total_values == 3
      assert result.observed.failing_values == 0
    end

    test "fails when values are outside range" do
      dataset = [
        %{age: 25},
        %{age: 150},
        %{age: 200}
      ]

      expectation = Value.expect_column_values_to_be_between(:age, 0, 120)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.total_values == 3
      assert result.observed.failing_values == 2
      assert 150 in result.observed.failing_examples
      assert 200 in result.observed.failing_examples
    end

    test "handles values at boundaries (inclusive)" do
      dataset = [
        %{age: 0},
        %{age: 120}
      ]

      expectation = Value.expect_column_values_to_be_between(:age, 0, 120)
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "ignores nil values by default" do
      dataset = [
        %{age: 25},
        %{age: nil},
        %{age: 30}
      ]

      expectation = Value.expect_column_values_to_be_between(:age, 0, 120)
      result = expectation.validator.(dataset)

      assert result.success == true
      assert result.observed.total_values == 2
    end

    test "works with float values" do
      dataset = [
        %{score: 0.5},
        %{score: 0.85},
        %{score: 0.92}
      ]

      expectation = Value.expect_column_values_to_be_between(:score, 0.0, 1.0)
      result = expectation.validator.(dataset)

      assert result.success == true
    end
  end

  describe "expect_column_values_to_be_in_set/2" do
    test "creates an expectation struct" do
      expectation =
        Value.expect_column_values_to_be_in_set(:status, ["active", "pending", "completed"])

      assert %Expectation{} = expectation
      assert expectation.type == :value_set
      assert expectation.column == :status
      assert expectation.metadata.allowed_values == ["active", "pending", "completed"]
    end

    test "validates when all values are in allowed set" do
      dataset = [
        %{status: "active"},
        %{status: "pending"},
        %{status: "completed"}
      ]

      expectation =
        Value.expect_column_values_to_be_in_set(:status, ["active", "pending", "completed"])

      result = expectation.validator.(dataset)

      assert result.success == true
      assert result.observed.failing_values == 0
    end

    test "fails when values are not in allowed set" do
      dataset = [
        %{status: "active"},
        %{status: "invalid"},
        %{status: "unknown"}
      ]

      expectation =
        Value.expect_column_values_to_be_in_set(:status, ["active", "pending", "completed"])

      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.failing_values == 2
      assert "invalid" in result.observed.failing_examples
      assert "unknown" in result.observed.failing_examples
    end

    test "works with atom values" do
      dataset = [
        %{status: :active},
        %{status: :pending}
      ]

      expectation =
        Value.expect_column_values_to_be_in_set(:status, [:active, :pending, :completed])

      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "ignores nil values by default" do
      dataset = [
        %{status: "active"},
        %{status: nil},
        %{status: "pending"}
      ]

      expectation = Value.expect_column_values_to_be_in_set(:status, ["active", "pending"])
      result = expectation.validator.(dataset)

      assert result.success == true
    end
  end

  describe "expect_column_values_to_match_regex/2" do
    test "creates an expectation struct" do
      expectation = Value.expect_column_values_to_match_regex(:email, ~r/@/)

      assert %Expectation{} = expectation
      assert expectation.type == :value_regex
      assert expectation.column == :email
      assert %Regex{} = expectation.metadata.pattern
    end

    test "validates when all values match regex" do
      dataset = [
        %{email: "alice@example.com"},
        %{email: "bob@test.org"}
      ]

      expectation = Value.expect_column_values_to_match_regex(:email, ~r/@/)
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "fails when values don't match regex" do
      dataset = [
        %{email: "alice@example.com"},
        %{email: "invalid"},
        %{email: "also-invalid"}
      ]

      expectation = Value.expect_column_values_to_match_regex(:email, ~r/@/)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.failing_values == 2
    end

    test "handles complex regex patterns" do
      dataset = [
        %{phone: "555-1234"},
        %{phone: "555-5678"}
      ]

      expectation = Value.expect_column_values_to_match_regex(:phone, ~r/^\d{3}-\d{4}$/)
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "ignores nil values" do
      dataset = [
        %{email: "alice@example.com"},
        %{email: nil}
      ]

      expectation = Value.expect_column_values_to_match_regex(:email, ~r/@/)
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "handles non-string values gracefully" do
      dataset = [
        %{value: 123},
        %{value: 456}
      ]

      expectation = Value.expect_column_values_to_match_regex(:value, ~r/\d+/)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.failing_values == 2
    end
  end

  describe "expect_column_values_to_not_be_null/1" do
    test "creates an expectation struct" do
      expectation = Value.expect_column_values_to_not_be_null(:user_id)

      assert %Expectation{} = expectation
      assert expectation.type == :not_null
      assert expectation.column == :user_id
    end

    test "validates when no values are null" do
      dataset = [
        %{user_id: 1},
        %{user_id: 2},
        %{user_id: 3}
      ]

      expectation = Value.expect_column_values_to_not_be_null(:user_id)
      result = expectation.validator.(dataset)

      assert result.success == true
      assert result.observed.null_count == 0
    end

    test "fails when values are null" do
      dataset = [
        %{user_id: 1},
        %{user_id: nil},
        %{user_id: nil}
      ]

      expectation = Value.expect_column_values_to_not_be_null(:user_id)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.null_count == 2
      assert result.observed.total_values == 3
    end

    test "handles missing keys as null" do
      dataset = [
        %{user_id: 1},
        %{name: "Bob"}
      ]

      expectation = Value.expect_column_values_to_not_be_null(:user_id)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.null_count == 1
    end

    test "empty string is not considered null" do
      dataset = [
        %{name: "Alice"},
        %{name: ""}
      ]

      expectation = Value.expect_column_values_to_not_be_null(:name)
      result = expectation.validator.(dataset)

      assert result.success == true
    end
  end

  describe "expect_column_values_to_be_unique/1" do
    test "creates an expectation struct" do
      expectation = Value.expect_column_values_to_be_unique(:user_id)

      assert %Expectation{} = expectation
      assert expectation.type == :unique
      assert expectation.column == :user_id
    end

    test "validates when all values are unique" do
      dataset = [
        %{user_id: 1},
        %{user_id: 2},
        %{user_id: 3}
      ]

      expectation = Value.expect_column_values_to_be_unique(:user_id)
      result = expectation.validator.(dataset)

      assert result.success == true
      assert result.observed.duplicate_count == 0
    end

    test "fails when values are duplicated" do
      dataset = [
        %{user_id: 1},
        %{user_id: 2},
        %{user_id: 1},
        %{user_id: 3},
        %{user_id: 2}
      ]

      expectation = Value.expect_column_values_to_be_unique(:user_id)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.duplicate_count == 2
      assert 1 in result.observed.duplicate_examples
      assert 2 in result.observed.duplicate_examples
    end

    test "nil values are not considered duplicates" do
      dataset = [
        %{user_id: 1},
        %{user_id: nil},
        %{user_id: nil},
        %{user_id: 2}
      ]

      expectation = Value.expect_column_values_to_be_unique(:user_id)
      result = expectation.validator.(dataset)

      assert result.success == true
    end
  end

  describe "expect_column_values_to_be_increasing/1" do
    test "creates an expectation struct" do
      expectation = Value.expect_column_values_to_be_increasing(:timestamp)

      assert %Expectation{} = expectation
      assert expectation.type == :increasing
      assert expectation.column == :timestamp
    end

    test "validates when values are strictly increasing" do
      dataset = [
        %{timestamp: 1},
        %{timestamp: 2},
        %{timestamp: 3}
      ]

      expectation = Value.expect_column_values_to_be_increasing(:timestamp)
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "fails when values are not increasing" do
      dataset = [
        %{timestamp: 1},
        %{timestamp: 3},
        %{timestamp: 2}
      ]

      expectation = Value.expect_column_values_to_be_increasing(:timestamp)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.violations > 0
    end

    test "fails when values are equal (not strictly increasing)" do
      dataset = [
        %{value: 1},
        %{value: 2},
        %{value: 2},
        %{value: 3}
      ]

      expectation = Value.expect_column_values_to_be_increasing(:value)
      result = expectation.validator.(dataset)

      assert result.success == false
    end

    test "handles single value as valid" do
      dataset = [%{value: 1}]

      expectation = Value.expect_column_values_to_be_increasing(:value)
      result = expectation.validator.(dataset)

      assert result.success == true
    end
  end

  describe "expect_column_values_to_be_decreasing/1" do
    test "creates an expectation struct" do
      expectation = Value.expect_column_values_to_be_decreasing(:temperature)

      assert %Expectation{} = expectation
      assert expectation.type == :decreasing
      assert expectation.column == :temperature
    end

    test "validates when values are strictly decreasing" do
      dataset = [
        %{temperature: 100},
        %{temperature: 75},
        %{temperature: 50}
      ]

      expectation = Value.expect_column_values_to_be_decreasing(:temperature)
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "fails when values are not decreasing" do
      dataset = [
        %{temperature: 100},
        %{temperature: 50},
        %{temperature: 75}
      ]

      expectation = Value.expect_column_values_to_be_decreasing(:temperature)
      result = expectation.validator.(dataset)

      assert result.success == false
    end
  end

  describe "expect_column_value_lengths_to_be_between/3" do
    test "creates an expectation struct" do
      expectation = Value.expect_column_value_lengths_to_be_between(:name, 2, 50)

      assert %Expectation{} = expectation
      assert expectation.type == :value_length_range
      assert expectation.column == :name
      assert expectation.metadata.min_length == 2
      assert expectation.metadata.max_length == 50
    end

    test "validates when all string lengths are within range" do
      dataset = [
        %{name: "Alice"},
        %{name: "Bob"},
        %{name: "Charlie"}
      ]

      expectation = Value.expect_column_value_lengths_to_be_between(:name, 2, 10)
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "fails when string lengths are outside range" do
      dataset = [
        %{name: "A"},
        %{name: "Bob"},
        %{name: "Very Long Name That Exceeds Limit"}
      ]

      expectation = Value.expect_column_value_lengths_to_be_between(:name, 2, 10)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.failing_values == 2
    end

    test "works with list lengths" do
      dataset = [
        %{tags: ["a", "b", "c"]},
        %{tags: ["x", "y"]}
      ]

      expectation = Value.expect_column_value_lengths_to_be_between(:tags, 1, 5)
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "ignores nil values" do
      dataset = [
        %{name: "Alice"},
        %{name: nil},
        %{name: "Bob"}
      ]

      expectation = Value.expect_column_value_lengths_to_be_between(:name, 2, 10)
      result = expectation.validator.(dataset)

      assert result.success == true
    end
  end

  property "between expectation always creates valid expectation" do
    check all(
            column <- atom(:alphanumeric),
            min <- integer(-100..100),
            range <- integer(0..100)
          ) do
      max = min + range
      expectation = Value.expect_column_values_to_be_between(column, min, max)

      assert %Expectation{} = expectation
      assert expectation.column == column
      assert is_function(expectation.validator, 1)
    end
  end

  property "in_set expectation works with any non-empty set" do
    check all(
            column <- atom(:alphanumeric),
            allowed_values <- list_of(integer(), min_length: 1, max_length: 10)
          ) do
      expectation = Value.expect_column_values_to_be_in_set(column, allowed_values)

      assert %Expectation{} = expectation
      assert expectation.metadata.allowed_values == allowed_values
    end
  end
end
