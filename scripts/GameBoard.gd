class_name GameBoard
extends Node2D

@onready var mode_lab:		Label = get_node("%DebugMode")

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

@onready var game_ui: 				Node2D = $GameUI
@onready var start_butt: 			Button = get_node("%Start")
@onready var noncurrent_ui:			Node2D = get_node("%LocalNonCurrentPlayerBidGroup")
@onready var current_player_label:	Label = get_node("%CurrentPlayerLabel")
@onready var turn_clock:			Label = get_node("%TurnClock")
@onready var roll_butt:				Button = get_node("%Roll")
@onready var bid_butt:				Button = get_node("%Bid")
@onready var pass_bid_butt:			Button = get_node("%PassBid")
@onready var build_house_butt:		Button = get_node("%BuildHouse")
@onready var trade_butt:			Button = get_node("%Trade")
@onready var end_turn_butt:			Button = get_node("%EndTurn")
var current_player_index: 	int = 0
var current_player: 		Player = null
var turn_timer: 			float = 0.0
var skip_move_animation:	bool = false

# auction ui stuff
@onready var auction_ui:			Node2D = get_node("%AuctionUI")
@onready var auction_prop:			Label = get_node("%AuctionUI/PropertyTitle")
@onready var auction_start_price:	Label = get_node("%AuctionUI/StartPrice")
@onready var auction_high_bid:		Label = get_node("%AuctionUI/HighBid")
@onready var auction_bidders:		Label = get_node("%AuctionUI/HighBidders")


var single_taxing:			bool = false
var public_treasury:		int = 0
var current_laps:			int = 0
var chance_deck:			ChanceDeck = null
var luxury_deck:			LuxuryDeck = null
var square_going_to:		Square = null
var square_came_from:		Square = null
var current_player_money:	Label = null

# bidding
var bidders: 				Array[Player]
var bidder_index:			int = 0
var top_bid:				int = 0
var min_bid_increment:		int = 50
var top_bidders:			Array[Player] = []
var bid_button:				Label = null
var bid_timer:				float = 0.0
@onready var noncurrent_bid_input:	LineEdit = get_node("%NonCurrentBidInput")
@onready var bid_input:		LineEdit = get_node("%BidInput")
@onready var bid_clock:		Label = get_node("%BidClock")

# adjustable game settings
var start_money: 			int = 1
var labor_on_mother_earth: 	int = 1
var time_per_turn: 			float = 100.0
var time_per_bid: 			float = 100.0

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
	start_money = 400
	match (players.size()):
		2: start_money = 600
		3: start_money = 500
	labor_on_mother_earth 	= Landlord.LABOR_ON_MOTHER_EARTH
	time_per_turn 			= Landlord.TIME_PER_TURN
	time_per_bid 			= Landlord.TIME_PER_BID

