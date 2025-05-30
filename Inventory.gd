extends Node2D

class_name Inventory

var property_cards: 		Array[Node2D] = []
var luxury_cards: 			Array[Node2D] = []
var goojf_card: 			Node2D = null

@export var hover_speed:	float = 5
const PC_GAP: 	float = 5
const LC_GAP: 	float = 5
const X_PC: 	float = 30
const Y_PC: 	float = 300
const X_LC: 	float = 30
const Y_LC: 	float = 400



func set_player(p: Player) -> void:
	var i = 0
	for pc in property_cards:
		pc.visible = pc.owner == p
		pc.position = Vector2(X_PC + i * PC_GAP, Y_PC)
	i = 0
	for lc in luxury_cards:
		lc.visible = lc.owner == p
		lc.position = Vector2(X_LC + i * LC_GAP, Y_LC)
	goojf_card.visible = goojf_card.owner == p
	


			
			
			
			
			
			
