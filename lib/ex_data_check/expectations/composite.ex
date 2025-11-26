defmodule ExDataCheck.Expectations.Composite do
  @moduledoc """
  Composite expectations for logical combination of validations.

  Allows expressing complex business rules through logical composition:
  - AND logic (all must pass)
  - OR logic (any must pass)
  - Threshold logic (at least N must pass)

  ## Examples

      # All expectations must pass
      expect_all([
        expect_column_to_exist(:age),
        expect_column_values_to_be_between(:age, 0, 120)
      ])

      # At least one must pass
      expect_any([
        expect_column_values_to_be_valid_emails(:contact),
        expect_column_values_to_match_format(:contact, :us_phone)
      ])

      # At least 2 of 3 must pass
      expect_at_least(2, [
        expect_no_missing_values(:features),
        expect_column_mean_to_be_between(:score, 0.7, 1.0),
        expect_label_balance(:target, min_ratio: 0.3)
      ])

  """

  alias ExDataCheck.{Expectation, ExpectationResult}

  @doc """
  Expects all provided expectations to pass (logical AND).

  ## Parameters

    * `expectations` - List of expectations

  ## Examples

      expect_all([
        expect_column_to_exist(:age),
        expect_column_values_to_be_between(:age, 0, 120)
      ])

  """
  @spec expect_all(list(Expectation.t())) :: Expectation.t()
  def expect_all(expectations) do
    validator = fn dataset ->
      results = Enum.map(expectations, & &1.validator.(dataset))
      passed = Enum.count(results, & &1.success)
      failed = length(results) - passed

      observed = %{
        total_expectations: length(expectations),
        passed: passed,
        failed: failed,
        all_results: results
      }

      ExpectationResult.new(
        failed == 0,
        "expect all #{length(expectations)} expectations to pass",
        observed,
        %{logic: :and, expectations: expectations}
      )
    end

    Expectation.new(:composite_all, :all, validator, %{expectations: expectations})
  end

  @doc """
  Expects at least one expectation to pass (logical OR).

  ## Parameters

    * `expectations` - List of expectations

  ## Examples

      expect_any([
        expect_column_values_to_be_valid_emails(:contact),
        expect_column_values_to_match_format(:contact, :us_phone)
      ])

  """
  @spec expect_any(list(Expectation.t())) :: Expectation.t()
  def expect_any(expectations) do
    validator = fn dataset ->
      results = Enum.map(expectations, & &1.validator.(dataset))
      passed = Enum.count(results, & &1.success)

      observed = %{
        total_expectations: length(expectations),
        passed: passed,
        failed: length(results) - passed,
        all_results: results
      }

      ExpectationResult.new(
        passed > 0,
        "expect at least one of #{length(expectations)} expectations to pass",
        observed,
        %{logic: :or, expectations: expectations}
      )
    end

    Expectation.new(:composite_any, :any, validator, %{expectations: expectations})
  end

  @doc """
  Expects at least N expectations to pass (threshold logic).

  ## Parameters

    * `min_passing` - Minimum number of expectations that must pass
    * `expectations` - List of expectations

  ## Examples

      expect_at_least(2, [
        expect_no_missing_values(:features),
        expect_column_mean_to_be_between(:score, 0.7, 1.0),
        expect_label_balance(:target, min_ratio: 0.3)
      ])

  """
  @spec expect_at_least(non_neg_integer(), list(Expectation.t())) :: Expectation.t()
  def expect_at_least(min_passing, expectations) do
    validator = fn dataset ->
      results = Enum.map(expectations, & &1.validator.(dataset))
      passed = Enum.count(results, & &1.success)

      observed = %{
        total_expectations: length(expectations),
        passed: passed,
        failed: length(results) - passed,
        min_required: min_passing,
        all_results: results
      }

      ExpectationResult.new(
        passed >= min_passing,
        "expect at least #{min_passing} of #{length(expectations)} expectations to pass",
        observed,
        %{logic: :threshold, min_passing: min_passing, expectations: expectations}
      )
    end

    Expectation.new(:composite_threshold, :threshold, validator, %{
      min_passing: min_passing,
      expectations: expectations
    })
  end
end
