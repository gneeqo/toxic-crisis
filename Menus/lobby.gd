extends Control

@export var match_scene: PackedScene

func _ready() -> void:
    pass

func _process(_delta: float) -> void:
    $BoxContainer/RemotePlayerName.text = NetworkManager.server_id
    $BoxContainer/LocalPlayerName.text = NetworkManager.client_id


func _on_start_button_pressed() -> void:    
    if NetworkManager.is_server and NetworkManager.player_connected:
        start_match.rpc()
    else:
        print("Not enough players to start")

@rpc("call_local","authority")
func start_match() -> void:
    var game: MatchManager = match_scene.instantiate()
    game.name = "Match"
    get_tree().root.add_child(game,true)
    queue_free()
