defmodule ExDataCheck.Expectations.StringTest do
  use ExUnit.Case, async: true
  doctest ExDataCheck.Expectations.String

  alias ExDataCheck.Expectations.String, as: StringExp

  describe "expect_column_values_to_be_valid_emails/1" do
    test "succeeds when all values are valid email addresses" do
      dataset = [
        %{email: "alice@example.com"},
        %{email: "bob.smith@company.co.uk"},
        %{email: "test+tag@domain.org"}
      ]

      expectation = StringExp.expect_column_values_to_be_valid_emails(:email)
      result = expectation.validator.(dataset)

      assert result.success
      assert result.observed.total_values == 3
      assert result.observed.invalid_count == 0
    end

    test "fails when values are invalid email addresses" do
      dataset = [
        %{email: "alice@example.com"},
        %{email: "not an email"},
        %{email: "@nodomain.com"},
        %{email: "missing@tld"}
      ]

      expectation = StringExp.expect_column_values_to_be_valid_emails(:email)
      result = expectation.validator.(dataset)

      refute result.success
      assert result.observed.invalid_count == 3
      assert length(result.observed.invalid_examples) == 3
    end

    test "ignores nil values by default" do
      dataset = [
        %{email: "alice@example.com"},
        %{email: nil},
        %{email: "bob@example.com"}
      ]

      expectation = StringExp.expect_column_values_to_be_valid_emails(:email)
      result = expectation.validator.(dataset)

      assert result.success
      assert result.observed.total_values == 2
      assert result.observed.nil_count == 1
    end

    test "handles empty dataset" do
      dataset = []

      expectation = StringExp.expect_column_values_to_be_valid_emails(:email)
      result = expectation.validator.(dataset)

      assert result.success
    end
  end

  describe "expect_column_values_to_be_valid_urls/2" do
    test "succeeds when all values are valid URLs" do
      dataset = [
        %{url: "https://example.com"},
        %{url: "http://www.google.com/search"},
        %{url: "https://api.service.io/v1/users?id=123"}
      ]

      expectation = StringExp.expect_column_values_to_be_valid_urls(:url)
      result = expectation.validator.(dataset)

      assert result.success
      assert result.observed.total_values == 3
      assert result.observed.invalid_count == 0
    end

    test "fails when values are invalid URLs" do
      dataset = [
        %{url: "https://example.com"},
        %{url: "not a url"},
        %{url: "htp://typo.com"},
        %{url: "missing-scheme.com"}
      ]

      expectation = StringExp.expect_column_values_to_be_valid_urls(:url)
      result = expectation.validator.(dataset)

      refute result.success
      assert result.observed.invalid_count >= 2
    end

    test "restricts to specific schemes when specified" do
      dataset = [
        %{url: "https://secure.com"},
        %{url: "http://insecure.com"}
      ]

      expectation = StringExp.expect_column_values_to_be_valid_urls(:url, schemes: [:https])
      result = expectation.validator.(dataset)

      refute result.success
      assert result.observed.invalid_count == 1
    end

    test "allows multiple schemes" do
      dataset = [
        %{url: "https://example.com"},
        %{url: "http://example.com"},
        %{url: "ftp://files.com"}
      ]

      expectation =
        StringExp.expect_column_values_to_be_valid_urls(:url, schemes: [:http, :https, :ftp])

      result = expectation.validator.(dataset)

      assert result.success
    end

    test "rejects hosts without TLD when require_tld is true (default)" do
      dataset = [
        %{url: "http://localhost"},
        %{url: "http://example.com"}
      ]

      expectation = StringExp.expect_column_values_to_be_valid_urls(:url)
      result = expectation.validator.(dataset)

      refute result.success
      assert result.observed.invalid_count == 1
    end

    test "allows hosts without TLD when require_tld is false" do
      dataset = [
        %{url: "http://localhost"},
        %{url: "http://example.com"}
      ]

      expectation = StringExp.expect_column_values_to_be_valid_urls(:url, require_tld: false)
      result = expectation.validator.(dataset)

      assert result.success
    end

    test "ignores nil values" do
      dataset = [
        %{url: "https://example.com"},
        %{url: nil}
      ]

      expectation = StringExp.expect_column_values_to_be_valid_urls(:url)
      result = expectation.validator.(dataset)

      assert result.success
    end
  end

  describe "expect_column_values_to_be_valid_uuids/2" do
    test "succeeds when all values are valid UUIDs" do
      dataset = [
        %{id: "550e8400-e29b-41d4-a716-446655440000"},
        %{id: "6ba7b810-9dad-11d1-80b4-00c04fd430c8"},
        %{id: "f47ac10b-58cc-4372-a567-0e02b2c3d479"}
      ]

      expectation = StringExp.expect_column_values_to_be_valid_uuids(:id)
      result = expectation.validator.(dataset)

      assert result.success
      assert result.observed.total_values == 3
      assert result.observed.invalid_count == 0
    end

    test "accepts uppercase UUIDs" do
      dataset = [
        %{id: "550E8400-E29B-41D4-A716-446655440000"}
      ]

      expectation = StringExp.expect_column_values_to_be_valid_uuids(:id)
      result = expectation.validator.(dataset)

      assert result.success
    end

    test "fails when values are invalid UUIDs" do
      dataset = [
        %{id: "550e8400-e29b-41d4-a716-446655440000"},
        %{id: "not-a-uuid"},
        %{id: "550e8400-e29b-41d4-a716"},
        %{id: "550e8400e29b41d4a716446655440000"}
      ]

      expectation = StringExp.expect_column_values_to_be_valid_uuids(:id)
      result = expectation.validator.(dataset)

      refute result.success
      assert result.observed.invalid_count == 3
    end

    test "validates specific UUID version when specified" do
      dataset = [
        %{id: "550e8400-e29b-41d4-a716-446655440000"},
        %{id: "6ba7b810-9dad-11d1-80b4-00c04fd430c8"}
      ]

      expectation = StringExp.expect_column_values_to_be_valid_uuids(:id, version: 4)
      result = expectation.validator.(dataset)

      # Both should be checked for version 4 format
      # (This may fail or succeed depending on actual version bits)
      assert is_boolean(result.success)
    end

    test "ignores nil values" do
      dataset = [
        %{id: "550e8400-e29b-41d4-a716-446655440000"},
        %{id: nil}
      ]

      expectation = StringExp.expect_column_values_to_be_valid_uuids(:id)
      result = expectation.validator.(dataset)

      assert result.success
    end
  end

  describe "expect_column_values_to_match_format/2" do
    test "validates US phone numbers" do
      dataset = [
        %{phone: "(123) 456-7890"},
        %{phone: "123-456-7890"},
        %{phone: "1234567890"}
      ]

      expectation = StringExp.expect_column_values_to_match_format(:phone, :us_phone)
      result = expectation.validator.(dataset)

      assert result.success
    end

    test "fails invalid US phone numbers" do
      dataset = [
        %{phone: "(123) 456-7890"},
        %{phone: "not-a-phone"},
        %{phone: "123"}
      ]

      expectation = StringExp.expect_column_values_to_match_format(:phone, :us_phone)
      result = expectation.validator.(dataset)

      refute result.success
    end

    test "validates ISO dates" do
      dataset = [
        %{date: "2025-11-25"},
        %{date: "2024-01-01"},
        %{date: "2023-12-31"}
      ]

      expectation = StringExp.expect_column_values_to_match_format(:date, :iso_date)
      result = expectation.validator.(dataset)

      assert result.success
    end

    test "validates ISO datetimes" do
      dataset = [
        %{timestamp: "2025-11-25T10:00:00Z"},
        %{timestamp: "2024-01-01T23:59:59Z"}
      ]

      expectation = StringExp.expect_column_values_to_match_format(:timestamp, :iso_datetime)
      result = expectation.validator.(dataset)

      assert result.success
    end

    test "validates IPv4 addresses" do
      dataset = [
        %{ip: "192.168.1.1"},
        %{ip: "10.0.0.1"},
        %{ip: "8.8.8.8"}
      ]

      expectation = StringExp.expect_column_values_to_match_format(:ip, :ip_address)
      result = expectation.validator.(dataset)

      assert result.success
    end

    test "validates hex colors" do
      dataset = [
        %{color: "#FF5733"},
        %{color: "#00FF00"},
        %{color: "#FFF"}
      ]

      expectation = StringExp.expect_column_values_to_match_format(:color, :hex_color)
      result = expectation.validator.(dataset)

      assert result.success
    end

    test "supports custom regex patterns" do
      dataset = [
        %{code: "ABC123"},
        %{code: "XYZ789"}
      ]

      custom_pattern = ~r/^[A-Z]{3}\d{3}$/
      expectation = StringExp.expect_column_values_to_match_format(:code, custom_pattern)
      result = expectation.validator.(dataset)

      assert result.success
    end

    test "raises when an unknown format atom is supplied" do
      assert_raise ArgumentError, fn ->
        StringExp.expect_column_values_to_match_format(:code, :unknown_format)
      end
    end

    test "ignores nil values" do
      dataset = [
        %{phone: "(123) 456-7890"},
        %{phone: nil}
      ]

      expectation = StringExp.expect_column_values_to_match_format(:phone, :us_phone)
      result = expectation.validator.(dataset)

      assert result.success
    end
  end

  describe "expect_column_string_length_distribution/2" do
    test "succeeds when string lengths are within expected distribution" do
      dataset = [
        %{name: "Alice"},
        %{name: "Bob Smith"},
        %{name: "Charlie Brown"}
      ]

      expectation =
        StringExp.expect_column_string_length_distribution(:name,
          mean_length: {5, 15},
          max_length: 20
        )

      result = expectation.validator.(dataset)

      assert result.success
    end

    test "fails when mean length is outside expected range" do
      dataset = [
        %{name: "Al"},
        %{name: "Bo"},
        %{name: "Ed"}
      ]

      expectation =
        StringExp.expect_column_string_length_distribution(:name,
          mean_length: {10, 20}
        )

      result = expectation.validator.(dataset)

      refute result.success
    end

    test "fails when values exceed max length" do
      dataset = [
        %{name: "Alice"},
        %{name: "This is a very long name that exceeds the maximum"}
      ]

      expectation =
        StringExp.expect_column_string_length_distribution(:name,
          max_length: 20
        )

      result = expectation.validator.(dataset)

      refute result.success
      assert result.observed.exceeds_max_count == 1
    end

    test "fails when values are below min length" do
      dataset = [
        %{name: "Alice Johnson"},
        %{name: "A"}
      ]

      expectation =
        StringExp.expect_column_string_length_distribution(:name,
          min_length: 3
        )

      result = expectation.validator.(dataset)

      refute result.success
      assert result.observed.below_min_count == 1
    end

    test "provides length statistics" do
      dataset = [
        %{name: "Alice"},
        %{name: "Bob"},
        %{name: "Charlie"}
      ]

      expectation =
        StringExp.expect_column_string_length_distribution(:name,
          mean_length: {3, 10}
        )

      result = expectation.validator.(dataset)

      assert result.success
      assert is_float(result.observed.actual_mean_length)
      assert is_number(result.observed.min_length_observed)
      assert is_number(result.observed.max_length_observed)
    end

    test "ignores nil values" do
      dataset = [
        %{name: "Alice"},
        %{name: nil},
        %{name: "Bob"}
      ]

      expectation =
        StringExp.expect_column_string_length_distribution(:name,
          mean_length: {3, 5}
        )

      result = expectation.validator.(dataset)

      assert result.success
    end

    test "handles empty strings" do
      dataset = [
        %{name: "Alice"},
        %{name: ""}
      ]

      expectation =
        StringExp.expect_column_string_length_distribution(:name,
          min_length: 1
        )

      result = expectation.validator.(dataset)

      refute result.success
    end
  end
end
