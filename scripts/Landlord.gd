class_name Landlord
extends Node2D

const MAX_PLAYERS = 99
const LABOR_ON_MOTHER_EARTH = 200
const TIME_PER_TURN = 60.0

@onready var board = $GameBoard

# TODO encapsulate all of this in a game instance
# so that multiple games can be handled at once

var PlayerTokenScene = preload("res://PlayerToken.tscn")
var PlayerClass = preload("res://scripts/Player.gd")
var players: Array[Player] = [];
var start_money = 1500 # TODO look this up
var current_player_index : int = 0
var current_player : Player = null
var time_turn_started : float = 0.0
var paused : bool = false
var game_running : bool = false

func _ready() -> void:
	pass
	
func _process(_delta: float) -> void:
	if not paused and game_running:
		if Time.get_ticks_msec() - time_turn_started > TIME_PER_TURN:
			end_turn()

func start_game() -> void:
	if players.size() == 0:
		print("can't play with no players!")
		return
	players.shuffle()
	# TODO update player list ui i guess
	for p in players:
		p.money = start_money
		p.token = PlayerTokenScene.instantiate()
		board.place_player_token(p, board.squares[0])
	
func add_player(name : String, is_ai : bool) -> void:
	if game_running:
		print("we don't handle adding players during game right now")
		return
	if players.size() >= MAX_PLAYERS:
		print("no more players geez louweez, already got %s" % players.size())
		return
	var p = PlayerClass.new()
	p.name = name
	p.is_ai = is_ai
	players.append(p)
	
func remove_player(name : String) -> void:
	var index = -1
	for i in players.size():
		if players[i].name == name:
			index = i
			break
			
	if index >= 0:
		players.remove_at(index)
	else: 
		# for reference: print("%s %s" [firstName, lastName])
		print("couldn't find player with name %s " % name)
		
func next_turn() -> void:
	# update ui
	current_player_index = (current_player_index + 1) % players.size()
	print("now it's %s's turn!" % players[current_player_index])
	time_turn_started = Time.get_ticks_msec() # TODO browser: get global time?
	
func end_turn() -> void:
	# TODO close dialog windows or whatever
	next_turn()

func process_roll(p : Player, die0 : int, die1 : int) -> void:
	if die0 == die1:
		if p.in_jail:
			p.in_jail = false
			print("got out of jail!")
		else:
			print("handle super highway or whatever doubles means")
		next_turn()
	else:
		var distance = die0 + die1
		var square_index = p.square.num + distance
		if square_index > board.squares.size():
			# passed GO! collect $200
			p.money += LABOR_ON_MOTHER_EARTH
			square_index -= board.squares.size()
		
		var old_square = p.square
		board.place_player_token(p, board.squares[square_index])
		board.process_square(p, old_square)
