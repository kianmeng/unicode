defmodule Unicode.Block do
  @moduledoc """
  Functions to introspect Unicode
  blocks for binaries
  (Strings) and codepoints.

  """

  alias Unicode.Utils

  @blocks Utils.blocks()
          |> Utils.remove_annotations()

  @doc """
  Returns the map of Unicode
  blocks.

  The block name is the map
  key and a list of codepoint
  ranges as tuples as the value.

  """
  def blocks do
    @blocks
  end

  @doc """
  Returns a list of known Unicode
  block names.

  This function does not return the
  names of any block aliases.

  """
  @known_blocks Map.keys(@blocks)
  def known_blocks do
    @known_blocks
  end

  @block_alias Utils.property_value_alias()
  |> Map.get("blk")
  |> Enum.flat_map(fn
    [code, alias1] ->
      [{String.downcase(alias1), String.to_atom(code)},
      {String.downcase(code), String.to_atom(code)}]
    [code, alias1, alias2] ->
      [{String.downcase(alias1), String.to_atom(code)},
      {String.downcase(alias2), String.to_atom(code)},
      {String.downcase(code), String.to_atom(code)}]
  end)
  |> Map.new

  @doc """
  Returns a map of aliases for
  Unicode blocks.

  An alias is an alternative name
  for referring to a block. Aliases
  are resolved by the `fetch/1` and
  `get/1` functions.

  """
  def aliases do
    @block_alias
  end

  @doc """
  Returns the Unicode ranges for
  a given block as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `{:ok, range_list}` or
  `:error`.

  """
  def fetch(block) do
    block = Map.get(aliases(), block, block)
    Map.fetch(blocks(), block)
  end

  @doc """
  Returns the Unicode ranges for
  a given block as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `range_list` or
  `nil`.

  """
  def get(block) do
    case fetch(block) do
      {:ok, block} -> block
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters
  for a given block.

  Aliases are resolved by this function.

  ## Example

      iex> Unicode.Block.count(:old_north_arabian)
      32

  """
  def count(block) do
    with {:ok, block} <- fetch(block) do
      Enum.reduce(block, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the block name(s) for the
  given binary or codepoint.

  In the case of a codepoint, a single
  block name is returned.

  For a binary a list of distinct block
  names represented by the graphemes in
  the binary is returned.

  """
  def block(string) when is_binary(string) do
    string
    |> String.to_charlist
    |> Enum.map(&block/1)
    |> Enum.uniq()
  end

  for {block, ranges} <- @blocks do
    def block(codepoint) when unquote(Utils.ranges_to_guard_clause(ranges)) do
      unquote(block)
    end
  end

  def block(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    :no_block
  end

  @doc """
  Returns a list of tuples representing the
  valid ranges of Unicode code points.

  """
  @ranges @blocks
          |> Map.values()
          |> Enum.map(&hd/1)
          |> Enum.sort()
          |> Unicode.compact_ranges

  def ranges do
    @ranges
  end
end
