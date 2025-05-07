extends Node2D

class_name BoardListing

var id: int = -1
var host: User
var player_count: int = 0

@onready var id_lab: Label = $BoardId
@onready var host_lab: Label = $Host
@onready var player_count_lab: Label = $PlayerCount
@onready var join_butt: Button = $Join
@onready var leave_butt: Button = $Leave

var board: GameBoard = null

func init(new_id: int, new_host: User) -> void:
	print("BOARD_" + str(new_id) + " initialized by host: " + new_host.nickname)
	id = new_id
	host = new_host
	set_player_count(0)
	id_lab.text = "BOARD " + str(id)
	host_lab.text = "Host: " + host.nickname
	# lord connects the join_butt so it can see user i guess
	
func set_player_count(count: int) -> void:
	player_count = count
	player_count_lab.text = "Players: " + str(player_count)
	print("BOARD_" + str(id) + " " + player_count_lab.text)

#func load_board(data: BoardData) -> void:
	#new board
	#new board.data = data
	#hurray!
