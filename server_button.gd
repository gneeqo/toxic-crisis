class_name ServerButton extends Control

@export var lobby_id:String
@export var lobby_name:String

func _process(_delta: float) -> void:
    $Button.text = lobby_name

func _on_button_pressed() -> void:
    NetworkManager.join(lobby_id)
