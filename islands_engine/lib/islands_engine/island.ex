defmodule IslandsEngine.Island do
  alias IslandsEngine.{Coordinate, Island}

  @enforce_keys [:coordinates, :hit_coordinates]
  defstruct [:coordinates, :hit_coordinates]

  def new(type, %Coordinate{} = upper_left) do
    with [_|_] = offsets <- offset(type),
         %MapSet{} = coordinates <- add_coordinates(offsets, upper_left)
    do
      {:ok, %Island{coordinates: coordinates, hit_coordinates: MapSet.new()}}
    else
      error -> error
    end
  end

  def types(), do: [:atoll, :dot, :l_shape, :s_shape, :square]

  def overlaps?(%Island{coordinates: coords}, %Island{coordinates: coords2}) do
    not MapSet.disjoint?(coords, coords2)
  end

  def guess(%Island{coordinates: coords, hit_coordinates: hit_coords} = island, %Coordinate{} = coordinate) do
    case MapSet.member?(coords, coordinate) do
      true -> {:hit, %{island | hit_coordinates: MapSet.put(hit_coords, coordinate)}}
      false -> :miss
    end
  end

  def forested?(%Island{coordinates: coords, hit_coordinates: hit_coords}), do: MapSet.equal?(coords, hit_coords)

  defp add_coordinates(offsets, upper_left) do
    Enum.reduce_while(offsets, MapSet.new(), fn offset, acc ->
      add_coordinate(acc, upper_left, offset)
    end)
  end

  defp add_coordinate(coordinates, %Coordinate{row: row, col: col}, {row_offset, col_offset}) do
    case Coordinate.new(row + row_offset, col + col_offset) do
      {:ok, coord} -> {:cont, MapSet.put(coordinates, coord)}
      {:error, _} = error -> {:halt, error}
    end
  end

  defp offset(:square), do: [{0,0}, {0,1}, {1,0}, {1,1}]
  defp offset(:atoll), do: [{0,0}, {0,1}, {1,1}, {2,0}, {2,1}]
  defp offset(:dot), do: [{0,0}]
  defp offset(:l_shape), do: [{0,0}, {1,0}, {2,0}, {2,1}]
  defp offset(:s_shape), do: [{0,1}, {0,2}, {1,0}, {1,1}]
  defp offset(_), do: {:error, :invalid_island_type}
end
