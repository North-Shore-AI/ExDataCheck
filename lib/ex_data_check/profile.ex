defmodule ExDataCheck.Profile do
  @moduledoc """
  Data profiling results and statistics.

  A Profile provides comprehensive statistical analysis of a dataset including:
  - Row and column counts
  - Column-level statistics (types, min/max, mean, cardinality)
  - Missing value analysis
  - Overall data quality score
  - Timestamp of profiling

  ## Examples

      iex> dataset = [%{age: 25, name: "Alice"}, %{age: 30, name: "Bob"}]
      iex> profile = ExDataCheck.profile(dataset)
      iex> profile.row_count
      2
      iex> profile.column_count
      2

  ## Quality Score

  The quality score is calculated based on data completeness:
  - 1.0 = Perfect data (no missing values)
  - 0.0 = All values missing
  - Values in between indicate the percentage of non-missing data

  ## Export Formats

  Profiles can be exported to multiple formats:

      # JSON export
      json = ExDataCheck.Profile.to_json(profile)

      # Markdown export
      markdown = ExDataCheck.Profile.to_markdown(profile)

  """

  @typedoc """
  Column profile containing statistics for a single column.

  Common fields:
  - `:type` - Inferred type (`:integer`, `:float`, `:string`, etc.)
  - `:missing` - Count of missing values
  - `:cardinality` - Number of unique values
  - `:min` - Minimum value (for numeric columns)
  - `:max` - Maximum value (for numeric columns)
  - `:mean` - Mean value (for numeric columns)
  - `:median` - Median value (for numeric columns)
  - `:stdev` - Standard deviation (for numeric columns)
  """
  @type column_profile :: map()

  @type t :: %__MODULE__{
          row_count: non_neg_integer(),
          column_count: non_neg_integer(),
          columns: %{optional(atom() | String.t()) => column_profile()},
          missing_values: %{optional(atom() | String.t()) => non_neg_integer()},
          quality_score: float(),
          timestamp: DateTime.t()
        }

  defstruct [
    :row_count,
    :column_count,
    :columns,
    :missing_values,
    :quality_score,
    :timestamp
  ]

  @doc """
  Creates a new Profile from row count and column profiles.

  Automatically calculates:
  - Column count
  - Missing values map
  - Quality score
  - Current timestamp

  ## Parameters

    * `row_count` - Total number of rows in the dataset
    * `column_profiles` - Map of column names to their profile statistics

  ## Examples

      iex> column_profiles = %{
      ...>   age: %{type: :integer, min: 25, max: 35, missing: 0},
      ...>   name: %{type: :string, cardinality: 10, missing: 2}
      ...> }
      iex> profile = ExDataCheck.Profile.new(10, column_profiles)
      iex> profile.row_count
      10
      iex> profile.column_count
      2
      iex> profile.missing_values
      %{age: 0, name: 2}

  """
  @spec new(non_neg_integer(), %{optional(atom() | String.t()) => column_profile()}) :: t()
  def new(row_count, column_profiles) do
    missing_values = extract_missing_values(column_profiles)
    quality_score = calculate_quality_score(row_count, column_profiles)

    %__MODULE__{
      row_count: row_count,
      column_count: map_size(column_profiles),
      columns: column_profiles,
      missing_values: missing_values,
      quality_score: quality_score,
      timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Returns the quality score of the profile.

  ## Examples

      iex> profile = %ExDataCheck.Profile{quality_score: 0.95}
      iex> ExDataCheck.Profile.quality_score(profile)
      0.95

  """
  @spec quality_score(t()) :: float()
  def quality_score(%__MODULE__{quality_score: score}), do: score

  @doc """
  Exports the profile to a JSON string.

  ## Examples

      iex> profile = %ExDataCheck.Profile{
      ...>   row_count: 10,
      ...>   column_count: 2,
      ...>   columns: %{age: %{type: :integer}},
      ...>   missing_values: %{},
      ...>   quality_score: 1.0,
      ...>   timestamp: ~U[2025-01-01 00:00:00Z]
      ...> }
      iex> json = ExDataCheck.Profile.to_json(profile)
      iex> is_binary(json)
      true

  """
  @spec to_json(t()) :: String.t()
  def to_json(profile) do
    profile
    |> Map.from_struct()
    |> Jason.encode!(pretty: true)
  end

  @doc """
  Exports the profile to a Markdown string.

  Includes:
  - Summary statistics (row count, column count, quality score)
  - Column-level details in a table
  - Missing value information

  ## Examples

      iex> profile = %ExDataCheck.Profile{
      ...>   row_count: 100,
      ...>   column_count: 3,
      ...>   columns: %{
      ...>     age: %{type: :integer, min: 25, max: 65},
      ...>     name: %{type: :string, cardinality: 95}
      ...>   },
      ...>   missing_values: %{age: 0, name: 5},
      ...>   quality_score: 0.95,
      ...>   timestamp: ~U[2025-01-01 00:00:00Z]
      ...> }
      iex> markdown = ExDataCheck.Profile.to_markdown(profile)
      iex> markdown =~ "# Data Profile"
      true

  """
  @spec to_markdown(t()) :: String.t()
  def to_markdown(profile) do
    """
    # Data Profile

    **Generated**: #{DateTime.to_string(profile.timestamp)}

    ## Summary

    - **Row Count**: #{profile.row_count}
    - **Column Count**: #{profile.column_count}
    - **Quality Score**: #{Float.round(profile.quality_score, 4)}

    ## Columns

    #{format_columns_table(profile.columns)}

    ## Missing Values

    #{format_missing_values(profile.missing_values)}
    """
  end

  # Private functions

  @spec extract_missing_values(%{optional(atom() | String.t()) => column_profile()}) :: %{
          optional(atom() | String.t()) => non_neg_integer()
        }
  defp extract_missing_values(column_profiles) do
    column_profiles
    |> Enum.map(fn {column, profile} ->
      {column, Map.get(profile, :missing, 0)}
    end)
    |> Enum.into(%{})
  end

  @spec calculate_quality_score(non_neg_integer(), %{
          optional(atom() | String.t()) => column_profile()
        }) :: float()
  defp calculate_quality_score(0, _column_profiles), do: 0.0

  defp calculate_quality_score(_row_count, column_profiles) when map_size(column_profiles) == 0,
    do: 1.0

  defp calculate_quality_score(row_count, column_profiles) do
    total_cells = row_count * map_size(column_profiles)

    total_missing =
      column_profiles
      |> Enum.map(fn {_col, profile} -> Map.get(profile, :missing, 0) end)
      |> Enum.sum()

    (total_cells - total_missing) / total_cells
  end

  @spec format_columns_table(%{optional(atom() | String.t()) => column_profile()}) :: String.t()
  defp format_columns_table(columns) do
    if map_size(columns) == 0 do
      "No columns profiled."
    else
      header = "| Column | Type | Details |\n|--------|------|---------|"

      rows =
        columns
        |> Enum.map(fn {column, profile} ->
          details = format_column_details(profile)
          "| #{column} | #{profile[:type] || "unknown"} | #{details} |"
        end)
        |> Enum.join("\n")

      header <> "\n" <> rows
    end
  end

  @spec format_column_details(column_profile()) :: String.t()
  defp format_column_details(profile) do
    details = []

    details =
      if profile[:min] && profile[:max] do
        ["Range: #{profile[:min]} - #{profile[:max]}" | details]
      else
        details
      end

    details =
      if profile[:mean] do
        ["Mean: #{Float.round(profile[:mean], 2)}" | details]
      else
        details
      end

    details =
      if profile[:cardinality] do
        ["Unique: #{profile[:cardinality]}" | details]
      else
        details
      end

    details =
      if profile[:missing] && profile[:missing] > 0 do
        ["Missing: #{profile[:missing]}" | details]
      else
        details
      end

    if details == [] do
      "-"
    else
      Enum.join(Enum.reverse(details), ", ")
    end
  end

  @spec format_missing_values(%{optional(atom() | String.t()) => non_neg_integer()}) ::
          String.t()
  defp format_missing_values(missing_values) do
    columns_with_missing =
      missing_values
      |> Enum.filter(fn {_col, count} -> count > 0 end)
      |> Enum.sort_by(fn {_col, count} -> count end, :desc)

    if columns_with_missing == [] do
      "No missing values detected. ✓"
    else
      lines =
        Enum.map(columns_with_missing, fn {column, count} ->
          "- **#{column}**: #{count} missing values"
        end)

      Enum.join(lines, "\n")
    end
  end
end
