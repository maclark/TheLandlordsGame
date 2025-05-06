class_name Landlord
extends Node2D


var GameBoardScene = preload("res://GameBoard.tscn")
var PlayerTokenScene = preload("res://PlayerToken.tscn")
var PlayerClass = preload("res://scripts/Player.gd")
var UserClass = preload("res://scripts/User.gd")
var boards : Array[GameBoard] = []
var default_player_names : Array[String] = []
var hosting_button : Button = null
var fake_user : User = null
var board_count : int = 0

# default settings
const MAX_PLAYERS 				= 99
const LABOR_ON_MOTHER_EARTH 	= 200
const TIME_PER_TURN 			= 60.0
const TIME_PER_BID 				= 10.0
const START_MONEY 				= 1500
const PLAYER_COLORS = [Color.DARK_RED, Color.AQUA, Color.CHARTREUSE, Color.YELLOW]

func _ready() -> void:
	fake_user = UserClass.new()
	hosting_button = $HostingButton
	hosting_button.text = "HOST BOARD"
	hosting_button.pressed.connect(pressed_hosting_button.bind(hosting_button))
	
	var file = FileAccess.open("res://scripts/funny_random_names.txt", FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line != "":
			default_player_names.append(line)
	file.close()

func pressed_hosting_button(butt : Button) -> void:
	# need to get user from browser somehow here
	if butt.text == "HOST BOARD":
		butt.text = "UNHOST BOARD"
		host_board(fake_user)
	else:
		butt.text = "HOST BOARD"
		unhost_board(fake_user)

func host_board(user : User) -> void:
	var board = GameBoardScene.instantiate() as GameBoard
	add_child(board)
	board_count += 1
	board.init_board(board_count, self, user)
	boards.append(board)
	board.add_player(user, false)
	board.add_ai()
	print("hosting board_%s" % board.id)
	# TODO make buttons for adding/remo players

func unhost_board(user : User) -> void:
	var board = user.board
	if not board:
		push_warning("%s doesn't have a board to unhost!" % user.nickname)
		return
	if board.host != user:
		push_warning("%s isn't the host! not allowed!" % user.nickname)
		return
	print("unhosting board_%s" % board.id)
	for p in board.players:
		p.user.board = null
	boards.erase(board)
	board.queue_free()
	
func make_board_public(user : User) -> void:
	if user.board:
		user.board.private_board = true
	refresh_board_list()
	
func make_board_private(user : User) -> void:
	if user.board:
		user.board.private_board = true
	refresh_board_list()
		
func refresh_board_list() -> void:
	var public_games = ""
	var private_games = ""
	for board in boards:
		if board.private_board:
			private_games += "board_%s is private, hosted by %s.\n" % [board.id, board.host.nickname]
		else: 
			public_games += "board_%s is public, hosted by %s.\n" % [board.id, board.host.nickname]
	print(public_games)
	print(private_games)
	
