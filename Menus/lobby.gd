extends Control

func _ready():
    NetworkManager.get_lobby_members()
    


func _process(dt:float):
    var members = NetworkManager.lobby_members
    if NetworkManager.handshake_valid:
        $BoxContainer/RemotePlayerName.text = NetworkManager.lobby_members[1] 
    else: if not members.is_empty():
        $BoxContainer/LocalPlayerName.text = NetworkManager.lobby_members[0].steam_name
