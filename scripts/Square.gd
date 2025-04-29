class_name Square
extends Node2D

# going to have to figure out how to track the interior spots

var num = -1
@export var type : Type = Type.Undefined
@export var title : String = "boardwalk"
@export var base_price : int = 100
@export var base_rent : int = 10
@export var house_rent : int = 5

var holder : Player = null
var houses : int = 0 # yes, corners won't have houses
var publicly_owned : bool = false

enum Type {
	Undefined,
	Go,
	Property,
	Utility,
	Railroad,
	Chance,
	CommunityChest, # TODO what were they called?
	Luxuries, 
	Jail,
	BluebloodsEstate,
	CollegeOrFreeLand, # free parking
}

func _ready() -> void:
	match type:
		#Type.Go:
			#modulate = Color(1, 1, 1, 1)
		Type.Property:
			modulate = Color(1, .5, .5, 1)
		Type.Railroad:
			modulate = Color(.1, .1, .1, 1)
		Type.Utility:
			modulate = Color(0, 0, 1, 1)
		Type.Chance:
			modulate = Color(1, 0, 0, 1)
		Type.Luxuries:
			modulate = Color(0, 1, 0, 1)
			
			
