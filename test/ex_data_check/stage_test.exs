defmodule ExDataCheck.StageTest do
  use ExUnit.Case, async: true

  alias ExDataCheck.Stage
  import ExDataCheck

  describe "run/2 basic validation" do
    test "validates dataset successfully with passing expectations" do
      dataset = [
        %{age: 25, name: "Alice"},
        %{age: 30, name: "Bob"}
      ]

      context = %{dataset: dataset}

      opts = %{
        expectations: [
          expect_column_to_exist(:age),
          expect_column_to_exist(:name),
          expect_column_values_to_be_between(:age, 0, 100)
        ]
      }

      result = Stage.run(context, opts)

      assert Map.has_key?(result, :data_validation)
      assert result.data_validation.passed == true
      assert result.data_validation.expectations_met == 3
      assert result.data_validation.expectations_failed == 0
      assert result.data_validation.total_expectations == 3
      assert result.data_validation.validation_result.success == true
    end

    test "validates dataset with failing expectations" do
      dataset = [
        %{age: 150, name: "Alice"},
        %{age: 30, name: "Bob"}
      ]

      context = %{dataset: dataset}

      opts = %{
        expectations: [
          expect_column_to_exist(:age),
          expect_column_values_to_be_between(:age, 0, 100)
        ]
      }

      result = Stage.run(context, opts)

      assert Map.has_key?(result, :data_validation)
      assert result.data_validation.passed == false
      assert result.data_validation.expectations_met == 1
      assert result.data_validation.expectations_failed == 1
      assert result.data_validation.total_expectations == 2
      assert result.data_validation.validation_result.success == false
    end

    test "accepts dataset under :examples key" do
      examples = [
        %{age: 25, name: "Alice"},
        %{age: 30, name: "Bob"}
      ]

      context = %{examples: examples}

      opts = %{
        expectations: [
          expect_column_to_exist(:age)
        ]
      }

      result = Stage.run(context, opts)

      assert result.data_validation.passed == true
    end

    test "preserves other context keys" do
      dataset = [%{age: 25}]
      context = %{dataset: dataset, other_key: "preserved", another: 123}

      opts = %{
        expectations: [expect_column_to_exist(:age)]
      }

      result = Stage.run(context, opts)

      assert result.other_key == "preserved"
      assert result.another == 123
      assert Map.has_key?(result, :data_validation)
    end
  end

  describe "run/2 error handling" do
    test "raises when context missing dataset/examples" do
      context = %{wrong_key: []}

      opts = %{
        expectations: [expect_column_to_exist(:age)]
      }

      assert_raise ArgumentError, ~r/must contain :dataset or :examples key/, fn ->
        Stage.run(context, opts)
      end
    end

    test "raises when expectations not provided" do
      context = %{dataset: [%{age: 25}]}
      opts = %{}

      assert_raise ArgumentError, ~r/requires :expectations/, fn ->
        Stage.run(context, opts)
      end
    end

    test "raises when expectations is empty list" do
      context = %{dataset: [%{age: 25}]}
      opts = %{expectations: []}

      assert_raise ArgumentError, ~r/requires :expectations/, fn ->
        Stage.run(context, opts)
      end
    end
  end

  describe "run/2 with fail_fast option" do
    test "does not raise on failure when fail_fast is false (default)" do
      dataset = [%{age: 150}]
      context = %{dataset: dataset}

      opts = %{
        expectations: [expect_column_values_to_be_between(:age, 0, 100)],
        fail_fast: false
      }

      result = Stage.run(context, opts)

      assert result.data_validation.passed == false
      # Should not raise, just return failure
    end

    test "raises on failure when fail_fast is true" do
      dataset = [%{age: 150}]
      context = %{dataset: dataset}

      opts = %{
        expectations: [expect_column_values_to_be_between(:age, 0, 100)],
        fail_fast: true
      }

      assert_raise ExDataCheck.ValidationError, fn ->
        Stage.run(context, opts)
      end
    end

    test "does not raise when validations pass with fail_fast true" do
      dataset = [%{age: 25}]
      context = %{dataset: dataset}

      opts = %{
        expectations: [expect_column_values_to_be_between(:age, 0, 100)],
        fail_fast: true
      }

      result = Stage.run(context, opts)

      assert result.data_validation.passed == true
    end
  end

  describe "run/2 with profile option" do
    test "includes profile when profile option is true" do
      dataset = [
        %{age: 25, name: "Alice"},
        %{age: 30, name: "Bob"},
        %{age: 35, name: "Charlie"}
      ]

      context = %{dataset: dataset}

      opts = %{
        expectations: [expect_column_to_exist(:age)],
        profile: true
      }

      result = Stage.run(context, opts)

      assert result.data_validation.profile != nil
      assert result.data_validation.profile.row_count == 3
      assert result.data_validation.profile.column_count == 2
      assert Map.has_key?(result.data_validation.profile.columns, :age)
      assert Map.has_key?(result.data_validation.profile.columns, :name)
    end

    test "does not include profile when profile option is false (default)" do
      dataset = [%{age: 25, name: "Alice"}]
      context = %{dataset: dataset}

      opts = %{
        expectations: [expect_column_to_exist(:age)],
        profile: false
      }

      result = Stage.run(context, opts)

      assert result.data_validation.profile == nil
    end

    test "does not include profile when option not specified" do
      dataset = [%{age: 25, name: "Alice"}]
      context = %{dataset: dataset}

      opts = %{
        expectations: [expect_column_to_exist(:age)]
      }

      result = Stage.run(context, opts)

      assert result.data_validation.profile == nil
    end
  end

  describe "run/2 with multiple expectations" do
    test "validates all schema expectations" do
      dataset = [
        %{age: 25, name: "Alice", email: "alice@example.com"},
        %{age: 30, name: "Bob", email: "bob@example.com"}
      ]

      context = %{dataset: dataset}

      opts = %{
        expectations: [
          expect_column_to_exist(:age),
          expect_column_to_exist(:name),
          expect_column_to_exist(:email),
          expect_column_to_be_of_type(:age, :integer),
          expect_column_to_be_of_type(:name, :string),
          expect_column_count_to_equal(3)
        ]
      }

      result = Stage.run(context, opts)

      assert result.data_validation.passed == true
      assert result.data_validation.expectations_met == 6
    end

    test "validates mixed expectation types" do
      dataset = [
        %{age: 25, name: "Alice", score: 0.85},
        %{age: 30, name: "Bob", score: 0.92},
        %{age: 35, name: "Charlie", score: 0.78}
      ]

      context = %{dataset: dataset}

      opts = %{
        expectations: [
          # Schema
          expect_column_to_exist(:age),
          expect_column_to_be_of_type(:score, :float),
          # Value
          expect_column_values_to_be_between(:age, 18, 100),
          expect_column_values_to_not_be_null(:name),
          # Statistical
          expect_column_mean_to_be_between(:age, 25, 35),
          expect_column_stdev_to_be_between(:score, 0.01, 0.2)
        ]
      }

      result = Stage.run(context, opts)

      assert result.data_validation.passed == true
      assert result.data_validation.expectations_met == 6
    end
  end

  describe "describe/1" do
    test "describes basic stage with expectation count" do
      opts = %{
        expectations: [
          expect_column_to_exist(:age),
          expect_column_to_exist(:name)
        ]
      }

      description = Stage.describe(opts)

      assert description == "Data validation stage with 2 expectation(s)"
    end

    test "describes stage with single expectation" do
      opts = %{
        expectations: [expect_column_to_exist(:age)]
      }

      description = Stage.describe(opts)

      assert description == "Data validation stage with 1 expectation(s)"
    end

    test "describes stage with fail_fast option" do
      opts = %{
        expectations: [expect_column_to_exist(:age)],
        fail_fast: true
      }

      description = Stage.describe(opts)

      assert description == "Data validation stage with 1 expectation(s) (fail-fast)"
    end

    test "describes stage with profile option" do
      opts = %{
        expectations: [expect_column_to_exist(:age)],
        profile: true
      }

      description = Stage.describe(opts)

      assert description == "Data validation stage with 1 expectation(s) (profiling)"
    end

    test "describes stage with both fail_fast and profile" do
      opts = %{
        expectations: [expect_column_to_exist(:age)],
        fail_fast: true,
        profile: true
      }

      description = Stage.describe(opts)

      assert description =~ "Data validation stage with 1 expectation(s)"
      assert description =~ "fail-fast"
      assert description =~ "profiling"
    end

    test "describes empty stage configuration" do
      opts = %{expectations: []}

      description = Stage.describe(opts)

      assert description == "Data validation stage with 0 expectation(s)"
    end

    test "describes stage with no options" do
      description = Stage.describe(%{})

      assert description == "Data validation stage with 0 expectation(s)"
    end
  end

  describe "integration with complex datasets" do
    test "handles ML training data validation" do
      dataset = [
        %{features: [1.0, 2.0, 3.0], label: 0, id: 1},
        %{features: [1.5, 2.5, 3.5], label: 1, id: 2},
        %{features: [2.0, 3.0, 4.0], label: 0, id: 3},
        %{features: [2.5, 3.5, 4.5], label: 1, id: 4}
      ]

      context = %{dataset: dataset}

      opts = %{
        expectations: [
          expect_column_to_exist(:features),
          expect_column_to_exist(:label),
          expect_column_values_to_be_unique(:id),
          expect_no_missing_values(:label),
          expect_label_balance(:label, min_ratio: 0.25),
          expect_table_row_count_to_be_between(2, 1000)
        ],
        profile: true
      }

      result = Stage.run(context, opts)

      assert result.data_validation.passed == true
      assert result.data_validation.profile != nil
      assert result.data_validation.profile.row_count == 4
    end

    test "handles temporal data validation" do
      dataset = [
        %{timestamp: ~U[2025-01-01 10:00:00Z], value: 100},
        %{timestamp: ~U[2025-01-01 11:00:00Z], value: 110},
        %{timestamp: ~U[2025-01-01 12:00:00Z], value: 105}
      ]

      context = %{dataset: dataset}

      opts = %{
        expectations: [
          expect_column_values_to_be_valid_timestamps(:timestamp),
          expect_column_timestamps_to_be_chronological(:timestamp),
          expect_column_values_to_be_between(:value, 0, 200)
        ]
      }

      result = Stage.run(context, opts)

      assert result.data_validation.passed == true
    end

    test "handles string format validation" do
      dataset = [
        %{email: "alice@example.com", url: "https://example.com"},
        %{email: "bob@example.com", url: "https://test.com"}
      ]

      context = %{dataset: dataset}

      opts = %{
        expectations: [
          expect_column_values_to_be_valid_emails(:email),
          expect_column_values_to_be_valid_urls(:url, schemes: [:https])
        ]
      }

      result = Stage.run(context, opts)

      assert result.data_validation.passed == true
    end
  end

  describe "validation result structure" do
    test "includes all required fields in data_validation" do
      dataset = [%{age: 25}]
      context = %{dataset: dataset}

      opts = %{
        expectations: [expect_column_to_exist(:age)]
      }

      result = Stage.run(context, opts)

      validation = result.data_validation

      assert Map.has_key?(validation, :validation_result)
      assert Map.has_key?(validation, :profile)
      assert Map.has_key?(validation, :passed)
      assert Map.has_key?(validation, :expectations_met)
      assert Map.has_key?(validation, :expectations_failed)
      assert Map.has_key?(validation, :total_expectations)
    end

    test "validation_result contains proper ValidationResult struct" do
      dataset = [%{age: 25}]
      context = %{dataset: dataset}

      opts = %{
        expectations: [expect_column_to_exist(:age)]
      }

      result = Stage.run(context, opts)

      validation_result = result.data_validation.validation_result

      assert %ExDataCheck.ValidationResult{} = validation_result
      assert validation_result.success == true
      assert is_list(validation_result.results)
      assert validation_result.total_expectations == 1
    end
  end
end
