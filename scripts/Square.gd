class_name Square
extends Node2D

# going to have to figure out how to track the interior spots

var num = -1
@export var type : Type = Type.Undefined
@export var title : String = "unknown property"
@export var sale_price : int = 100
@export var land_rent : int = 10




var lord : Player = null
var houses : int = 0 # yes, corners won't have houses TODO house object, Array[House]
var publicly_owned : bool = false

enum Type {
	Undefined,
	Go,
	Property,
	Utility,
	Railroad,
	Chance,
	Luxury,
	Taxes, 
	Speculation,
	GamePreserves,
	JailShelter,
	BluebloodsEstate,
	PoorhouseCentralPark, # free parking
}

func define(_num: int, _type: Type, _title: String, _sale_price: int, _land_rent: int) -> void:
	num = _num
	type = _type
	title = _title
	sale_price = _sale_price
	land_rent = _land_rent
	
	var label = $Label
	if label: label.text = title
	
	var sprite = $Sprite2D
	if sprite:
		match type:
			Type.Property:
				sprite.modulate = Color(1, .5, .5, 1)
			Type.Railroad:
				sprite.modulate = Color(.1, .1, .1, 1)
			Type.Utility:
				sprite.modulate = Color(0, 0, 1, 1)
			Type.Chance:
				sprite.modulate = Color(1, 0, 0, 1)
			Type.Luxury:
				sprite.modulate = Color(1, 1, 0, 1)
			Type.Taxes:
				sprite.modulate = Color(0, 1, 0, 1)
