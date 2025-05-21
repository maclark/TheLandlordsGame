class_name ChanceDeck

var deck: Array[int] = []
var deck_index: int = 0

func _init() -> void:
	for i in range(0, 16):
		deck.append(i)
	deck.shuffle()
	deck_index = 0

func draw_card(index: int, _board: GameBoard) -> void:
	# note: placing card at bottom of deck, not shuffling it in
	# TODO implement functionality duh
	index = (index + 1) % deck.size()
	match index:
		0:
			print("go ahead 3 spaces")
		1:
			print("take a free turn")
		2: 
			print("go to Mother Earth (collect wages)")
		3: 
			print("go to jail")
		4:
			print("go to wall st")
		5:
			print("pay $100 taxes")
		6: 
			print("collect $75 from lawsuit")
		7:
			print("miss a turn")
		8:
			print("go to mother earth (colelct $100 wages)") # duplicate, mismatched subtitle tho
		9: 
			print("collect $100 tax refund")
		10: 
			print("collect $25 from each player")
		11:
			print("get ouf of jail (return card to deck after use)")
		12: 
			print("collect $50 from sale of stock")
		13:
			print("pay $50 stock loss")
		14:
			print("pay $25 to each player")
		15:
			print("pay $75 lawyer's fees")
		_:
			push_warning("oob card index: %d" % index)
