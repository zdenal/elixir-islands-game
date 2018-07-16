defmodule IslandsEngine.Board do
  alias IslandsEngine.{Coordinate, Island}

  def new do
    %{}
  end

  def all_island_positioned?(board) do
    Enum.all?(Island.types, &(Map.has_key?(board, &1)))
  end

  def position_island(board, type, %Island{} = island) do
    case overlapping_island?(board, island) do
      true -> {:error, :overlapping_island}
      false -> Map.put(board, type, island)
    end
  end

  def guess(board, %Coordinate{} = coordinate) do
    board
    |> check_all_islands(coordinate)
    |> guess_response(board)
  end

  defp check_all_islands(board, %Coordinate{} = coordinate) do
    Enum.find_value(board, :miss, fn {type, island} ->
      case Island.guess(island, coordinate) do
        {:hit, island} -> {type, island}
        :miss -> false
      end
    end)
  end

  defp guess_response({type, island}, board) do
    board = %{board | type => island}

    {:hit, forest_check(board, type), win_check(board), board}
  end
  defp guess_response(:miss, board), do: {:miss, :none, :no_win, board}

  defp forest_check(board, type) do
    case board |> Map.fetch!(type) |> Island.forested? do
      true -> type
      false -> :none
    end
  end

  defp win_check(board) do
    case all_forested?(board) do
      true -> :win
      false -> :no_win
    end
  end

  defp all_forested?(board) do
    Enum.all?(board, fn {_, island} ->
      Island.forested?(island)
    end)
  end

  defp overlapping_island?(board, %Island{} = new_island) do
    Enum.any?(board, fn {_, island} ->
      Island.overlaps?(island, new_island)
    end)
  end
end
