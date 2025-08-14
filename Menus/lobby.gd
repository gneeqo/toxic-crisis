extends Control

func _ready() -> void:
    pass

func _process(_delta: float) -> void:
    $BoxContainer/RemotePlayerName.text = NetworkManager.server_id
    $BoxContainer/LocalPlayerName.text = NetworkManager.client_id
