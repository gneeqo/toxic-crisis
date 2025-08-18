extends Control
@export var LobbyMenu: PackedScene
@export var ServerButtonClass: PackedScene

func _ready() -> void:
    ServerBrowser.lobbies_updated.connect(populate_lobbies)
    NetworkManager.lobby_joined.connect(on_lobby_joined)
    NetworkManager.lobby_hosted.connect(on_lobby_joined)


func _on_host_pressed() -> void:
    NetworkManager.host()
    
    ServerBrowser.add_lobby(NetworkManager.local_id, $VBoxContainer/HBoxContainer/hostName.text)
    

func on_lobby_joined() -> void:
    add_sibling(LobbyMenu.instantiate(),true)
    queue_free()

func _on_join_pressed() -> void:
    NetworkManager.join($VBoxContainer/JoinID.text)
    

func populate_lobbies(lobbies: Array) -> void:
    for lobby: Dictionary in lobbies:
        var server_button: Control = ServerButtonClass.instantiate()
        server_button.lobby_id = lobby["online_id"]
        server_button.lobby_name = lobby["host_name"]
        %Lobby_List.add_child(server_button,true)


func _on_refresh_lobbies_pressed() -> void:
    for child: ServerButton in %Lobby_List.get_children():
        child.queue_free()
    ServerBrowser.request_lobbies()
