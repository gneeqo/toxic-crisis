extends Control
@export var LobbyMenu:PackedScene

func _on_host_pressed() -> void:
    NetworkManager.create_lobby()
    NetworkManager.connect("lobby_joined",Callable(self,"on_lobby_joined"))
    
    

func on_lobby_joined()->void:
    add_sibling(LobbyMenu.instantiate())
    queue_free()


func _on_join_pressed() -> void:
    pass # Replace with function body.
