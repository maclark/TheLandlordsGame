class_name PlayerToken
extends Node2D

@onready var sprite : Sprite2D = $Sprite2D

func _ready() -> void:
	print("token is ready! sprite: " + sprite.name)
