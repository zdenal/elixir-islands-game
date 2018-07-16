# Why
I have chosen to read this book **Functional Web Development with Elixir, OTP, and Phoenix** mainly for approach to how to build web applications.
Postpone adding framework and data storage. As it is well described in book our applications should have their own domains,
completely separate from the framework. They should maintain a clean separation between the interface and the core application domain.
The slippery slope is that frameworks make it all too easy to tangle the framework components and the application together in ways that really hurt us

It is why using the Phoenix and game engine Applications as building blocks to create a third Application that
will keep the Phoenix interface separate from the game in a way that will make our job trivially easy.

## Start
Go to `islands_interface` folder and run `mix deps.get`, then `iex -S mix phx.server`. Run server in interactive mode is for testing reason. Eg. you
can test some stuff/states through `:sys.get_state(address)` on server and so on. Then open 2 browser, open consoles there
and play with channel's functions which you can find in `islands_interface/assets/js/app.js` with some commented command examples.

## IslandsEngine
The main domain of game which is responsible for game rules and providing interface for playing games (new game, add player, set island, ...).
It is designed by OTP with supervisor and dynamically created services for each game (via Registry). State for each game is persisted
in ETS (Erlang Term Storage) which allow us to recovery state after process crash (fault tolerance - supervisor is automatically restarting
process when it is crashed ... dependent on child spec and so on).

## IslandsInterface
The web app handling everything around channels (messaging/broadcasting, Presence, simple authorization) for clients and interacting with **IslandsEngine** application.

## My notices

### GenServer
There’s a direct mapping between GenServer module functions and callbacks. Calling GenServer.start_link/3 will always trigger GenServer.init/1. GenServer.call/3 calls GenServer.handle_call/3, and GenServer.cast/2 maps to GenServer.handle_cast/2.
Calling eg. `send(self(), {:action, params})` will be handled by `handle_info({:action, params}, ..)`.

- we can overwrite default opts for GenServer by `use GenServer, opts` ... see in `lib/game.ex`.
  We can also overwrite default functions as it is in `lib/game_supervisor.ex`.
- `:sys.get_state(address)` get state of service directly via erland module. In this project we can generate address by `Game.via_tuple("game_name")`, which
  is generating tuple for using `Registry` service which generate addresses for processes. Result is eg. `{:via, Registry, {Registry.Game, "game_name"}}`.
  By `GenServer.whereis(via_address)` we can see back PID of process.
- `Supervisor.which_children(GameSupervisor)` see status of supervisor (running children and etc..)

### Presence
Presence keep track of the clients subscribed to a topic on a channel.
That means keeping track of the players in each game. Presence does this amazingly well.
It use CRDTs (conflict-free replicated datatypes). They track the sequence of clients joining and leaving, across nodes and clients.
CRDTs allow Presence to reconstruct the sequence of events to accurately determine which clients are currently subscribed to a topic on a channel.

For generating presence you can use: `mix phx.gen.presence` what will generate: `islands_interface/lib/islands_interface_web/channels/presence.ex`

Don't forget add into `lib/islands_interface/application.ex` the Presence module in the list of children.

### Addinng external app (IslandsEngine)
For adding external app into another app (IslandsInterface) add into `mix.exs` eg.:
```
  defp deps do
    [
      ...
      {:islands_engine, path: "../islands_engine"}
      ...
    ]
  end
```

### JS client
In `islands_interface/assets/js/app.js` are prepared functions from book to test Phoenix channels from browser console.

