class_name MatchManager extends Node3D

@export var player_scene: PackedScene
@export var player_spawn_points: Array[Marker3D]

var player1: Player
var player2: Player
var init:bool = false

func _process(_delta: float) -> void:
    if not init and get_parent() != null:
        init = true
        initialize()

func initialize() -> void:
    player1 = player_scene.instantiate()
    player1.name = "Player1"
    player1.position = player_spawn_points[0].position
    add_child(player1,true)

    player2 = player_scene.instantiate()
    player2.name = "Player2"
    player2.position = player_spawn_points[1].position
    add_child(player2,true)
