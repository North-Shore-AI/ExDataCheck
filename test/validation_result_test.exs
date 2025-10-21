defmodule ExDataCheck.ValidationResultTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExDataCheck.{ValidationResult, ExpectationResult}

  describe "ValidationResult struct" do
    test "creates a successful validation result" do
      results = [
        ExpectationResult.new(true, "column exists", %{found: true}),
        ExpectationResult.new(true, "values in range", %{total: 100, failing: 0})
      ]

      validation_result = %ValidationResult{
        success: true,
        total_expectations: 2,
        expectations_met: 2,
        expectations_failed: 0,
        results: results,
        dataset_info: %{row_count: 100, column_count: 3},
        timestamp: DateTime.utc_now()
      }

      assert validation_result.success == true
      assert validation_result.total_expectations == 2
      assert validation_result.expectations_met == 2
      assert validation_result.expectations_failed == 0
      assert length(validation_result.results) == 2
    end

    test "creates a failed validation result" do
      results = [
        ExpectationResult.new(true, "column exists", %{found: true}),
        ExpectationResult.new(false, "values in range", %{total: 100, failing: 5})
      ]

      validation_result = %ValidationResult{
        success: false,
        total_expectations: 2,
        expectations_met: 1,
        expectations_failed: 1,
        results: results,
        dataset_info: %{row_count: 100, column_count: 3},
        timestamp: DateTime.utc_now()
      }

      assert validation_result.success == false
      assert validation_result.expectations_met == 1
      assert validation_result.expectations_failed == 1
    end
  end

  describe "new/2" do
    test "creates validation result from expectation results" do
      results = [
        ExpectationResult.new(true, "test 1", %{}),
        ExpectationResult.new(true, "test 2", %{})
      ]

      dataset_info = %{row_count: 50, column_count: 5}

      validation_result = ValidationResult.new(results, dataset_info)

      assert %ValidationResult{} = validation_result
      assert validation_result.success == true
      assert validation_result.total_expectations == 2
      assert validation_result.expectations_met == 2
      assert validation_result.expectations_failed == 0
      assert validation_result.results == results
      assert validation_result.dataset_info == dataset_info
      assert %DateTime{} = validation_result.timestamp
    end

    test "marks validation as failed if any expectation fails" do
      results = [
        ExpectationResult.new(true, "test 1", %{}),
        ExpectationResult.new(false, "test 2", %{}),
        ExpectationResult.new(true, "test 3", %{})
      ]

      dataset_info = %{row_count: 50, column_count: 5}

      validation_result = ValidationResult.new(results, dataset_info)

      assert validation_result.success == false
      assert validation_result.total_expectations == 3
      assert validation_result.expectations_met == 2
      assert validation_result.expectations_failed == 1
    end

    test "handles empty results list" do
      validation_result = ValidationResult.new([], %{row_count: 0})

      assert validation_result.success == true
      assert validation_result.total_expectations == 0
      assert validation_result.expectations_met == 0
      assert validation_result.expectations_failed == 0
    end
  end

  describe "success?/1" do
    test "returns true when all expectations pass" do
      results = [
        ExpectationResult.new(true, "test 1", %{}),
        ExpectationResult.new(true, "test 2", %{})
      ]

      validation_result = ValidationResult.new(results, %{})

      assert ValidationResult.success?(validation_result) == true
    end

    test "returns false when any expectation fails" do
      results = [
        ExpectationResult.new(true, "test 1", %{}),
        ExpectationResult.new(false, "test 2", %{})
      ]

      validation_result = ValidationResult.new(results, %{})

      assert ValidationResult.success?(validation_result) == false
    end
  end

  describe "failed?/1" do
    test "returns false when all expectations pass" do
      results = [ExpectationResult.new(true, "test", %{})]

      validation_result = ValidationResult.new(results, %{})

      assert ValidationResult.failed?(validation_result) == false
    end

    test "returns true when any expectation fails" do
      results = [
        ExpectationResult.new(true, "test 1", %{}),
        ExpectationResult.new(false, "test 2", %{})
      ]

      validation_result = ValidationResult.new(results, %{})

      assert ValidationResult.failed?(validation_result) == true
    end
  end

  describe "failed_expectations/1" do
    test "returns only failed expectation results" do
      results = [
        ExpectationResult.new(true, "test 1", %{}),
        ExpectationResult.new(false, "test 2", %{}),
        ExpectationResult.new(false, "test 3", %{}),
        ExpectationResult.new(true, "test 4", %{})
      ]

      validation_result = ValidationResult.new(results, %{})
      failed = ValidationResult.failed_expectations(validation_result)

      assert length(failed) == 2
      assert Enum.all?(failed, &(&1.success == false))
    end

    test "returns empty list when all expectations pass" do
      results = [
        ExpectationResult.new(true, "test 1", %{}),
        ExpectationResult.new(true, "test 2", %{})
      ]

      validation_result = ValidationResult.new(results, %{})
      failed = ValidationResult.failed_expectations(validation_result)

      assert failed == []
    end
  end

  describe "passed_expectations/1" do
    test "returns only passed expectation results" do
      results = [
        ExpectationResult.new(true, "test 1", %{}),
        ExpectationResult.new(false, "test 2", %{}),
        ExpectationResult.new(true, "test 3", %{})
      ]

      validation_result = ValidationResult.new(results, %{})
      passed = ValidationResult.passed_expectations(validation_result)

      assert length(passed) == 2
      assert Enum.all?(passed, &(&1.success == true))
    end

    test "returns empty list when all expectations fail" do
      results = [
        ExpectationResult.new(false, "test 1", %{}),
        ExpectationResult.new(false, "test 2", %{})
      ]

      validation_result = ValidationResult.new(results, %{})
      passed = ValidationResult.passed_expectations(validation_result)

      assert passed == []
    end
  end

  property "success and failed are inverse" do
    check all(success_list <- list_of(boolean(), min_length: 1)) do
      results =
        Enum.map(success_list, fn success ->
          ExpectationResult.new(success, "test", %{})
        end)

      validation_result = ValidationResult.new(results, %{})

      assert ValidationResult.success?(validation_result) ==
               !ValidationResult.failed?(validation_result)
    end
  end

  property "failed expectations count matches expectations_failed field" do
    check all(success_list <- list_of(boolean(), min_length: 1)) do
      results =
        Enum.map(success_list, fn success ->
          ExpectationResult.new(success, "test", %{})
        end)

      validation_result = ValidationResult.new(results, %{})
      failed = ValidationResult.failed_expectations(validation_result)

      assert length(failed) == validation_result.expectations_failed
    end
  end
end
