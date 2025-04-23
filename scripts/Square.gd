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