func init_board(new_id : int, new_lord : Landlord, new_host : User) -> void:
	reset_settings()
	
	game_ui.visible = false
	auction_ui.visible = false
	
	id = new_id
	lord = new_lord
	host = new_host 
	chance_deck = lord.ChanceDeckClass.new()
	luxury_deck = lord.LuxuryDeckClass.new()
		
	start_butt.pressed.connect(start_game)
	
	var add_ai_button: Button = get_node("%AddAI")
	add_ai_button.pressed.connect(add_ai)
	var temp_skip_button: Button = get_node("%Skip")
	temp_skip_button.pressed.connect(skip_input)
	var stand_up_button: Button = get_node("%StandUp")
	stand_up_button.pressed.connect(stand_up)
	
	roll_butt.pressed.connect(roll_dice)
	bid_butt.pressed.connect(bid_submitted)
	pass_bid_butt.pressed.connect(pass_bid_pressed)
	build_house_butt.pressed.connect(build_house)
	trade_butt.pressed.connect(start_trade)
	end_turn_butt.pressed.connect(end_turn)
	
	current_player_money = get_node("%MoneyLabel")
	assert(current_player_money)
	
	var noncurrent_bid_butt = noncurrent_ui.get_node("Bid2") as Button
	noncurrent_bid_butt.pressed.connect(noncurrent_local_player_pressed_bid)
	var noncurrent_pass_bid_butt = noncurrent_ui.get_node("Pass2")
	noncurrent_pass_bid_butt.pressed.connect(pass_bid) # i think ok
	
	# start with Mother Earth (GO) in bot right and go clockwise
	make_square(Square.Type.Go, "MOTHER EARTH", 0, 0)
	make_square(Square.Type.Property, "WAYBACK", 25, 0)
	make_square(Square.Type.Taxes, "FUEL", 10, 0)
	make_square(Square.Type.Property, "LONELY LANE", 25, 2)
	make_square(Square.Type.GamePreserves, "GAME PRESERVES", 0, 0)
	make_square(Square.Type.Railroad, "ROYAL RUSHER R.R.", 50, 5)
	make_square(Square.Type.Property, "THE PIKE", 25, 4)
	make_square(Square.Type.Property, "THE FARM", 25, 4)
	make_square(Square.Type.Speculation, "SPECULATION", 50, 10)
	make_square(Square.Type.Property, "RUBEVILLE", 25, 6)
	
	# next side
	make_square(Square.Type.JailShelter, "JAIL", 10, 0)
	make_square(Square.Type.Property, "BOOMTOWN", 50, 6)
	make_square(Square.Type.Property, "GOAT ALLEY", 50, 8)
	make_square(Square.Type.Utility, "SOAKUM LIGHTING SYSTEM", 50, 5)
	make_square(Square.Type.Property, "BEGGARMAN'S COURT", 50, 8)
	make_square(Square.Type.Railroad, "SHOOTING STAR R.R.", 50, 5)
	make_square(Square.Type.Property, "RICKETY ROW", 50, 10)
	make_square(Square.Type.Taxes, "FOOD", 10, 0)
	make_square(Square.Type.Property, "MARKET PLACE", 50, 10)
	make_square(Square.Type.Property, "COTTAGE TERRACE", 50, 12)
	
	#next side
	make_square(Square.Type.PoorhouseCentralPark, "POORHOUSE", 0, 0)
	make_square(Square.Type.Property, "EASY STREET", 75, 12)
	make_square(Square.Type.Chance, "CHANCE", 0, 0)
	make_square(Square.Type.Property, "GEORGE STREET", 75, 14)
	make_square(Square.Type.Property, "MAGUIRE FLATS", 75, 14)
	make_square(Square.Type.Railroad, "GEE WHIZ R.R.", 50, 5)
	make_square(Square.Type.Property, "FAIRHOPE AVENUE", 75, 16)
	make_square(Square.Type.Utility, "SLAMBANG TROLLEY", 50, 5)
	make_square(Square.Type.Property, "JOHNSON CIRCLE", 75, 16)
	make_square(Square.Type.Property, "THE BOWERY", 75, 18)
	
	#next side
	make_square(Square.Type.BluebloodsEstate, "BLUEBLOOD", 0, 0)
	make_square(Square.Type.Property, "BROADWAY", 100, 18)
	make_square(Square.Type.Taxes, "CLOTHING", 10, 0)
	make_square(Square.Type.Property, "MADISON SQUARE", 100, 20)
	make_square(Square.Type.Property, "FIFTH AVENUE", 100, 20)
	make_square(Square.Type.Railroad, "P.D.Q. R.R.", 50, 5)
	make_square(Square.Type.Property, "GRAND BOULEVARD", 100, 22)
	make_square(Square.Type.Chance, "CHANCE", 0, 0)
	make_square(Square.Type.Property, "WALL STREET", 100, 22)
	make_square(Square.Type.Luxury, "LUXURY", 75, 0)
	
	# TODO could probably load the last settings this user used
	
# landlord's game has Go in bot right
func make_square(type: Square.Type, title: String, sale_price: int, land_rent: int) -> void:
	var square_count = squares.size()
	var square: Square = null
	var is_corner = false
	var square_rotation: float
	var square_width = 43
	var half_corner = 32
	var corner_width = 64
	var pos = Vector2(0, 0)
	var bot_right = Vector2(850, 570)
	var bot_left = bot_right + Vector2(-10 * square_width - corner_width, 0)
	var top_left = bot_left + Vector2(0, -10 * square_width - corner_width)
	var top_right = top_left + Vector2(10 * square_width + corner_width, 0)
	if square_count == 0: # MOTHER EARTH
		is_corner = true
		pos = bot_right
	elif square_count < 10:
		pos = bot_right + Vector2(-square_count * square_width - half_corner, 0)
	elif square_count == 10: # JAIL
		is_corner = true
		pos = bot_left
	elif square_count < 20:
		square_rotation = PI / 2.0
		pos = bot_left + Vector2(0, -square_width * (square_count - 10) - half_corner)	
	elif square_count == 20: # POORHOUSE/CENTRAL PARK FREE
		is_corner = true
		pos = top_left
	elif square_count < 30:
		square_rotation = PI
		pos = top_left + Vector2(square_width * (square_count - 20) + half_corner, 0)
	elif square_count == 30: # BLUEBLOODS
		is_corner = true
		pos = top_right
	elif square_count < 40:
		square_rotation = 3.0 * PI / 2.0
		pos = top_right + Vector2(0, square_width * (square_count - 30) + half_corner)
	else:
		push_warning("how many squares we making!?")
	
	if is_corner:
		square = lord.CornerSquareScene.instantiate() as Square
	else:
		square = lord.NormalSquareScene.instantiate() as Square
	square.define(square_count, type, title, sale_price, land_rent)
	$Squares.add_child(square)
	print("pos: %s" % str(pos))
	print("rotation: %d" % square_rotation)
	square.position = pos
	square.rotation = square_rotation
	squares.append(square)
	
	
