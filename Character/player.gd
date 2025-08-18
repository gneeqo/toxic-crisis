class_name Player extends CharacterBody3D


@export var movement_multiplier:float

var server_controlled:bool
var relativeMouseMotion:Vector2
var client_controlled:bool

var my_player:bool = false

func _enter_tree() -> void:
    if name == "Player1":
        set_multiplayer_authority(NetworkManager.server_unique_id) 
        if NetworkManager.is_server:
            $Camera3D.make_current()
            my_player = true
    else:
        set_multiplayer_authority(NetworkManager.client_unique_id) 
        if not NetworkManager.is_server:
            $Camera3D.make_current()
            my_player = true
    
    $MultiplayerSynchronizer.root_path = get_path()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
   

func _input(event:InputEvent)->void:
    if event is InputEventMouseMotion:
        relativeMouseMotion = event.relative
        
        
    
func _process(delta: float) -> void:
    if not is_multiplayer_authority():
        return
    
    transform.basis = transform.basis.rotated(transform.basis.y.normalized(),-relativeMouseMotion.x / 500)
    transform.basis = transform.basis.rotated(transform.basis.x.normalized(),-relativeMouseMotion.y / 500)
    if Input.is_action_pressed("forward"):
        var movement_vector:Vector3 = rotation.normalized()
        velocity -= movement_vector * movement_multiplier
        move_and_slide()

    

    
