class_name Landlord
extends Node2D

# TODO a chat! duh, ugh

@onready var listings:				Node2D = $Listings

var BoardListingScene 		= preload("res://BoardListing.tscn")
var GameBoardScene 			= preload("res://GameBoard.tscn")
var PlayerTokenScene 		= preload("res://PlayerToken.tscn")
var PlayerClass 			= preload("res://scripts/Player.gd")
var UserClass 				= preload("res://scripts/User.gd")
var board_listings:			Array[BoardListing] = []
var default_player_names: 	Array[String] = []
var hosting_button: 		Button = null
var fake_user: 				User = null
var board_count: 			int = 0

# default settings
const MAX_PLAYERS 				= 99
const LABOR_ON_MOTHER_EARTH 	= 200
const TIME_PER_TURN 			= 60.0
const TIME_PER_BID 				= 1000.0
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
		create_board_listing(fake_user)
	elif fake_user.listing:
		var listing = fake_user.listing
		leave_board(listing.id)
		remove_board_listing(listing.id)
		butt.text = "HOST BOARD"

func draw_board_listings() -> void:
	var y_offset = 10;
	for listing in board_listings:
		listing.position = Vector2(300, y_offset)
		y_offset += 100.0
		
func create_board_listing(host: User) -> void:
	board_count += 1
	var listing = BoardListingScene.instantiate() as BoardListing
	listings.add_child(listing)
	board_listings.append(listing)
	listing.init(board_count, host)
	listing.join_butt.visible = fake_user.board == null
	listing.leave_butt.visible = false
	listing.join_butt.pressed.connect(func(): join_board(listing.id))
	listing.leave_butt.pressed.connect(func(): leave_board(listing.id))
	draw_board_listings()
	
func remove_board_listing(id: int) -> void:
	var listing_index = board_listings.find_custom(func(l): return l.id == id)
	var listing = board_listings[listing_index]
	if listing != null:
		listing.queue_free()
		board_listings.remove_at(listing_index)
	draw_board_listings()
	
func hide_board() -> void:
	listings.visisble = true
	fake_user.board.visible = false
	
func join_board(id: int) -> void:
	hosting_button.text = "UNHOST BOARD"
	var listing_index = board_listings.find_custom(func(l): return l.id == id)
	var listing = board_listings[listing_index]
	if listing.join_butt.text == "SIT":
		# TODO NEXT
		fake_user.board.visible = true
		listings.visible = false
	else:
		fake_user.listing = listing
		listing.set_player_count(listing.player_count + 1)
		listing.join_butt.text = "SIT"
		listing.leave_butt.visible = true
		for l in board_listings:
			if l != listing:
				l.join_butt.visible = false
	
func leave_board(id: int) -> void:
	hosting_button.text = "HOST BOARD"
	fake_user.listing = null
	var listing_index = board_listings.find_custom(func(l): return l.id == id)
	var listing = board_listings[listing_index]
	listing.set_player_count(listing.player_count - 1)
	listing.join_butt.text = "JOIN"
	listing.leave_butt.visible = false
	for l in board_listings:
		l.join_butt.visible = true

func host_board(user : User) -> void:
	var board = GameBoardScene.instantiate() as GameBoard
	add_child(board)
	board_count += 1
	board.init_board(board_count, self, user)
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
	board.queue_free()
