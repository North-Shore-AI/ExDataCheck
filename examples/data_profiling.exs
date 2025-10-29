#!/usr/bin/env elixir

# ExDataCheck - Data Profiling Example
#
# This example demonstrates comprehensive data profiling with statistics,
# outlier detection, and correlation analysis.
# Run with: mix run examples/data_profiling.exs

IO.puts("\n=== ExDataCheck Data Profiling Example ===\n")

# Sample dataset: Sales data with various numeric and categorical features
dataset = [
  %{
    product: "Widget A",
    price: 29.99,
    quantity: 100,
    revenue: 2999.0,
    region: "North",
    rating: 4.5
  },
  %{
    product: "Widget B",
    price: 49.99,
    quantity: 75,
    revenue: 3749.25,
    region: "South",
    rating: 4.7
  },
  %{
    product: "Widget C",
    price: 19.99,
    quantity: 150,
    revenue: 2998.5,
    region: "East",
    rating: 4.2
  },
  %{
    product: "Widget D",
    price: 39.99,
    quantity: 90,
    revenue: 3599.1,
    region: "West",
    rating: 4.6
  },
  %{
    product: "Widget E",
    price: 59.99,
    quantity: 60,
    revenue: 3599.4,
    region: "North",
    rating: 4.8
  },
  %{
    product: "Widget F",
    price: 24.99,
    quantity: 120,
    revenue: 2998.8,
    region: "South",
    rating: 4.3
  },
  %{
    product: "Widget G",
    price: 44.99,
    quantity: 85,
    revenue: 3824.15,
    region: "East",
    rating: 4.5
  },
  %{
    product: "Widget H",
    price: 34.99,
    quantity: 95,
    revenue: 3324.05,
    region: "West",
    rating: 4.4
  },
  %{
    product: "Widget I",
    price: 54.99,
    quantity: 70,
    revenue: 3849.3,
    region: "North",
    rating: 4.7
  },
  # outlier
  %{
    product: "Widget J",
    price: 199.99,
    quantity: 5,
    revenue: 999.95,
    region: "South",
    rating: 3.9
  }
]

IO.puts("Dataset: #{length(dataset)} products")
IO.puts("Columns: #{dataset |> List.first() |> Map.keys() |> Enum.join(", ")}\n")

# ============================================================================
# Basic Profiling
# ============================================================================

IO.puts("=== Basic Profile ===\n")

profile = ExDataCheck.profile(dataset)

IO.puts("Dataset Statistics:")
IO.puts("  Row Count: #{profile.row_count}")
IO.puts("  Column Count: #{profile.column_count}")
IO.puts("  Quality Score: #{Float.round(profile.quality_score, 4)} (1.0 = perfect)")
IO.puts("")

IO.puts("Missing Values:")

profile.missing_values
|> Enum.each(fn {col, count} ->
  IO.puts("  #{col}: #{count}")
end)

IO.puts("")

# Display statistics for numeric columns
IO.puts("Column Statistics:\n")

[:price, :quantity, :revenue, :rating]
|> Enum.each(fn col ->
  stats = profile.columns[col]

  if stats do
    IO.puts("  #{col}:")
    IO.puts("    Type: #{stats.type}")

    # Helper to safely format numeric values
    format_num = fn val ->
      if is_float(val), do: Float.round(val, 2), else: val
    end

    IO.puts("    Min: #{format_num.(stats.min)}")
    IO.puts("    Max: #{format_num.(stats.max)}")
    IO.puts("    Mean: #{format_num.(stats.mean)}")
    IO.puts("    Median: #{format_num.(stats.median)}")
    IO.puts("    StdDev: #{format_num.(stats.stdev)}")
    IO.puts("    Missing: #{stats.missing}")
    IO.puts("    Cardinality: #{stats.cardinality}")
    IO.puts("")
  end
end)

# Display statistics for categorical columns
[:product, :region]
|> Enum.each(fn col ->
  stats = profile.columns[col]

  if stats do
    IO.puts("  #{col}:")
    IO.puts("    Type: #{stats.type}")
    IO.puts("    Cardinality: #{stats.cardinality}")
    IO.puts("    Missing: #{stats.missing}")
    IO.puts("")
  end
end)

# ============================================================================
# Detailed Profiling with Outliers and Correlations
# ============================================================================

IO.puts("\n=== Detailed Profile (with outliers and correlations) ===\n")

detailed_profile = ExDataCheck.profile(dataset, detailed: true, outlier_method: :iqr)

# Display outlier information
IO.puts("Outlier Detection (IQR method):\n")

# Helper to safely format numeric values
format_num = fn val ->
  if is_float(val), do: Float.round(val, 2), else: val
end

[:price, :quantity, :revenue]
|> Enum.each(fn col ->
  outlier_info = detailed_profile.columns[col].outliers

  if outlier_info && outlier_info.outlier_count > 0 do
    IO.puts("  #{col}:")
    IO.puts("    Outliers found: #{outlier_info.outlier_count}")
    IO.puts("    Outlier values: #{inspect(outlier_info.outliers)}")
    IO.puts("    Q1: #{format_num.(outlier_info.q1)}")
    IO.puts("    Q3: #{format_num.(outlier_info.q3)}")
    IO.puts("    IQR: #{format_num.(outlier_info.iqr)}")
    IO.puts("    Lower fence: #{format_num.(outlier_info.lower_fence)}")
    IO.puts("    Upper fence: #{format_num.(outlier_info.upper_fence)}")
    IO.puts("")
  else
    IO.puts("  #{col}: No outliers detected")
  end
end)

