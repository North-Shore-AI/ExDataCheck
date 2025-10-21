defmodule ExDataCheck.Validator.ColumnExtractorTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExDataCheck.Validator.ColumnExtractor

  describe "extract/2 with maps" do
    test "extracts column from list of maps with atom keys" do
      dataset = [
        %{age: 25, name: "Alice"},
        %{age: 30, name: "Bob"},
        %{age: 35, name: "Charlie"}
      ]

      result = ColumnExtractor.extract(dataset, :age)

      assert result == [25, 30, 35]
    end

    test "extracts column from list of maps with string keys" do
      dataset = [
        %{"age" => 25, "name" => "Alice"},
        %{"age" => 30, "name" => "Bob"}
      ]

      result = ColumnExtractor.extract(dataset, "age")

      assert result == [25, 30]
    end

    test "extracts column using atom key from maps with string keys" do
      dataset = [
        %{"age" => 25},
        %{"age" => 30}
      ]

      result = ColumnExtractor.extract(dataset, :age)

      assert result == [25, 30]
    end

    test "extracts column using string key from maps with atom keys" do
      dataset = [
        %{age: 25},
        %{age: 30}
      ]

      result = ColumnExtractor.extract(dataset, "age")

      assert result == [25, 30]
    end

    test "handles missing values as nil" do
      dataset = [
        %{age: 25, name: "Alice"},
        %{name: "Bob"},
        %{age: 35, name: "Charlie"}
      ]

      result = ColumnExtractor.extract(dataset, :age)

      assert result == [25, nil, 35]
    end

    test "handles nil values in dataset" do
      dataset = [
        %{age: 25},
        %{age: nil},
        %{age: 30}
      ]

      result = ColumnExtractor.extract(dataset, :age)

      assert result == [25, nil, 30]
    end

    test "returns empty list for empty dataset" do
      result = ColumnExtractor.extract([], :age)

      assert result == []
    end
  end

  describe "extract/2 with keyword lists" do
    test "extracts column from list of keyword lists" do
      dataset = [
        [age: 25, name: "Alice"],
        [age: 30, name: "Bob"],
        [age: 35, name: "Charlie"]
      ]

      result = ColumnExtractor.extract(dataset, :age)

      assert result == [25, 30, 35]
    end

    test "handles missing keys in keyword lists" do
      dataset = [
        [age: 25, name: "Alice"],
        [name: "Bob"],
        [age: 35, name: "Charlie"]
      ]

      result = ColumnExtractor.extract(dataset, :age)

      assert result == [25, nil, 35]
    end
  end

  describe "column_exists?/2" do
    test "returns true if column exists in all rows" do
      dataset = [
        %{age: 25, name: "Alice"},
        %{age: 30, name: "Bob"}
      ]

      assert ColumnExtractor.column_exists?(dataset, :age) == true
      assert ColumnExtractor.column_exists?(dataset, :name) == true
    end

    test "returns true if column exists in at least one row" do
      dataset = [
        %{age: 25},
        %{name: "Bob"}
      ]

      assert ColumnExtractor.column_exists?(dataset, :age) == true
      assert ColumnExtractor.column_exists?(dataset, :name) == true
    end

    test "returns false if column doesn't exist in any row" do
      dataset = [
        %{age: 25, name: "Alice"},
        %{age: 30, name: "Bob"}
      ]

      assert ColumnExtractor.column_exists?(dataset, :email) == false
    end

    test "returns false for empty dataset" do
      assert ColumnExtractor.column_exists?([], :age) == false
    end

    test "handles string keys" do
      dataset = [
        %{"age" => 25},
        %{"age" => 30}
      ]

      assert ColumnExtractor.column_exists?(dataset, "age") == true
      assert ColumnExtractor.column_exists?(dataset, :age) == true
    end
  end

  describe "columns/1" do
    test "returns all unique column names from dataset" do
      dataset = [
        %{age: 25, name: "Alice"},
        %{age: 30, name: "Bob"},
        %{age: 35, email: "charlie@example.com"}
      ]

      columns = ColumnExtractor.columns(dataset)

      assert :age in columns
      assert :name in columns
      assert :email in columns
      assert length(columns) == 3
    end

    test "returns columns from maps with string keys" do
      dataset = [
        %{"age" => 25, "name" => "Alice"},
        %{"age" => 30, "email" => "bob@example.com"}
      ]

      columns = ColumnExtractor.columns(dataset)

      assert "age" in columns
      assert "name" in columns
      assert "email" in columns
    end

    test "returns empty list for empty dataset" do
      columns = ColumnExtractor.columns([])

      assert columns == []
    end

    test "handles keyword lists" do
      dataset = [
        [age: 25, name: "Alice"],
        [age: 30, email: "bob@example.com"]
      ]

      columns = ColumnExtractor.columns(dataset)

      assert :age in columns
      assert :name in columns
      assert :email in columns
    end
  end

  describe "count_non_null/2" do
    test "counts non-nil values in column" do
      dataset = [
        %{age: 25},
        %{age: nil},
        %{age: 30},
        %{age: nil},
        %{age: 35}
      ]

      count = ColumnExtractor.count_non_null(dataset, :age)

      assert count == 3
    end

    test "counts all values when none are nil" do
      dataset = [
        %{age: 25},
        %{age: 30},
        %{age: 35}
      ]

      count = ColumnExtractor.count_non_null(dataset, :age)

      assert count == 3
    end

    test "returns 0 when all values are nil" do
      dataset = [
        %{age: nil},
        %{age: nil}
      ]

      count = ColumnExtractor.count_non_null(dataset, :age)

      assert count == 0
    end

    test "returns 0 for empty dataset" do
      count = ColumnExtractor.count_non_null([], :age)

      assert count == 0
    end
  end

  property "extract preserves dataset length" do
    check all(dataset <- list_of(map_of(atom(:alphanumeric), integer()))) do
      columns = ColumnExtractor.columns(dataset)

      if columns != [] do
        column = hd(columns)
        extracted = ColumnExtractor.extract(dataset, column)

        assert length(extracted) == length(dataset)
      end
    end
  end

  property "column_exists? is consistent with columns/1" do
    check all(dataset <- list_of(map_of(atom(:alphanumeric), integer()), min_length: 1)) do
      columns = ColumnExtractor.columns(dataset)

      if columns != [] do
        column = hd(columns)
        assert ColumnExtractor.column_exists?(dataset, column) == true
      end
    end
  end
end
