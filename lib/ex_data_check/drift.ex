defmodule ExDataCheck.Drift do
  @moduledoc """
  Data drift detection for ML model monitoring.

  Drift detection identifies when the distribution of production data differs
  significantly from training data, which can degrade model performance.

  ## Drift Detection Methods

  - **Kolmogorov-Smirnov (KS)**: For continuous numerical features
  - **Chi-Square**: For categorical features
  - **Population Stability Index (PSI)**: Industry-standard metric

  ## Workflow

  1. Create baseline from training/reference data
  2. Detect drift in production/current data
  3. Monitor drift scores over time
  4. Retrain model when significant drift detected

  ## Examples

      # Create baseline from training data
      baseline = ExDataCheck.Drift.create_baseline(training_data)

      # Check production data for drift
      drift_result = ExDataCheck.Drift.detect(production_data, baseline)

      case drift_result do
        %{drifted: true} = r ->
          IO.puts("Drift detected in columns")
          trigger_model_retraining()
        _ ->
          :ok
      end

  """

  alias ExDataCheck.{DriftResult, Statistics}
  alias ExDataCheck.Validator.ColumnExtractor

  @default_threshold 0.05

  @typedoc """
  Baseline distribution for a column.

  For numeric columns:
  - `:type` - :numeric
  - `:values` - List of baseline values
  - `:mean` - Baseline mean
  - `:stdev` - Baseline standard deviation

  For categorical columns:
  - `:type` - :categorical
  - `:frequencies` - Map of value frequencies
  """
  @type baseline_column :: map()

  @typedoc """
  Complete baseline for all columns.
  """
  @type baseline :: %{optional(atom() | String.t()) => baseline_column()}

  @doc """
  Creates a baseline distribution from a reference dataset.

  The baseline captures the distribution of each column for later comparison.

  ## Parameters

    * `dataset` - Reference dataset (typically training data)

  ## Returns

  Map of column names to baseline statistics.

  ## Examples

      iex> dataset = [%{age: 25}, %{age: 30}, %{age: 35}]
      iex> baseline = ExDataCheck.Drift.create_baseline(dataset)
      iex> baseline[:age].type
      :numeric

  """
  @spec create_baseline(list(map())) :: baseline()
  def create_baseline(dataset) do
    columns = ColumnExtractor.columns(dataset)

    columns
    |> Enum.map(fn column ->
      {column, create_column_baseline(dataset, column)}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Detects drift between current data and baseline.

  Compares the distribution of current data against the baseline and
  identifies columns that have drifted significantly.

  ## Parameters

    * `dataset` - Current dataset to check for drift
    * `baseline` - Baseline created from reference data
    * `opts` - Options
      * `:threshold` - Drift score threshold (default: 0.05)
      * `:method` - Detection method (`:auto`, `:ks`, `:psi`, default: :auto)

  ## Returns

  `DriftResult` struct with drift detection results.

  ## Examples

      iex> baseline = ExDataCheck.Drift.create_baseline(training_data)
      iex> result = ExDataCheck.Drift.detect(production_data, baseline)
      iex> result.drifted
      false

  """
  @spec detect(list(map()), baseline(), keyword()) :: DriftResult.t()
  def detect(dataset, baseline, opts \\ []) do
    threshold = Keyword.get(opts, :threshold, @default_threshold)
    method = Keyword.get(opts, :method, :auto)

    drift_scores =
      baseline
      |> Enum.map(fn {column, column_baseline} ->
        score = detect_column_drift(dataset, column, column_baseline, method)
        {column, score}
      end)
      |> Enum.into(%{})

    DriftResult.new(drift_scores, threshold, method)
  end

  @doc """
  Performs two-sample Kolmogorov-Smirnov test.

  Tests whether two samples come from the same distribution.

  ## Returns

  Tuple of `{ks_statistic, p_value}`.

  ## Examples

      iex> dist1 = [1, 2, 3, 4, 5]
      iex> dist2 = [1, 2, 3, 4, 5]
      iex> {stat, p} = ExDataCheck.Drift.ks_test(dist1, dist2)
      iex> stat
      0.0

  """
  @spec ks_test(list(number()), list(number())) :: {float(), float()}
  def ks_test(dist1, dist2) do
    sorted1 = Enum.sort(dist1)
    sorted2 = Enum.sort(dist2)

    n1 = length(sorted1)
    n2 = length(sorted2)

    # Combine and sort all values
    all_values = (sorted1 ++ sorted2) |> Enum.sort() |> Enum.uniq()

    # Calculate maximum difference between empirical CDFs
    ks_statistic =
      all_values
      |> Enum.map(fn value ->
        # Count values <= value in each distribution
        cdf1 = Enum.count(sorted1, fn v -> v <= value end) / n1
        cdf2 = Enum.count(sorted2, fn v -> v <= value end) / n2

        abs(cdf1 - cdf2)
      end)
      |> Enum.max(fn -> 0.0 end)

    # Approximate p-value using Kolmogorov distribution
    effective_n = n1 * n2 / (n1 + n2)
    lambda = ks_statistic * :math.sqrt(effective_n)
    p_value = kolmogorov_cdf(lambda)

    {ks_statistic, p_value}
  end

  @doc """
  Calculates Population Stability Index (PSI) between two distributions.

  PSI measures distribution shift, commonly used in credit scoring and ML monitoring.

  PSI Interpretation:
  - PSI < 0.1: No significant shift
  - 0.1 <= PSI < 0.2: Moderate shift
  - PSI >= 0.2: Significant shift

  ## Parameters

    * `baseline_dist` - Map of categories to baseline proportions
    * `current_dist` - Map of categories to current proportions

  ## Examples

      iex> baseline = %{"A" => 0.5, "B" => 0.5}
      iex> current = %{"A" => 0.5, "B" => 0.5}
      iex> ExDataCheck.Drift.psi(baseline, current)
      0.0

  """
  @spec psi(map(), map()) :: float()
  def psi(baseline_dist, current_dist) do
    all_categories =
      (Map.keys(baseline_dist) ++ Map.keys(current_dist))
      |> Enum.uniq()

    all_categories
    |> Enum.map(fn category ->
      baseline_pct = Map.get(baseline_dist, category, 0.001)
      current_pct = Map.get(current_dist, category, 0.001)

      # PSI formula: (current% - baseline%) * ln(current% / baseline%)
      (current_pct - baseline_pct) * :math.log(current_pct / baseline_pct)
    end)
    |> Enum.sum()
  end

  # Private functions

  @spec create_column_baseline(list(map()), atom() | String.t()) :: baseline_column()
  defp create_column_baseline(dataset, column) do
    values =
      dataset
      |> ColumnExtractor.extract(column)
      |> Enum.reject(&is_nil/1)

    if is_numeric_column?(values) do
      %{
        type: :numeric,
        values: values,
        mean: Statistics.mean(values),
        stdev: Statistics.stdev(values)
      }
    else
      frequencies = Enum.frequencies(values)

      %{
        type: :categorical,
        frequencies: frequencies,
        total: length(values)
      }
    end
  end

  @spec detect_column_drift(list(map()), atom() | String.t(), baseline_column(), atom()) ::
          float()
  defp detect_column_drift(dataset, column, column_baseline, method) do
    current_values =
      dataset
      |> ColumnExtractor.extract(column)
      |> Enum.reject(&is_nil/1)

    case {column_baseline.type, method} do
      {:numeric, _} ->
        detect_numeric_drift(current_values, column_baseline)

      {:categorical, _} ->
        detect_categorical_drift(current_values, column_baseline)
    end
  end

  @spec detect_numeric_drift(list(number()), baseline_column()) :: float()
  defp detect_numeric_drift(current_values, baseline) do
    # Use KS test
    {ks_statistic, _p_value} = ks_test(baseline.values, current_values)
    ks_statistic
  end

  @spec detect_categorical_drift(list(any()), baseline_column()) :: float()
  defp detect_categorical_drift(current_values, baseline) do
    # Calculate current distribution
    current_freq = Enum.frequencies(current_values)
    current_total = length(current_values)

    baseline_dist =
      baseline.frequencies
      |> Enum.map(fn {cat, count} -> {cat, count / baseline.total} end)
      |> Enum.into(%{})

    current_dist =
      current_freq
      |> Enum.map(fn {cat, count} -> {cat, count / current_total} end)
      |> Enum.into(%{})

    # Use PSI
    psi(baseline_dist, current_dist)
  end

  @spec is_numeric_column?(list(any())) :: boolean()
  defp is_numeric_column?([]), do: false

  defp is_numeric_column?(values) do
    sample = Enum.take(values, 10)
    Enum.all?(sample, &is_number/1)
  end

  # Approximate Kolmogorov CDF (returns 1 - p_value)
  @spec kolmogorov_cdf(float()) :: float()
  defp kolmogorov_cdf(lambda) when lambda < 0, do: 0.0

  defp kolmogorov_cdf(lambda) do
    # Simplified approximation
    sum =
      1..10
      |> Enum.map(fn k ->
        :math.pow(-1, k - 1) * :math.exp(-2 * k * k * lambda * lambda)
      end)
      |> Enum.sum()

    max(0.0, min(1.0, 1.0 - 2 * sum))
  end
end
