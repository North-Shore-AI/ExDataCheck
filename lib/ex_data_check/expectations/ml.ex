defmodule ExDataCheck.Expectations.ML do
  @moduledoc """
  ML-specific expectations for machine learning workflows.

  Provides expectations tailored for ML use cases:
  - Label balance checking for classification tasks
  - Label cardinality validation
  - Feature correlation analysis
  - Missing value detection (critical for ML)
  - Dataset size validation

  ## Examples

      # Check label balance for classification
      expect_label_balance(:target, min_ratio: 0.2)

      # Ensure reasonable number of classes
      expect_label_cardinality(:target, min: 2, max: 10)

      # Detect highly correlated features
      expect_feature_correlation(:feature1, :feature2, max: 0.95)

      # Ensure no missing values (critical for many ML algorithms)
      expect_no_missing_values(:features)

      # Validate dataset size
      expect_table_row_count_to_be_between(1000, 1_000_000)

  ## Design Principles

  - **ML-Aware**: Designed specifically for ML pipeline needs
  - **Practical Defaults**: Sensible defaults based on ML best practices
  - **Detailed Diagnostics**: Provides actionable information for fixing issues

  """

  alias ExDataCheck.{Expectation, ExpectationResult, Correlation}
  alias ExDataCheck.Validator.ColumnExtractor

  @doc """
  Expects labels to be reasonably balanced across classes.

  Important for classification tasks to avoid model bias. Checks that the
  smallest class represents at least `min_ratio` of the dataset.

  ## Parameters

    * `column` - Label column name
    * `opts` - Options
      * `:min_ratio` - Minimum ratio for smallest class (default: 0.1 or 10%)

  ## Examples

      iex> dataset = [%{target: 0}, %{target: 1}, %{target: 0}, %{target: 1}]
      iex> expectation = ExDataCheck.Expectations.ML.expect_label_balance(:target, min_ratio: 0.4)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

  """
  @spec expect_label_balance(atom() | String.t(), keyword()) :: Expectation.t()
  def expect_label_balance(column, opts \\ []) do
    min_ratio = Keyword.get(opts, :min_ratio, 0.1)

    validator = fn dataset ->
      labels =
        dataset
        |> ColumnExtractor.extract(column)
        |> Enum.reject(&is_nil/1)

      class_distribution = Enum.frequencies(labels)
      num_classes = map_size(class_distribution)
      total = length(labels)

      min_class_count = if num_classes > 0, do: Enum.min(Map.values(class_distribution)), else: 0
      min_class_ratio = if total > 0, do: min_class_count / total, else: 0.0

      success = min_class_ratio >= min_ratio

      observed = %{
        num_classes: num_classes,
        total_samples: total,
        min_class_count: min_class_count,
        min_class_ratio: min_class_ratio,
        class_distribution: class_distribution,
        min_ratio_threshold: min_ratio
      }

      ExpectationResult.new(
        success,
        "expect column #{inspect(column)} label balance >= #{min_ratio}",
        observed,
        %{min_ratio: min_ratio}
      )
    end

    Expectation.new(:label_balance, column, validator, %{min_ratio: min_ratio})
  end

  @doc """
  Expects the number of unique labels to fall within a specified range.

  Useful for validating classification tasks have reasonable number of classes.

  ## Parameters

    * `column` - Label column name
    * `opts` - Options
      * `:min` - Minimum number of unique labels (default: 2)
      * `:max` - Maximum number of unique labels (default: 100)

  ## Examples

      iex> dataset = [%{target: "A"}, %{target: "B"}, %{target: "C"}]
      iex> expectation = ExDataCheck.Expectations.ML.expect_label_cardinality(:target, min: 2, max: 5)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

  """
  @spec expect_label_cardinality(atom() | String.t(), keyword()) :: Expectation.t()
  def expect_label_cardinality(column, opts \\ []) do
    min = Keyword.get(opts, :min, 2)
    max = Keyword.get(opts, :max, 100)

    validator = fn dataset ->
      labels =
        dataset
        |> ColumnExtractor.extract(column)
        |> Enum.reject(&is_nil/1)

      cardinality = labels |> Enum.uniq() |> length()
      success = cardinality >= min and cardinality <= max

      observed = %{
        cardinality: cardinality,
        min_expected: min,
        max_expected: max
      }

      ExpectationResult.new(
        success,
        "expect column #{inspect(column)} to have #{min}-#{max} unique labels",
        observed,
        %{min: min, max: max}
      )
    end

    Expectation.new(:label_cardinality, column, validator, %{min: min, max: max})
  end

  @doc """
  Expects correlation between two features to be within bounds.

  Helps detect feature redundancy or collinearity issues in ML models.

  ## Parameters

    * `column1` - First feature column
    * `column2` - Second feature column
    * `opts` - Options
      * `:max` - Maximum absolute correlation (default: 0.95)
      * `:min` - Minimum absolute correlation (default: nil)

  ## Examples

      iex> dataset = [%{f1: 1, f2: 10}, %{f1: 2, f2: 12}, %{f1: 3, f2: 35}]
      iex> expectation = ExDataCheck.Expectations.ML.expect_feature_correlation(:f1, :f2, max: 0.95)
      iex> result = expectation.validator.(dataset)
      iex> is_boolean(result.success)
      true

  """
  @spec expect_feature_correlation(atom() | String.t(), atom() | String.t(), keyword()) ::
          Expectation.t()
  def expect_feature_correlation(column1, column2, opts \\ []) do
    max = Keyword.get(opts, :max, 0.95)
    min = Keyword.get(opts, :min)

    validator = fn dataset ->
      values1 =
        dataset
        |> ColumnExtractor.extract(column1)
        |> Enum.reject(&is_nil/1)

      values2 =
        dataset
        |> ColumnExtractor.extract(column2)
        |> Enum.reject(&is_nil/1)

      correlation = Correlation.pearson(values1, values2)
      abs_correlation = if correlation, do: abs(correlation), else: nil

      success =
        cond do
          abs_correlation == nil -> false
          min != nil and abs_correlation < min -> false
          abs_correlation > max -> false
          true -> true
        end

      observed = %{
        correlation: correlation,
        abs_correlation: abs_correlation,
        max_threshold: max,
        min_threshold: min
      }

      message =
        if min do
          "expect correlation between #{inspect(column1)} and #{inspect(column2)} to be between #{min} and #{max}"
        else
          "expect correlation between #{inspect(column1)} and #{inspect(column2)} to be <= #{max}"
        end

      ExpectationResult.new(
        success,
        message,
        observed,
        %{max: max, min: min}
      )
    end

    Expectation.new(:feature_correlation, nil, validator, %{
      column1: column1,
      column2: column2,
      max: max,
      min: min
    })
  end

  @doc """
  Expects no missing (nil) values in a column.

  Alias for `expect_column_values_to_not_be_null/1` but with ML-specific
  naming. Many ML algorithms cannot handle missing values.

  ## Parameters

    * `column` - Column name

  ## Examples

      iex> dataset = [%{features: [1, 2, 3]}, %{features: [4, 5, 6]}]
      iex> expectation = ExDataCheck.Expectations.ML.expect_no_missing_values(:features)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

  """
  @spec expect_no_missing_values(atom() | String.t()) :: Expectation.t()
  def expect_no_missing_values(column) do
    validator = fn dataset ->
      values = ColumnExtractor.extract(dataset, column)
      missing_count = Enum.count(values, &is_nil/1)

      observed = %{
        total_values: length(values),
        missing_count: missing_count,
        completeness:
          if(length(values) > 0, do: (length(values) - missing_count) / length(values), else: 0.0)
      }

      ExpectationResult.new(
        missing_count == 0,
        "expect no missing values in column #{inspect(column)}",
        observed,
        %{column: column}
      )
    end

    Expectation.new(:no_missing, column, validator, %{})
  end

  @doc """
  Expects the dataset to have a row count within a specified range.

  Important for ML to ensure sufficient training data while avoiding
  computational issues with very large datasets.

  ## Parameters

    * `min` - Minimum row count
    * `max` - Maximum row count

  ## Examples

      iex> dataset = Enum.map(1..500, fn i -> %{id: i} end)
      iex> expectation = ExDataCheck.Expectations.ML.expect_table_row_count_to_be_between(100, 1000)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

  """
  @spec expect_table_row_count_to_be_between(non_neg_integer(), non_neg_integer()) ::
          Expectation.t()
  def expect_table_row_count_to_be_between(min, max) do
    validator = fn dataset ->
      row_count = length(dataset)
      success = row_count >= min and row_count <= max

      observed = %{
        row_count: row_count,
        min_expected: min,
        max_expected: max
      }

      ExpectationResult.new(
        success,
        "expect table to have #{min}-#{max} rows",
        observed,
        %{min: min, max: max}
      )
    end

    Expectation.new(:row_count_range, nil, validator, %{min: min, max: max})
  end
end
