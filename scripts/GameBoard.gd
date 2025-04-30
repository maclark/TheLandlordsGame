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
var turn_timer: 			float = 0.0
var turn_clock:				Label = null

var single_taxing:			bool = false
var current_laps:			int = 0
var square_going_to:		Square = null
var square_came_from:		Square = null
var current_player_money:	Label = null

# bidding
var bidders: 				Array[Player]
var bidder_index:			int = 0
var top_bid:				int = 0
var min_bid_increment:		int = 50
var bid_input:				LineEdit = null
var noncurrent_ui:			Node2D = null
var noncurrent_bid_input:	LineEdit = null
var top_bidders:			Array[Player] = []
var bid_button:				Label = null
var bid_timer:				float = 0.0
var bid_clock:				Label = null

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
	WaitingForEndTurn,
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
	var start_button: Button = $Start
	start_button.pressed.connect(start_game)
	var roll_button: Button = $Roll
	roll_button.pressed.connect(roll_dice)
	var add_ai_button: Button = $AddAI
	add_ai_button.pressed.connect(add_ai)
	var temp_skip_button: Button = $Skip
	temp_skip_button.pressed.connect(skip_input)
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
					place_player_token(current_player, square_going_to)
					process_square(current_player, square_came_from, square_going_to)
					current_laps = 0
		Mode.Rolling:
			turn_timer -= delta
			turn_clock.text = floor(turn_timer)
			if turn_timer < 0:
				end_turn()
		Mode.PayingDebts:
			turn_timer -= delta
			turn_clock.text = floor(turn_timer)
			if turn_timer < 0:
				end_turn()
		Mode.Bidding:
			bid_timer -= delta
			bid_clock.text = floor(bid_timer)
			if bid_timer <= 0:
				pass_bid()
				
		Mode.WaitingForEndTurn:
			# player could build a house now or something
			turn_timer -= delta
			turn_clock.text = floor(turn_timer)
			if turn_timer < 0:
				end_turn()

func skip_input() -> void:
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
	update_money(current_player)
	print("now it's %s's turn!" % current_player.nickname)
	turn_timer = time_per_turn

func update_money(p: Player) -> void:
	if p == current_player:
		current_player_money.text = "MONEY: $%s" % str(current_player.money)
	else:
		push_warning("how do we update non current player money?")
	
func end_turn() -> void:
	# TODO close dialog windows or whatever
	next_turn()

func roll_dice() -> void:
	if not paused && game_started && mode == Mode.Rolling:
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
	var neighbors = players.filter(func(n): return n != p and n.square == square)
	var spread_out = false
	for i in range(20):
		spread_out = true
		p.token.position = square.position + 2.5 * i * Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		)
		for other in neighbors:
			var dist = p.token.position.distance_to(other.token.position)
			if dist < 10:
				spread_out = false
		if spread_out:
			break
			
func pass_go() -> void:
	print("%s labored on Mother Earth, gained $%d" % [current_player.nickname, labor_on_mother_earth])
	current_player.money += labor_on_mother_earth
	update_money(current_player)
	
func charge_rent(tenant: Player, square: Square) -> void:
	# TODO #SINGLETAX
	var rent = 10
	match square.type:
		Square.Type.Property:
			rent = square.base_price + square.houses * square.house_rent
		Square.Type.Utility:
			push_warning("utility rent?")
		Square.Type.Railroad:
			push_warning("railroad rent?")
		
	print("pay rent!: $%d" % rent)
	if tenant.money >= rent:
		tenant.money -= rent
		square.lord.money += rent
		update_money(tenant)
		update_money(square.lord)
	else:
		mode = Mode.PayingDebts
		
func start_auction(for_sale : Square) -> void:
	print("start bidding for %s" % for_sale.title)
	mode = Mode.Bidding
	bidders = players.duplicate(true)
	bidder_index = bidders.find(current_player) - 1
	top_bid = for_sale.base_price
	next_bidder();
	
