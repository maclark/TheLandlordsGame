class_name Square
extends Node2D

# going to have to figure out how to track the interior spots
var num = -1
var type : Type = Type.Undefined

enum Type {
	Undefined,
	Property,
	Utility,
	Chance,
	Corner
}
