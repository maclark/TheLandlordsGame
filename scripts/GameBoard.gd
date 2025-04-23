class_name GameBoard
extends Node2D

@export var player_label_spacing : int = 25
@export var move_speed : float = 5.0

var id: 					int = -1
var lord: 					Landlord = null
var host: 					User = null
var private_board: 			bool = false
var squares: 				Array[Square] = []
var players: 				Array[Player] = []
var player_labels: 			Array[Label] = []

var mode:					Mode = Mode.Rolling
var paused:					bool = false
var game_started:			bool = false
var current_player_index: 	int = 0
var current_player: 		Player = null
var time_turn_started: 		float = 0.0
var time_of_last_bid: 		float = 0.0

var single_taxing:			bool = false
var current_laps:			int = 0
var square_going_to:		Square = null
var square_came_from:		Square = null
var current_player_money:	Label = null


# adjustable game settings
var start_money: 			int = 1
var labor_on_mother_earth: 	int = 1
var time_per_turn: 			float = 1.0
var time_per_bid: 			float = 1.0

enum Mode {
	Moving,
	Rolling,
	Bidding,
	PayingDebts,
	ReadingCard,
	JailingPlayer,
}

func reset_settings() -> void:
	start_money 			= Landlord.START_MONEY
	labor_on_mother_earth 	= Landlord.LABOR_ON_MOTHER_EARTH
	time_per_turn 			= Landlord.TIME_PER_TURN
	time_per_bid 			= Landlord.TIME_PER_BID

func init_board(new_id : int, new_lord : Landlord, new_host : User) -> void:
	reset_settings()
	
	id = new_id
	lord = new_lord
	host = new_host 
	var start_button: Button = $StartButton
	start_button.pressed.connect(start_game)
	var roll_button: Button = $Roll
	roll_button.pressed.connect(roll_dice)
	var add_ai_button: Button = $AddAI
	add_ai_button.pressed.connect(add_ai)
	
	current_player_money = $MoneyLabel
	assert(current_player_money)
	
	var square_index = 0
	for c in get_children():
		if c is Square:
			c.num = square_index
			print("square found, num is %d" % c.num)
			square_index += 1
			squares.append(c as Square)
	# TODO could probably load the last settings this user used
	
func start_game() -> void:
	game_started = true
	paused = false
	if players.size() == 0:
		print("can't play with no players!")
		return
	for p in players:
		p.money = start_money
	#players.shuffle() only uncomment if we're willing to redraw ai
	print("Go forth and labor upon Mother Earth!")
	current_player_index = -1
	next_turn()
		
func _process(delta: float) -> void:
	if game_started:
		if not paused:
			simulate_game(delta)
			
func simulate_game(delta: float) -> void:
	match mode:
		Mode.Moving:
			var step = delta * move_speed
			var next_square_index = current_player.square.num + 1
			if next_square_index == squares.size():
				next_square_index = 0
			var to_destination = squares[next_square_index].position - current_player.token.position 
			current_player.token.position += to_destination.normalized() * step
			if step > to_destination.length():
				if next_square_index == 0: # we've reached Go!
					current_laps += 1
				current_player.square = squares[next_square_index]
				if current_player.square == square_going_to:
					process_square(current_player, square_came_from, square_going_to)
					current_laps = 0
		Mode.Rolling:
			if Time.get_ticks_msec() - time_turn_started > time_per_turn:
				end_turn()
		Mode.PayingDebts:
			if Time.get_ticks_msec() - time_turn_started > time_per_turn:
				end_turn()
		Mode.Bidding:
			# TODO this depends
			if Time.get_ticks_msec() - time_of_last_bid > time_per_bid:
				end_turn()
	

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
	
	if game_started:
		push_warning("we don't handle adding players during game right now")
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
	# TODO update ui
	mode = Mode.Rolling
	current_player_index = (current_player_index + 1) % players.size()
	current_player = players[current_player_index]
	update_current_money()
	print("now it's %s's turn!" % current_player.nickname)
	time_turn_started = Time.get_ticks_msec() # TODO browser: get global time?

func update_current_money() -> void:
	current_player_money.text = "MONEY: $%s" % str(current_player.money)
	
func end_turn() -> void:
	# TODO close dialog windows or whatever
	next_turn()

func roll_dice() -> void:
	if not paused && mode == Mode.Rolling:
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
		
	square_going_to = squares[square_index]
	square_came_from = p.square
	mode = Mode.Moving
	

func place_player_token(p : Player, square : Square) -> void:
	var temp_square_width = 10.0 # only the corners are squares, actually
	var offset = temp_square_width * Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	)
	p.token.position = square.position + offset
	
func pass_go() -> void:
	print("%s labored on Mother Earth, gained $%d" % [current_player.nickname, labor_on_mother_earth])
	current_player.money += labor_on_mother_earth
	update_current_money()
	
func charge_rent(rent : int) -> void:
	print("pay rent!: $%d" % rent)
	if current_player.money >= rent:
		current_player.money -= rent
		update_current_money()
	else:
		mode = Mode.PayingDebts
		
func start_auction(for_sale : Square) -> void:
	print("start bidding for %s" % for_sale.title)
	mode = Mode.Bidding
	
func process_square(p : Player, _came_from : Square, landed_on : Square) -> void:
	p.square = landed_on
	print("%s is now on square_%d: %s" % [p.nickname, landed_on.num, landed_on.title])
	
	# track this, in case they don't pass Go
	var retreated = false
	
	match landed_on.type:
		Square.Type.Go:
			# do nothing, should get the money if you looped
			pass
		Square.Type.Property:
			print("property")
			if landed_on.holder == null:
				# start auction!
				start_auction(landed_on)
			elif landed_on.holder == current_player:
				print("nothing happens, since %s owns %s" % [current_player.nickname, landed_on.title])
			else:
				var rent_due = landed_on.base_rent + landed_on.houses * landed_on.house_rent 
				charge_rent(rent_due)
		
		Square.Type.Utility:
			print("Utility")
			if landed_on.holder == null:
				# start auction!
				start_auction(landed_on)
			elif landed_on.holder == current_player:
				print("nothing happens, since %s owns %s" % [current_player.nickname, landed_on.title])
			else:
				var rent_due = landed_on.base_rent
				push_warning("calculate Utility rent")
				charge_rent(rent_due)
				
		Square.Type.Railroad:
			print("Railroad")
			if landed_on.holder == null:
				# start auction!
				start_auction(landed_on)
			elif landed_on.holder == current_player:
				print("nothing happens, since %s owns %s" % [current_player.nickname, landed_on.title])
			else:
				var rent_due = landed_on.base_rent
				push_warning("calculate Railroad rent")
				charge_rent(rent_due)
				
		Square.Type.Chance:
			print("chance")
			mode = Mode.ReadingCard
		Square.Type.CommunityChest:
			print("community chest")
			mode = Mode.ReadingCard
		Square.Type.Luxuries:
			print("luxuries")
			mode = Mode.ReadingCard
		Square.Type.Jail:
			print("Jail")
		Square.Type.BluebloodsEstate:
			print("BluebloodsEstate")
			mode = Mode.JailingPlayer
		Square.Type.CollegeOrFreeLand:
			print("CollegeOrFreeLand")
			
		Square.Type.Undefined:
			push_warning("undefined square!")
	
	print(current_laps)
	for i in current_laps:
		if not retreated:
			pass_go()
		
	end_turn()
	
