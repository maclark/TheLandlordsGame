class_name GameBoard
extends Node2D

@export var player_label_spacing : int = 25

var id : 					int = -1
var lord : 					Landlord = null
var host : 					User = null
var private_board : 		bool = false
var squares : 				Array[Square] = []
var players: 				Array[Player] = []
var player_labels: 			Array[Label] = []
var current_player_index : 	int = 0
var current_player : 		Player = null
var time_turn_started : 	float = 0.0
var paused : 				bool = false
var game_running : 			bool = false

# adjustable game settings
var start_money : int = Landlord.START_MONEY
var labor_on_mother_earth : int = Landlord.LABOR_ON_MOTHER_EARTH

func init_board(new_id : int, new_lord : Landlord, new_host : User) -> void:
	id = new_id
	lord = new_lord
	host = new_host 
	var start_button : Button = $StartButton
	start_button.pressed.connect(start_game)
	var roll_button : Button = $Roll
	roll_button.pressed.connect(roll_dice)
	var add_ai_button : Button = $AddAI
	add_ai_button.pressed.connect(add_ai)
	
	var square_index = 0
	for c in get_children():
		if c is Square:
			c.num = square_index
			print("square found, num is %d" % c.num)
			square_index += 1
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
	for p in players:
		p.money = start_money
	#players.shuffle() only uncomment if we're willing to redraw ai
	current_player = players[0]
	print("GO! first player is %s" % current_player.nickname)
		
func add_ai() -> void:
	add_player(players[0].user, true)

func add_player(user : User, is_ai : bool) -> void:
	var found_unique_name = false
	var nickname = ""
	while not found_unique_name:
		found_unique_name = true
		nickname = lord.default_player_names.pick_random();
		for p in players:
			if p.nickname == nickname:
				found_unique_name = false
	if is_ai:
		nickname += "_AI"
	
	if game_running:
		print("we don't handle adding players during game right now")
		return
	if players.size() >= lord.MAX_PLAYERS:
		print("no more players geez louweez, already got %s" % players.size())
		return
	
	user.board = self
	
	var p = lord.PlayerClass.new()
	p.user = user
	p.nickname = nickname
	p.is_ai = is_ai
	p.token = lord.PlayerTokenScene.instantiate() as PlayerToken
	self.add_child(p.token)
	var color_index = players.size() % Landlord.PLAYER_COLORS.size()
	p.token.sprite.set_modulate(Landlord.PLAYER_COLORS[color_index])
	place_player_token(p, squares[0])
	# we assign them Go, but don't give 'em 
	# Mother Nature's Bounty just for being born
	p.square = squares[0] 
	players.append(p)
	
	# setup the labels
	var label : Label = Label.new()
	label.text = nickname
	var y_offset = 10.0 + player_labels.size() * player_label_spacing
	label.position = Vector2(get_viewport().size.x - 200.0, y_offset)
	add_child(label)
	player_labels.append(label)
	
func remove_player(nickname : String) -> void:
	var index = -1
	for i in players.size():
		if players[i].nickname == nickname:
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
	current_player = players[current_player_index]
	print("now it's %s's turn!" % current_player.nickname)
	time_turn_started = Time.get_ticks_msec() # TODO browser: get global time?
	
func end_turn() -> void:
	# TODO close dialog windows or whatever
	next_turn()

func roll_dice() -> void:
	if game_running:
		process_roll(current_player, randi_range(1, 6), randi_range(1, 6))
	else:
		print("no rolling dice, game hasn't started!")

func process_roll(p : Player, die0 : int, die1 : int) -> void:
	print("%s rolled %d+%d=%d" % [p.nickname, die0, die1, (die0 + die1)])
	if die0 == die1:
		if p.in_jail:
			p.in_jail = false
			push_warning("TODO: got out of jail!")
		else:
			push_warning("TODO: handle super highway or whatever doubles means")
			
	var distance = die0 + die1
	var square_index = p.square.num + distance
	if square_index >= squares.size():
		# passed GO! collect $200
		p.money += labor_on_mother_earth
		square_index -= squares.size()
		
	var came_from = p.square
	var landed_on = squares[square_index]
	place_player_token(p, landed_on)
	process_square(p, came_from, landed_on)

func place_player_token(p : Player, square : Square) -> void:
	var temp_square_width = 10.0 # only the corners are squares, actually
	var offset = temp_square_width * Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	)
	p.token.position = square.position + offset
	
func process_square(p : Player, _came_from : Square, landed_on : Square) -> void:
	p.square = landed_on
	print("%s is now on square_%d" % [p.nickname, landed_on.num])
	end_turn()
	
