class_name GameBoard
extends Node2D

var id : int = -1
var lord : Landlord = null
var host : User = null
var private_board : bool = false
var squares : Array[Square] = []
var players: Array[Player] = [];
var current_player_index : int = 0
var current_player : Player = null
var time_turn_started : float = 0.0
var paused : bool = false
var game_running : bool = false

# adjustable game settings
var start_money : int = Landlord.START_MONEY
var labor_on_mother_earth : int = Landlord.LABOR_ON_MOTHER_EARTH

func init_board(new_id : int, new_lord : Landlord, new_host : User) -> void:
	id = new_id
	lord = new_lord
	host = new_host 
	for c in get_children():
		if c is Square:
			squares.append(c as Square)
	# TODO could probably load the last settings this user used
	
func _process(_delta: float) -> void:
	if not paused and game_running:
		if Time.get_ticks_msec() - time_turn_started > Landlord.TIME_PER_TURN:
			end_turn()
			

func start_game() -> void:
	game_running = true
	paused = false
	if players.size() == 0:
		print("can't play with no players!")
		return
	players.shuffle()
	for p in players:
		p.money = start_money
		
func add_player(user : User, nickname : String, is_ai : bool) -> void:
	if game_running:
		print("we don't handle adding players during game right now")
		return
	if players.size() >= lord.MAX_PLAYERS:
		print("no more players geez louweez, already got %s" % players.size())
		return
	var p = lord.PlayerClass.new()
	p.user = user
	p.nickname = nickname
	p.is_ai = is_ai
	p.token = lord.PlayerTokenScene.instantiate() as PlayerToken
	self.add_child(p.token)
	var color_index = players.size() % Landlord.PLAYER_COLORS.size()
	p.token.sprite.set_modulate(Landlord.PLAYER_COLORS[color_index])
	place_player_token(p, squares[0])
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
		if square_index > squares.size():
			# passed GO! collect $200
			p.money += labor_on_mother_earth
			square_index -= squares.size()
		
		var old_square = p.square
		place_player_token(p, squares[square_index])
		process_square(p, old_square)

func place_player_token(p : Player, square : Square) -> void:
	var offset = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	)
	p.token.position = square.position + offset
	
func process_square(_p : Player, _square : Square) -> void:
	push_warning("process_square: NOT IMPLEMENTED")
	end_turn()
	
