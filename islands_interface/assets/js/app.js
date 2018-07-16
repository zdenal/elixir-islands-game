// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"

import {Socket} from "phoenix"
window.socket = new Socket("/socket", {})

socket.connect()

window.new_channel = function(subtopic, screenName) {
  return socket.channel("game:"+subtopic, {screen_name: screenName})
}

window.join = function(channel) {
  channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })
}

window.leave = function(channel) {
  channel.leave()
    .receive("ok", resp => { console.log("Left successfully", resp) })
    .receive("error", resp => { console.log("Unable to leave", resp) })
}

window.new_game = function(channel) {
  channel.push("new_game")
    .receive("ok", resp => { console.log("New Game:", resp) })
    .receive("error", resp => { console.log("Unable to start new game", resp) })
}

window.add_player = function(channel, player) {
  channel.push("add_player", player)
    .receive("error", resp => { console.log("Unable to add player: " + player, resp) })
}

window.position_island = function(channel, player, island, row, col) {
  var params = {"player": player, "island": island, "row": row, "col": col}

  channel.push("position_island", params)
    .receive("ok", response => { console.log("Island positioned!", response) })
    .receive("error", response => { console.log("Unable to position island.", response) })
}

window.guess_coordinate = function(channel, player, row, col) {
  var params = {"player": player, "row": row, "col": col}

  channel.push("guess_coordinate", params)
    .receive("ok", response => { console.log("Island positioned!", response) })
    .receive("error", response => { console.log("Unable to position island.", response) })
}

window.set_islands = function(channel, player) {
  channel.push("set_islands", player)
    .receive("error", resp => { console.log("Unable to guess coordinate: " + player, resp) })
}

// From console #1
//var channel = new_channel("zdenal", "zdenal")
//channel.on("player_added", resp => { console.log("Player added", resp) })
//channel.on("player_set_islands", resp => { console.log("Player set islands", resp) })
//channel.on("player_guessed_coordinate", resp => { console.log("Player gussed coordinate:", resp) })
//join(channel)
//new_game(channel)


// From console #2
//var channel = new_channel("zdenal", "zdenal")
//channel.on("player_added", resp => { console.log("Player added", resp) })
//channel.on("player_set_islands", resp => { console.log("Player set islands", resp) })
//channel.on("subscribers", resp => { console.log("List of players: ", resp) })
//channel.on("player_guessed_coordinate", resp => { console.log("Player gussed coordinate:", resp) })
//join(channel)
// add_player("petr")
//position_island(game_channel, "player2", "atoll", 1, 1)
//position_island(game_channel, "player2", "dot", 1, 5)
//position_island(game_channel, "player2", "l_shape", 1, 7)
//position_island(game_channel, "player2", "s_shape", 5, 1)
//position_island(game_channel, "player2", "square", 5, 5)
//position_island(game_channel, "player1", "dot", 1, 1)
//set_islands(game_channel, "player2")
//guess_coordinate(game_channel, "player2", 1, 5)
//channel.push("show_subscribers")