# Display correlation matrix
IO.puts("\nCorrelation Matrix:\n")

if detailed_profile.correlation_matrix do
  numeric_cols = [:price, :quantity, :revenue, :rating]

  # Print header
  IO.write("              ")

  Enum.each(numeric_cols, fn col ->
    IO.write(String.pad_trailing("#{col}", 10))
  end)

  IO.puts("")

  # Print matrix
  Enum.each(numeric_cols, fn row_col ->
    IO.write(String.pad_trailing("  #{row_col}", 14))

    Enum.each(numeric_cols, fn col_col ->
      corr = get_in(detailed_profile.correlation_matrix, [row_col, col_col])

      if corr do
        formatted = :io_lib.format("~6.3f", [corr]) |> to_string()
        IO.write(String.pad_trailing(formatted, 10))
      else
        IO.write(String.pad_trailing("N/A", 10))
      end
    end)

    IO.puts("")
  end)

  IO.puts("")
end

# ============================================================================
# Detailed Profiling with Z-score Outlier Detection
# ============================================================================

IO.puts("\n=== Outlier Detection (Z-score method) ===\n")

zscore_profile = ExDataCheck.profile(dataset, detailed: true, outlier_method: :zscore)

[:price, :quantity, :revenue]
|> Enum.each(fn col ->
  outlier_info = zscore_profile.columns[col].outliers

  if outlier_info && outlier_info.outlier_count > 0 do
    IO.puts("  #{col}:")
    IO.puts("    Outliers found: #{outlier_info.outlier_count}")
    IO.puts("    Outlier values: #{inspect(outlier_info.outliers)}")
    IO.puts("    Mean: #{format_num.(outlier_info.mean)}")
    IO.puts("    StdDev: #{format_num.(outlier_info.stdev)}")
    IO.puts("    Z-score threshold: #{outlier_info.threshold}")
    IO.puts("")
  else
    IO.puts("  #{col}: No outliers detected (|z-score| < 3)")
  end
end)

# ============================================================================
# Export Profile to JSON
# ============================================================================

IO.puts("\n=== Exporting Profile ===\n")

json = ExDataCheck.Profile.to_json(profile)
json_file = "/tmp/exdatacheck_profile.json"
File.write!(json_file, json)
IO.puts("Profile exported to JSON: #{json_file}")
IO.puts("File size: #{byte_size(json)} bytes")

# Export to Markdown
markdown = ExDataCheck.Profile.to_markdown(profile)
md_file = "/tmp/exdatacheck_profile.md"
File.write!(md_file, markdown)
IO.puts("Profile exported to Markdown: #{md_file}")
IO.puts("File size: #{byte_size(markdown)} bytes")

# ============================================================================
# Profiling Large Dataset (demonstration)
# ============================================================================

IO.puts("\n\n=== Profiling Larger Dataset ===\n")

# Generate a larger dataset
large_dataset =
  for i <- 1..1000 do
    %{
      id: i,
      value: :rand.uniform() * 100,
      category: Enum.random(["A", "B", "C", "D", "E"]),
      score: :rand.normal() * 10 + 50,
      timestamp: DateTime.add(DateTime.utc_now(), -i * 60, :second)
    }
  end

IO.puts("Large dataset: #{length(large_dataset)} rows")

# Profile with timing
start_time = System.monotonic_time(:millisecond)
large_profile = ExDataCheck.profile(large_dataset, detailed: true)
end_time = System.monotonic_time(:millisecond)
elapsed = end_time - start_time

IO.puts("Profiling completed in #{elapsed}ms")
IO.puts("Row Count: #{large_profile.row_count}")
IO.puts("Column Count: #{large_profile.column_count}")
IO.puts("Quality Score: #{Float.round(large_profile.quality_score, 4)}")

# Show value statistics
value_stats = large_profile.columns[:value]
IO.puts("\nValue column statistics:")
IO.puts("  Min: #{format_num.(value_stats.min)}")
IO.puts("  Max: #{format_num.(value_stats.max)}")
IO.puts("  Mean: #{format_num.(value_stats.mean)}")
IO.puts("  Median: #{format_num.(value_stats.median)}")
IO.puts("  StdDev: #{format_num.(value_stats.stdev)}")

# Show score statistics (should be approximately normal)
score_stats = large_profile.columns[:score]
IO.puts("\nScore column statistics (normal distribution):")
IO.puts("  Min: #{format_num.(score_stats.min)}")
IO.puts("  Max: #{format_num.(score_stats.max)}")
IO.puts("  Mean: #{format_num.(score_stats.mean)}")
IO.puts("  Median: #{format_num.(score_stats.median)}")
IO.puts("  StdDev: #{format_num.(score_stats.stdev)}")

IO.puts("\n=== Example Complete ===\n")