func start_game() -> void:
	if game_started:
		if paused:
			start_butt.text = "PAUSE"
			paused = false
			game_ui.visible = true
		else:
			start_butt.text = "RESUME"
			paused = true
			game_ui.visible = false
		return
		
	start_butt.text = "PAUSE"
	game_started = true
	paused = false
	game_ui.visible = true
	if players.size() == 0:
		print("can't play with no players!")
		return
	for p in players:
		p.money = start_money
	#players.shuffle() only uncomment if we're willing to redraw ai
	print("Go forth and labor upon Mother Earth!")
	current_player_index = -1
	next_turn()
	
func player_left(_p: Player) -> void:
	# do we just mark player as having left and then on their turn they quit?
	pass

func stand_up() -> void:
	game_ui.visible = false
	$BoardMenu.visible = false
	lord.view_listings()
	
func sit() -> void:
	visible = true
	if game_started:
		game_ui.visible = true
	$BoardMenu.visible = true

func _process(delta: float) -> void:
	mode_lab.text = str(Mode.keys()[mode]) # DEBUG
	if game_started:
		if not paused:
			simulate_game(delta)
			
func simulate_game(delta: float) -> void:
	match mode:
		Mode.Moving:
			var keep_going = true
			while keep_going:
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
						skip_move_animation = false
						place_player_token(current_player, square_going_to)
						process_square(current_player, square_came_from, square_going_to)
						current_laps = 0
				keep_going = skip_move_animation
				
				
		Mode.Rolling:
			turn_timer -= delta
			turn_clock.text = str(floor(turn_timer))
			if turn_timer < 0:
				end_turn()
			if current_player.is_ai and turn_timer < time_per_turn - 1:
				roll_dice()
		Mode.PayingDebts:
			turn_timer -= delta
			turn_clock.text = str(floor(turn_timer))
			if turn_timer < 0:
				end_turn()
		Mode.Bidding:
			var bidder = bidders[bidder_index]
			# only local
			if bidder.user == current_player.user:
				bid_timer -= delta
				bid_clock.text = str(floor(bid_timer))
				if bid_timer <= 0:
					pass_bid_pressed()
				
		Mode.WaitingForEndTurn:
			# player could build a house now or something
			turn_timer -= delta
			turn_clock.text = str(floor(turn_timer))
			if turn_timer < 0 or current_player.is_ai:
				end_turn()

func skip_input() -> void:
	if mode == Mode.Bidding:
		bidders = top_bidders
		next_bidder();
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
	
func redraw_player_labels() -> void:
	var y_offset = 10.0 
	for lab in player_labels:
		y_offset += player_label_spacing
		lab.position = Vector2(get_viewport().size.x - 200.0, y_offset)
	
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
	current_player_index = (current_player_index + 1) % players.size()
	current_player = players[current_player_index]
	if current_player.left_game:
		players.remove_at(current_player_index)
		current_player_index -= 1
		redraw_player_labels()
		# check for any local players
		var stay_on_board = false
		for p in players:
			if p.user.local:
				stay_on_board = true
		if stay_on_board:
			next_turn()
		elif current_player.user.local: 
			current_player.user.board = null
			
	else:
		current_player_label.text = current_player.nickname
		update_money(current_player)
		roll_butt.disabled = false
		roll_butt.text = "ROLL"
		bid_butt.disabled = true
		pass_bid_butt.disabled = true
		end_turn_butt.disabled = true
		turn_timer = time_per_turn
		mode = Mode.Rolling
		print("now it's %s's turn!" % current_player.nickname)

func update_money(p: Player) -> void:
	if p == current_player:
		current_player_money.text = "MONEY: $%s" % str(current_player.money)
	else:
		#TODO
		pass

