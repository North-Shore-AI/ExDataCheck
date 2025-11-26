defmodule ExDataCheck.Expectations.String do
  @moduledoc """
  Enhanced string validation expectations.

  Provides format-specific validation for common string patterns like emails,
  URLs, UUIDs, phone numbers, and other structured text formats.

  ## Examples

      # Validate email addresses
      expect_column_values_to_be_valid_emails(:email)

      # Validate URLs
      expect_column_values_to_be_valid_urls(:website, schemes: [:https])

      # Validate UUIDs
      expect_column_values_to_be_valid_uuids(:id)

      # Validate specific formats
      expect_column_values_to_match_format(:phone, :us_phone)

      # Validate string length distribution
      expect_column_string_length_distribution(:name,
        mean_length: {5, 20},
        max_length: 50
      )

  ## Design Principles

  - **Format-Specific**: Dedicated validators for common formats
  - **Extensible**: Support for custom regex patterns
  - **Informative**: Detailed error messages with examples
  - **Nil Handling**: Ignores nil values by default

  """

  alias ExDataCheck.{Expectation, ExpectationResult}
  alias ExDataCheck.Validator.ColumnExtractor

  # Regex patterns for common formats
  @email_regex ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/
  @uuid_regex ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  @us_phone_regex ~r/^(?:\(\d{3}\)\s?|\d{3}[-\s]?)?\d{3}[-\s]?\d{4}$/
  @iso_date_regex ~r/^\d{4}-\d{2}-\d{2}$/
  @iso_datetime_regex ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:Z|[+-]\d{2}:\d{2})?$/
  @ipv4_regex ~r/^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
  @hex_color_regex ~r/^#(?:[0-9a-fA-F]{3}){1,2}$/

  @doc """
  Expects all non-nil values in a column to be valid email addresses.

  Uses a practical email validation regex that checks for basic structure.

  ## Parameters

    * `column` - Column name (atom or string)

  ## Examples

      iex> dataset = [
      ...>   %{email: "alice@example.com"},
      ...>   %{email: "bob@company.co.uk"}
      ...> ]
      iex> expectation = ExDataCheck.Expectations.String.expect_column_values_to_be_valid_emails(:email)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

  """
  @spec expect_column_values_to_be_valid_emails(atom() | String.t()) :: Expectation.t()
  def expect_column_values_to_be_valid_emails(column) do
    validator = fn dataset ->
      values =
        dataset
        |> ColumnExtractor.extract(column)
        |> Enum.reject(&is_nil/1)

      nil_count = length(ColumnExtractor.extract(dataset, column)) - length(values)

      invalid =
        values
        |> Enum.reject(fn value ->
          is_binary(value) and Regex.match?(@email_regex, value)
        end)

      observed = %{
        total_values: length(values),
        valid_count: length(values) - length(invalid),
        invalid_count: length(invalid),
        invalid_examples: Enum.take(invalid, 5),
        nil_count: nil_count
      }

      ExpectationResult.new(
        length(invalid) == 0,
        "expect column #{inspect(column)} values to be valid email addresses",
        observed,
        %{}
      )
    end

    Expectation.new(:valid_emails, column, validator, %{})
  end

  @doc """
  Expects all non-nil values in a column to be valid URLs.

  ## Parameters

    * `column` - Column name (atom or string)
    * `opts` - Options
      * `:schemes` - Allowed URL schemes (default: [:http, :https])
      * `:require_tld` - Require top-level domain (default: true)

  ## Examples

      iex> dataset = [
      ...>   %{url: "https://example.com"},
      ...>   %{url: "http://www.google.com/search"}
      ...> ]
      iex> expectation = ExDataCheck.Expectations.String.expect_column_values_to_be_valid_urls(:url)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

  """
  @spec expect_column_values_to_be_valid_urls(atom() | String.t(), keyword()) :: Expectation.t()
  def expect_column_values_to_be_valid_urls(column, opts \\ []) do
    allowed_schemes = Keyword.get(opts, :schemes, [:http, :https])
    require_tld = Keyword.get(opts, :require_tld, true)

    metadata =
      opts
      |> Map.new()
      |> Map.put(:schemes, allowed_schemes)
      |> Map.put(:require_tld, require_tld)

    validator = fn dataset ->
      values =
        dataset
        |> ColumnExtractor.extract(column)
        |> Enum.reject(&is_nil/1)

      nil_count = length(ColumnExtractor.extract(dataset, column)) - length(values)

      invalid =
        values
        |> Enum.reject(fn value ->
          valid_url?(value, allowed_schemes, require_tld)
        end)

      observed = %{
        total_values: length(values),
        valid_count: length(values) - length(invalid),
        invalid_count: length(invalid),
        invalid_examples: Enum.take(invalid, 5),
        allowed_schemes: allowed_schemes,
        require_tld: require_tld,
        nil_count: nil_count
      }

      ExpectationResult.new(
        length(invalid) == 0,
        "expect column #{inspect(column)} values to be valid URLs (schemes: #{inspect(allowed_schemes)}, require_tld: #{require_tld})",
        observed,
        metadata
      )
    end

    Expectation.new(:valid_urls, column, validator, metadata)
  end

  @doc """
  Expects all non-nil values in a column to be valid UUIDs.

  ## Parameters

    * `column` - Column name (atom or string)
    * `opts` - Options
      * `:version` - UUID version to validate (1-5, default: any)
      * `:case` - :lower, :upper, or :any (default: :any)

  ## Examples

      iex> dataset = [
      ...>   %{id: "550e8400-e29b-41d4-a716-446655440000"},
      ...>   %{id: "6ba7b810-9dad-11d1-80b4-00c04fd430c8"}
      ...> ]
      iex> expectation = ExDataCheck.Expectations.String.expect_column_values_to_be_valid_uuids(:id)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

  """
  @spec expect_column_values_to_be_valid_uuids(atom() | String.t(), keyword()) :: Expectation.t()
  def expect_column_values_to_be_valid_uuids(column, opts \\ []) do
    version = Keyword.get(opts, :version)

    metadata =
      opts
      |> Map.new()
      |> Map.put(:version, version)

    validator = fn dataset ->
      values =
        dataset
        |> ColumnExtractor.extract(column)
        |> Enum.reject(&is_nil/1)

      nil_count = length(ColumnExtractor.extract(dataset, column)) - length(values)

      invalid =
        values
        |> Enum.reject(fn value ->
          valid_uuid?(value, version)
        end)

      observed = %{
        total_values: length(values),
        valid_count: length(values) - length(invalid),
        invalid_count: length(invalid),
        invalid_examples: Enum.take(invalid, 5),
        version_required: version,
        nil_count: nil_count
      }

      version_text = if version, do: " (version #{version})", else: ""

      ExpectationResult.new(
        length(invalid) == 0,
        "expect column #{inspect(column)} values to be valid UUIDs#{version_text}",
        observed,
        metadata
      )
    end

    Expectation.new(:valid_uuids, column, validator, metadata)
  end

  @doc """
  Expects values to match a predefined or custom format pattern.

  ## Supported Formats

  - `:us_phone` - US phone number formats
  - `:iso_date` - ISO 8601 date (YYYY-MM-DD)
  - `:iso_datetime` - ISO 8601 datetime
  - `:ip_address` - IPv4 address
  - `:hex_color` - Hex color code (#RGB or #RRGGBB)
  - Custom Regex - Provide your own regex pattern

  ## Parameters

    * `column` - Column name (atom or string)
    * `format` - Format atom or custom Regex

  ## Examples

      iex> dataset = [
      ...>   %{phone: "(123) 456-7890"},
      ...>   %{phone: "123-456-7890"}
      ...> ]
      iex> expectation = ExDataCheck.Expectations.String.expect_column_values_to_match_format(:phone, :us_phone)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

  """
  @spec expect_column_values_to_match_format(atom() | String.t(), atom() | Regex.t()) ::
          Expectation.t()
  def expect_column_values_to_match_format(column, format) do
    {pattern, format_name} = get_format_pattern(format)

    validator = fn dataset ->
      values =
        dataset
        |> ColumnExtractor.extract(column)
        |> Enum.reject(&is_nil/1)

      nil_count = length(ColumnExtractor.extract(dataset, column)) - length(values)

      non_matching =
        values
        |> Enum.reject(fn value ->
          is_binary(value) and Regex.match?(pattern, value)
        end)

      observed = %{
        total_values: length(values),
        matching_count: length(values) - length(non_matching),
        non_matching_count: length(non_matching),
        non_matching_examples: Enum.take(non_matching, 5),
        format: format_name,
        nil_count: nil_count
      }

      ExpectationResult.new(
        length(non_matching) == 0,
        "expect column #{inspect(column)} values to match format #{format_name}",
        observed,
        %{format: format}
      )
    end

    Expectation.new(:match_format, column, validator, %{format: format})
  end

  @doc """
  Expects string length distribution to be within specified parameters.

  Validates that string lengths follow expected patterns, with options for
  mean length range, minimum length, and maximum length constraints.

  ## Parameters

    * `column` - Column name (atom or string)
    * `opts` - Options
      * `:mean_length` - Expected mean length range as {min, max} tuple
      * `:min_length` - Absolute minimum length (values below fail)
      * `:max_length` - Absolute maximum length (values above fail)

  ## Examples

      iex> dataset = [
      ...>   %{name: "Alice"},
      ...>   %{name: "Bob Smith"},
      ...>   %{name: "Charlie"}
      ...> ]
      iex> expectation = ExDataCheck.Expectations.String.expect_column_string_length_distribution(
      ...>   :name,
      ...>   mean_length: {5, 15},
      ...>   max_length: 20
      ...> )
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

  """
  @spec expect_column_string_length_distribution(atom() | String.t(), keyword()) ::
          Expectation.t()
  def expect_column_string_length_distribution(column, opts) do
    mean_range = Keyword.get(opts, :mean_length)
    min_length = Keyword.get(opts, :min_length)
    max_length = Keyword.get(opts, :max_length)
    metadata = Map.new(opts)

    validator = fn dataset ->
      values =
        dataset
        |> ColumnExtractor.extract(column)
        |> Enum.reject(&is_nil/1)
        |> Enum.filter(&is_binary/1)

      lengths = Enum.map(values, &String.length/1)

      actual_mean = if length(lengths) > 0, do: Enum.sum(lengths) / length(lengths), else: 0.0
      min_observed = if length(lengths) > 0, do: Enum.min(lengths), else: 0
      max_observed = if length(lengths) > 0, do: Enum.max(lengths), else: 0

      # Check violations
      mean_valid =
        case mean_range do
          {min_mean, max_mean} -> actual_mean >= min_mean and actual_mean <= max_mean
          nil -> true
        end

      below_min =
        if min_length do
          Enum.filter(values, fn v -> String.length(v) < min_length end)
        else
          []
        end

      exceeds_max =
        if max_length do
          Enum.filter(values, fn v -> String.length(v) > max_length end)
        else
          []
        end

      success = mean_valid and length(below_min) == 0 and length(exceeds_max) == 0

      observed = %{
        total_values: length(values),
        actual_mean_length: actual_mean,
        min_length_observed: min_observed,
        max_length_observed: max_observed,
        expected_mean_range: mean_range,
        below_min_count: length(below_min),
        below_min_examples: Enum.take(below_min, 5),
        exceeds_max_count: length(exceeds_max),
        exceeds_max_examples: Enum.take(exceeds_max, 5)
      }

      ExpectationResult.new(
        success,
        "expect column #{inspect(column)} string length distribution to meet constraints",
        observed,
        metadata
      )
    end

    Expectation.new(:string_length_distribution, column, validator, metadata)
  end

  # Private helper functions

  defp valid_url?(value, allowed_schemes, require_tld) when is_binary(value) do
    allowed_schemes =
      allowed_schemes
      |> Enum.map(&to_string/1)
      |> Enum.map(&String.downcase/1)

    case URI.parse(value) do
      %URI{scheme: scheme, host: host} when not is_nil(scheme) and not is_nil(host) ->
        scheme_normalized = String.downcase(scheme)
        valid_scheme = scheme_normalized in allowed_schemes
        valid_tld = if require_tld, do: String.contains?(host, "."), else: true
        valid_scheme and valid_tld

      _ ->
        false
    end
  end

  defp valid_url?(_, _, _), do: false

  defp valid_uuid?(value, version) when is_binary(value) do
    if Regex.match?(@uuid_regex, value) do
      if version do
        # Check version bits (13th character should match version)
        check_uuid_version(value, version)
      else
        true
      end
    else
      false
    end
  end

  defp valid_uuid?(_, _), do: false

  defp check_uuid_version(uuid, version) do
    # The version is in the 13th character (after removing hyphens)
    # Format: xxxxxxxx-xxxx-Vxxx-xxxx-xxxxxxxxxxxx where V is the version
    parts = String.split(uuid, "-")

    if length(parts) == 5 do
      version_part = Enum.at(parts, 2)
      version_char = String.at(version_part, 0)

      case Integer.parse(version_char, 16) do
        {v, _} -> v == version
        _ -> false
      end
    else
      false
    end
  end

  defp get_format_pattern(:us_phone), do: {@us_phone_regex, "US phone"}
  defp get_format_pattern(:iso_date), do: {@iso_date_regex, "ISO date (YYYY-MM-DD)"}

  defp get_format_pattern(:iso_datetime),
    do: {@iso_datetime_regex, "ISO datetime (YYYY-MM-DDTHH:MM:SSZ)"}

  defp get_format_pattern(:ip_address), do: {@ipv4_regex, "IPv4 address"}
  defp get_format_pattern(:hex_color), do: {@hex_color_regex, "hex color (#RGB or #RRGGBB)"}
  defp get_format_pattern(%Regex{} = pattern), do: {pattern, "custom regex"}

  defp get_format_pattern(unknown) do
    raise ArgumentError,
          "unknown format #{inspect(unknown)}. Supported formats: :us_phone, :iso_date, :iso_datetime, :ip_address, :hex_color, or a custom Regex."
  end
end
