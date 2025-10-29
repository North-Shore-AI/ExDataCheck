#!/usr/bin/env elixir

# ExDataCheck - Basic Validation Example
#
# This example demonstrates basic data validation with schema and value expectations.
# Run with: mix run examples/basic_validation.exs

# Import convenience functions
import ExDataCheck

IO.puts("\n=== ExDataCheck Basic Validation Example ===\n")

# Sample dataset: User information
dataset = [
  %{
    id: 1,
    name: "Alice Johnson",
    age: 25,
    email: "alice@example.com",
    score: 0.85,
    status: "active"
  },
  %{id: 2, name: "Bob Smith", age: 30, email: "bob@example.com", score: 0.92, status: "active"},
  %{
    id: 3,
    name: "Charlie Brown",
    age: 35,
    email: "charlie@example.com",
    score: 0.78,
    status: "pending"
  },
  %{
    id: 4,
    name: "Diana Prince",
    age: 28,
    email: "diana@example.com",
    score: 0.88,
    status: "active"
  },
  %{id: 5, name: "Eve Adams", age: 32, email: "eve@example.com", score: 0.95, status: "active"}
]

IO.puts("Dataset: #{length(dataset)} users")
IO.puts("Columns: #{dataset |> List.first() |> Map.keys() |> Enum.join(", ")}\n")

# Define comprehensive expectations
expectations = [
  # Schema expectations - verify structure
  expect_column_to_exist(:id),
  expect_column_to_exist(:name),
  expect_column_to_exist(:age),
  expect_column_to_exist(:email),
  expect_column_to_exist(:score),
  expect_column_to_exist(:status),
  expect_column_count_to_equal(6),

  # Type expectations
  expect_column_to_be_of_type(:id, :integer),
  expect_column_to_be_of_type(:name, :string),
  expect_column_to_be_of_type(:age, :integer),
  expect_column_to_be_of_type(:email, :string),
  expect_column_to_be_of_type(:score, :float),
  expect_column_to_be_of_type(:status, :string),

  # Value expectations - business rules
  expect_column_values_to_be_between(:age, 18, 100),
  expect_column_values_to_be_between(:score, 0.0, 1.0),
  expect_column_values_to_be_in_set(:status, ["active", "pending", "inactive"]),
  expect_column_values_to_match_regex(:email, ~r/^[^@]+@[^@]+\.[^@]+$/),
  expect_column_values_to_not_be_null(:id),
  expect_column_values_to_not_be_null(:name),
  expect_column_values_to_not_be_null(:email),
  expect_column_values_to_be_unique(:id),
  expect_column_values_to_be_unique(:email),

  # Statistical expectations
  expect_column_mean_to_be_between(:age, 25, 35),
  expect_column_mean_to_be_between(:score, 0.7, 1.0),

  # ML expectations
  expect_table_row_count_to_be_between(1, 100)
]

IO.puts("Running validation with #{length(expectations)} expectations...\n")

# Validate the dataset
result = ExDataCheck.validate(dataset, expectations)

# Display results
IO.puts("=== Validation Results ===")
IO.puts("Overall Status: #{if result.success, do: "✓ SUCCESS", else: "✗ FAILED"}")
IO.puts("Total Expectations: #{result.total_expectations}")
IO.puts("Expectations Met: #{result.expectations_met}")
IO.puts("Expectations Failed: #{result.expectations_failed}")
IO.puts("")

if result.success do
  IO.puts("All data quality checks passed! The dataset is valid.")
else
  IO.puts("Some expectations failed:\n")

  result
  |> ExDataCheck.ValidationResult.failed_expectations()
  |> Enum.each(fn failed ->
    IO.puts("  ✗ #{failed.expectation}")

    if failed.metadata[:details] do
      IO.puts("    Details: #{inspect(failed.metadata[:details])}")
    end
  end)
end

# Example with intentional failures
IO.puts("\n\n=== Example with Invalid Data ===\n")

invalid_dataset = [
  %{id: 1, name: "User1", age: 150, email: "invalid-email", score: 1.5, status: "unknown"},
  # duplicate id
  %{id: 1, name: "User2", age: -5, email: "user2@test.com", score: 0.5, status: "active"}
]

IO.puts("Dataset with invalid data: #{length(invalid_dataset)} rows\n")

result2 = ExDataCheck.validate(invalid_dataset, expectations)

IO.puts("=== Validation Results ===")
IO.puts("Overall Status: #{if result2.success, do: "✓ SUCCESS", else: "✗ FAILED"}")
IO.puts("Total Expectations: #{result2.total_expectations}")
IO.puts("Expectations Met: #{result2.expectations_met}")
IO.puts("Expectations Failed: #{result2.expectations_failed}")
IO.puts("")

if not result2.success do
  IO.puts("Failed expectations:\n")

  result2
  |> ExDataCheck.ValidationResult.failed_expectations()
  |> Enum.with_index(1)
  |> Enum.each(fn {failed, idx} ->
    IO.puts("  #{idx}. #{failed.expectation}")
  end)
end

# Demonstrate validate! (raises on failure)
IO.puts("\n\n=== Using validate! (exception on failure) ===\n")

try do
  ExDataCheck.validate!(invalid_dataset, [
    expect_column_values_to_be_between(:age, 18, 100)
  ])

  IO.puts("Validation passed")
rescue
  e in ExDataCheck.ValidationError ->
    IO.puts("Caught ValidationError:")
    IO.puts("  Message: #{Exception.message(e)}")
    IO.puts("  Failed: #{e.result.expectations_failed} expectations")
end

IO.puts("\n=== Example Complete ===\n")
