defmodule IslandsEngine.Game do
	use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

  alias IslandsEngine.{Board, Guesses, Rules, Island, Coordinate}

  @players [:player1, :player2]
	@timeout 60 * 60 * 1000

  # Client functions
  def start_link(name) when is_binary(name), do: GenServer.start_link(__MODULE__, name, name: via_tuple(name))

  def via_tuple(name), do: {:via, Registry, {Registry.Game, name}}

  def add_player(game, name) when is_binary(name), do: GenServer.call(game, {:add_player, name})

  def position_island(game, player, type, row, cow) when player in @players do
    GenServer.call(game, {:position_island, player, type, row, cow})
  end

  def set_islands(game, player) when player in @players, do: GenServer.call(game, {:set_islands, player})

  def guess_coordinate(game, player, row, col) when player in @players, do: GenServer.call(game, {:guess_coordinate, player, row, col})

  # Callbacks
  def init(name) do
    send(self(), {:set_state, name})

    {:ok, new_state(name)}
  end

	def terminate({:shutdown, :timeout}, state_data) do
		:ets.delete(:game_state, state_data.player1.name)
		:ok
	end
	def terminate(_reason, _state), do: :ok

	#####################################################
	## Tagging the return tuple with :stop causes
	## the Behaviour to trigger the terminate/2 callback
	#####################################################
	def handle_info(:timeout, state_data) do
		{:stop, {:shutdown, :timeout}, state_data}
	end

  def handle_info({:set_state, name}, _state) do
    state = case :ets.lookup(:game_state, name) do
      [] -> new_state(name)
      [{_key, state}] -> state
    end

    :ets.insert(:game_state, {name, state})
    {:noreply, state, @timeout}
  end

  def handle_call({:add_player, name}, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, :add_player) do
      state
      |> put_in([:player2, :name], name)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, state}
    end
  end

  def handle_call({:position_island, player, type, row, col}, _from, state) do
    board = player_board(state, player)

    with {:ok, rules} <- Rules.check(state.rules, {:position_island, player}),
         {:ok, coord} <- Coordinate.new(row, col),
         {:ok, island} <- Island.new(type, coord),
         %{} = board <- Board.position_island(board, type, island) do
      state
      |> update_board(player, board)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:set_islands, player}, _from, state) do
    board = player_board(state, player)

    with {:ok, rules} <- Rules.check(state.rules, {:set_islands, player}),
         true <- Board.all_island_positioned?(board) do
      state
      |> update_rules(rules)
      |> reply_success({:ok, board})
    else
      :error -> {:reply, :error, state}
      false -> {:reply, {:error, :not_all_islands_positioned}, state}
    end
  end

  def handle_call({:guess_coordinate, player, row, col}, _from, state) do
    opponent = player_board(state, get_opponent(player))
    opponent_board = player_board(state, get_opponent(player))

    with {:ok, rules} <- Rules.check(state.rules, {:guess_coordinate, player}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {hit_or_miss, forested_island, win_status, opponent_board} <- Board.guess(opponent_board, coordinate),
         {:ok, rules} <- Rules.check(rules, {:win_check, win_status}) do
      state
      |> update_board(opponent, opponent_board)
      |> update_guesses(player, hit_or_miss, coordinate)
      |> update_rules(rules)
      |> reply_success({hit_or_miss, forested_island, win_status})
    else
      :error ->
        {:reply, :error, state}
      {:error, :invalid_coordinate} ->
        {:reply, {:error, :invalid_coordinate}, state}
    end
  end

  defp new_state(name) do
    player1 = %{name: name, board: Board.new, guesses: Guesses.new}
    player2 = %{name: nil, board: Board.new, guesses: Guesses.new}

    %{player1: player1, player2: player2, rules: Rules.new}
  end

  defp get_opponent(:player1), do: :player2
  defp get_opponent(:player2), do: :player1

  defp update_board(state, player, board) when player in @players, do: put_in(state, [player, :board], board)

  defp update_rules(state, rules), do: %{state | rules: rules}

  defp reply_success(state, message) do
    :ets.insert(:game_state, {state.player1.name, state})
    {:reply, message, state, @timeout}
  end

  defp player_board(state, player) when player in @players, do: Map.get(state, player).board

  defp update_guesses(state, player, hit_or_miss, coordinate) do
    update_in(state[player].guesses, fn guesses ->
      Guesses.add(guesses, hit_or_miss, coordinate)
    end)
  end
end
