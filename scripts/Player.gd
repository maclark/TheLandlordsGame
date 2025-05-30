class_name Player

var user: User = null
var nickname: String = "unnamed"
var is_ai: bool = false # AI players are associated with host user
var square: Square
var token: PlayerToken
var money: int
var properties: Array[Square] = []
var in_jail: bool = false
var left_game: bool = false
var luxuries: Array[String] = []
var get_out_of_jails: int = 0