func conclude_auction() -> void:
	# we're assuming the square for sale is current player's
	var property = current_player.square
	var winner = current_player
	if top_bidders.size() > 1:
		push_warning("how are we handling this?")
		if not top_bidders.has(current_player):
			winner = top_bidders.pick_random()
	elif top_bidders.size() == 0:
		push_warning("can we conclude an auction with no winner? check rules")
		# TODO auction with no winner?
	else:
		winner = top_bidders[0]
	winner.properties.push(property)
	property.lord = winner
	print("{winner.nickname} won auction with bid {top_bid}. now owns {current_player.square.title}")
	winner.money -= top_bid
	update_money(winner)
	if winner != current_player:
		charge_rent(current_player, property)
	mode = Mode.WaitingForEndTurn
	
func pass_bid() -> void:
	bidders.remove_at(bidder_index)
	# how do i handle calling? is that allowed? i forget the rules
	# but i thought it said something like
	# if everyone bids the same amount, the current player gets it
	# but if two non current player bid the same amount, what then?
	# what about using vickrey auctions?
	if bidders.size() == top_bidders.size():
		conclude_auction()
	else:
		next_bidder()

func current_player_pressed_bid() -> void:
	if current_player == bidders[bidder_index]:
		if bid_input.text.is_valid_int(): 
			var amount = int(bid_input.text)
			if amount >= top_bid:
				bid(amount)
		else:
			push_warning("invalid bid amount: {bid_input.text}")

func noncurrent_local_player_pressed_bid() -> void:
	var bidder: Player = bidders[bidder_index]
	if noncurrent_bid_input.text.is_valid_int(): 
		var amount = int(noncurrent_bid_input.text)
		if amount >= top_bid:
			bid(amount)
	else:
		push_warning("invalid bid amount: {bid_input.text}")
		
func bid(amount: int) -> void:
	if amount < top_bid:
		print("bid {amount} is less than top bid of {top_bid}")
	elif amount == top_bid:
		print("how do we handle equal top bids? i forget")
		next_bidder()
	else:
		top_bid = amount
		next_bidder()
		
func next_bidder() -> void:
	bidder_index = (bidder_index + 1) % bidders.size()
	noncurrent_ui.visible = false
	var bidder: Player = players[bidder_index] 
	if bidder.is_ai:
		if bidder.money > top_bid + min_bid_increment:
			# let's say 50/50 they bid
			if randf() > .5:
				bid(top_bid + min_bid_increment)
			else:
				pass_bid()
	elif bidder == current_player:
		pass
	elif bidder.user == current_player.user:
		noncurrent_ui.visible = true
	else:
		pass
		
	bid_timer = time_per_bid
	bid_clock.text = floor(bid_timer)
	
func process_square(p : Player, _came_from : Square, landed_on : Square) -> void:
	p.square = landed_on
	print("%s is now on square_%d: %s" % [p.nickname, landed_on.num, landed_on.title])
	
	# track this, in case they unpass Go (see rules)
	var retreated = false
	
	match landed_on.type:
		Square.Type.Go:
			pass
		Square.Type.Property:
			if landed_on.lord == null:
				start_auction(landed_on)
			elif landed_on.lord == current_player:
				print("nothing happens, since %s owns %s" % [current_player.nickname, landed_on.title])
			else:
				charge_rent(current_player, landed_on)
		
		Square.Type.Utility:
			if landed_on.lord == null:
				start_auction(landed_on)
			elif landed_on.lord == current_player:
				print("nothing happens, since %s owns %s" % [current_player.nickname, landed_on.title])
			else:
				push_warning("calculate Utility rent")
				charge_rent(current_player, landed_on)
				
		Square.Type.Railroad:
			if landed_on.holder == null:
				start_auction(landed_on)
			elif landed_on.holder == current_player:
				print("nothing happens, since %s owns %s" % [current_player.nickname, landed_on.title])
			else:
				push_warning("calculate Railroad rent")
				charge_rent(current_player, landed_on)
				
		Square.Type.Chance:
			mode = Mode.ReadingCard
		Square.Type.CommunityChest:
			mode = Mode.ReadingCard
		Square.Type.Luxuries:
			mode = Mode.ReadingCard
		Square.Type.Jail:
			pass
		Square.Type.BluebloodsEstate:
			mode = Mode.JailingPlayer
		Square.Type.CollegeOrFreeLand:
			pass
			
		Square.Type.Undefined:
			push_warning("undefined square!")
	
	print(current_laps)
	for i in current_laps:
		if not retreated:
			pass_go()
		
	end_turn()
	
