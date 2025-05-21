class_name LuxuryDeck

var deck: Array[int] = []
var deck_index: int = 0

func _init() -> void:
	for i in range(0, 27):
		deck.append(i)
	deck.shuffle()
	deck_index = 0

func draw_card(index: int) -> void:
	# note: placing card at bottom of deck, not shuffling it in
	index = (index + 1) % deck.size()
	var description = "-"
	match index:
		0: description = "AN AUTOMOBILE"
		1: description = "A SUMMER AT THE SEASHORE"
		2: description = "A LIBRARY"
		3: description = "A BUST OF HENRY GEORGE"
		4: description = "ROAST TURKEY & DRESSING"
		5: description = "A FINE CIGAR"
		6: description = "A PET PANDA"
		7: description = "A TYPE WRITER"
		8: description = "BREAKFAST IN BED"
		9: description = "A PAIR OF SPATS"
		10: description = "A FUR COAT"
		11: description = "A DAY OFF"
		12: description = "A TELESCOPE"
		13: description = "A TELEPHONE"
		14: description = "A MAID"
		15: description = "A PRINTING PRESS"
		16: description = "A VICTROLA"
		17: description = "LA SWELLE HOTEL"
		18: description = "A TUXEDO"
		19: description = "A KISS"
		20: description = "STEAK AT DEMONICO'S"
		21: description = "A VISIT TO THE SOUTH"
		22: description = "A TEDDY BEAR"
		23: description = "HENRICI'S RESTAURANT"
		24: description = "A BASEBALL CLUB"
		25: description = "AN AEROPLANE"
		26: description = "A DIAMOND RING"
		_: 
			push_warning("oob card index: %d" % index)
			description = "unhandled card index: " + str(index)
	print("card drawn: %s, worth $100 at end of game" % description)
