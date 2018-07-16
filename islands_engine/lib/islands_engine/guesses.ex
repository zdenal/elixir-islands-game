defmodule IslandsEngine.Guesses do
  alias IslandsEngine.{Guesses, Coordinate}

  @enforce_keys [:hits, :misses]
  defstruct [:hits, :misses]

  def new do
    %Guesses{hits: MapSet.new(), misses: MapSet.new()}
  end

  def add(%Guesses{} = guesses, :hit, %Coordinate{} = coord) do
    update_in(guesses.hits, &MapSet.put(&1, coord))
  end
  def add(%Guesses{} = guesses, :miss, %Coordinate{} = coord) do
    update_in(guesses.misses, &MapSet.put(&1, coord))
  end
end