func roll_dice() -> void:
	if paused or not game_started:
		pass
	elif mode == Mode.Rolling:
		process_roll(current_player, randi_range(1, 6), randi_range(1, 6))
	elif mode == Mode.Moving:
		print("skip_move_animation set true")
		skip_move_animation = true
	else:
		print("what mode is it? maybe should disable ROLL button")

func process_roll(p : Player, die0 : int, die1 : int) -> void:
	print("%s rolled %d(%d+%d)" % [p.nickname, (die0 + die1), die0, die1])
	if die0 == die1:
		if p.in_jail:
			p.in_jail = false
			#TODO
		else:
			#TODO
			pass
			
	roll_butt.text = "SKIP"
	var total_roll = die0 + die1
	var square_index = p.square.num + total_roll
	if square_index >= squares.size():
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
	print("%s labored on Mother Earth. Cash holdings: $%d(+$%d)" % [
			current_player.nickname, 
			current_player.money, 
			labor_on_mother_earth])
	current_player.money += labor_on_mother_earth
	update_money(current_player)
	
func charge_rent(tenant: Player, square: Square) -> void:
	# TODO #SINGLETAX
	var rent = 10
	match square.type:
		Square.Type.Property:
			rent = square.land_rent + square.houses * lord.HOUSE_RENT
		Square.Type.Utility:
			rent = 5
			if square.lord:
				var utilities_owned = square.lord.properties.filter(func(sqr): return sqr.type == Square.Type.Utility)
				# a "municipal cinch"!
				if utilities_owned.size() == 2:
					rent = 25
		Square.Type.Railroad:
			rent = 5
			if square.lord:
				var rrs_owned = square.lord.properties.filter(func(sqr): return sqr.type == Square.Type.Utility).size()
				match rrs_owned:
					2: rent = 10
					3: rent = 20
					4: rent = 50
					_: push_warning("how do you own %d rrs?" % rrs_owned)
		_:  push_warning("unhandled square is charging rent?: %s" % square.nickname)
	
	if tenant.money >= rent:
		tenant.money -= rent
		update_money(tenant)
		if square.lord:
			update_money(square.lord)
			square.lord.money += rent
			print(tenant.nickname + " paid rent $%d(-$%d) to %s" % [tenant.money, rent, square.lord.nickname])
		else:
			public_treasury += rent
			print(tenant.nickname + " paid rent $%d(-$%d) to public treasury" % [tenant.money, rent])
		mode = Mode.WaitingForEndTurn
	else:
		if tenant.is_ai:
			pass
			# TODO bankruptcy!
			# offer selling of goods or something?
		
func start_auction(for_sale : Square) -> void:
	print("start bidding for %s" % for_sale.title)
	bidders = players.duplicate(true)
	bidder_index = bidders.find(current_player) - 1
	top_bid = for_sale.sale_price
	top_bidders = []
	bid_butt.disabled = false
	pass_bid_butt.disabled = false
	auction_ui.visible = true
	auction_prop.text = "Property: " + for_sale.title
	auction_start_price.text = "Start Price: " + str(for_sale.sale_price)
	auction_high_bid.text = "High Bid: --"
	auction_bidders.text = "High Bidders: --"
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
		# TODO auction with no winner?
		# paid into PUBLIC TREASURY (maybe this does nothing until LVT?)
		pass
	else:
		winner = top_bidders[0]
		
	if winner:
		winner.properties.append(property)
		property.lord = winner
		print("%s won auction with bid $%s, new lord of %s." % [
			current_player.nickname,
			str(top_bid),
			current_player.square.title
		])	
		winner.money -= top_bid
		update_money(winner)
		if winner != current_player:
			charge_rent(current_player, property)
			
	bid_butt.disabled = true
	pass_bid_butt.disabled = true
	bid_clock.text = ""
	auction_ui.visible = false
	mode = Mode.WaitingForEndTurn
	end_turn_butt.disabled = false
	bidders = []
	top_bidders = []
	
func pass_bid() -> void:
	print(bidders[bidder_index].nickname + " passes")
	bidders.remove_at(bidder_index)
	print(str(bidders.size()) + " bidders.size")
	bidder_index -= 1
	# how do i handle calling? is that allowed? i forget the rules
	# but i thought it said something like
	# if everyone bids the same amount, the current player gets it
	# but if two non current player bid the same amount, what then?
	# what about using vickrey auctions?
	if bidders.size() == top_bidders.size():
		conclude_auction()
	else:
		next_bidder()

