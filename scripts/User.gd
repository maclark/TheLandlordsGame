# this is what a person browsing the website will be
# when they join a game, they can become a player
# they can also host multiple local players
class_name User 
extends Node

var board: 		GameBoard = null
var listing: 	BoardListing = null
var nickname: 	String = "hg"
var local: 		bool = false