func bid_submitted() -> void:
	if current_player == bidders[bidder_index]:
		if bid_input.text.is_valid_int(): 
			var amount = int(bid_input.text)
			if amount >= top_bid:
				bid(current_player, amount)
		else:
			push_warning("invalid bid amount: " + bid_input.text)
	else:
		print("not your turn!")

func noncurrent_local_player_pressed_bid() -> void:
	var bidder: Player = bidders[bidder_index]
	if noncurrent_bid_input.text.is_valid_int(): 
		var amount = int(noncurrent_bid_input.text)
		if amount >= top_bid and amount <= bidder.money:
			bid(bidder, amount)
		else:
			print("not enough or not high enough $")
	else:
		push_warning("invalid bid amount: " + noncurrent_bid_input.text)
		
func bid(p: Player, amount: int) -> void:
	if amount < top_bid:
		print("bid is less than top bid")
	elif amount == top_bid and top_bidders.size() > 0:
		print("how do we handle equal top bids? i forget")
	else:
		top_bid = amount
		top_bidders = [p]
		auction_high_bid.text = "High Bid: " + str(top_bid)
		auction_bidders.text = "High Bidder: " + p.nickname 
		print("%s bid $%d" % [p.nickname, amount])
		next_bidder();
		
		
func next_bidder() -> void:
	if bidders.size() == top_bidders.size():
		conclude_auction()	
	else:
		bidder_index = (bidder_index + 1) % bidders.size()
		noncurrent_ui.visible = false
		var bidder: Player = bidders[bidder_index] 
		if bidder.is_ai:
			print("next bidder is ai: " + bidder.nickname)
			if bidder.money > top_bid + min_bid_increment:
				# let's say 50/50 they bid
				var roll = randf()
				print("ai rolled: " + str(roll))
				if roll > .5:
					bid(bidder, top_bid + min_bid_increment)
				else:
					pass_bid()
		elif bidder == current_player:
			print("next bidder is current_player: " + bidder.nickname)
			bid_butt.disabled = false
			pass_bid_butt.disabled = false
		elif bidder.user == current_player.user:
			print("next bidder is local player: " + bidder.nickname)
			noncurrent_ui.visible = true
			bid_butt.disabled = true
			pass_bid_butt.disabled = true
		else:
			print("next bidder is network player:" + bidder.nickname)
			pass
			
		bid_timer = time_per_bid
		bid_clock.text = str(floor(bid_timer))
	
func process_square(p : Player, _came_from : Square, landed_on : Square) -> void:
	roll_butt.disabled = true
	roll_butt.text = "ROLL"
	p.square = landed_on
	print("%s is now on square_%d: %s" % [p.nickname, landed_on.num, landed_on.title])
	
	# track this, in case they unpass Go (see rules)
	var retreated = false
	
	mode = Mode.WaitingForEndTurn
	match landed_on.type:
		Square.Type.Property:
			if landed_on.lord == null:
				mode = Mode.Bidding
				start_auction(landed_on)
			elif landed_on.lord == current_player:
				print("nothing happens, since %s owns %s" % [current_player.nickname, landed_on.title])
			else:
				mode = Mode.PayingDebts
				charge_rent(current_player, landed_on)
		
		Square.Type.Utility:
			if landed_on.lord == null:
				mode = Mode.Bidding
				start_auction(landed_on)
			elif landed_on.lord == current_player:
				print("nothing happens, since %s owns %s" % [current_player.nickname, landed_on.title])
			else:
				mode = Mode.PayingDebts
				charge_rent(current_player, landed_on)
				
		Square.Type.Railroad:
			if landed_on.lord == null:
				mode = Mode.Bidding
				start_auction(landed_on)
			elif landed_on.lord == current_player:
				print("nothing happens, since %s owns %s" % [current_player.nickname, landed_on.title])
			else:
				mode = Mode.PayingDebts
				charge_rent(current_player, landed_on)
				
		Square.Type.Undefined:
			push_warning("undefined square!")
			pass
			
	if mode == Mode.WaitingForEndTurn:
		end_turn_butt.disabled = false
		
	for i in current_laps:
		if not retreated:
			pass_go()
			
func pass_bid_pressed() -> void:
	pass_bid() # pass bid just passes for player at bidder_index, hm
	
func build_house() -> void:
	# need to specify location
	# then just check for $ and num of houses already built
	# SINGLETAX in play, then build anywhere i think
	pass
	
func start_trade() -> void:
	# prompt for $ and properties and target player
	# trading ui? any time? retract offer? network timing issues
	pass
			
func end_turn() -> void:
	# TODO close dialog windows or whatever
	# windows that could be open: other bids, building, trading, reading card?
	next_turn()
