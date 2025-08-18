class_name Player extends CharacterBody3D

@export var Camera:Camera3D
@export var movement_multiplier:float
@export var mouse_sens:float
var pitch:float = 0.0
var server_controlled:bool
var relativeMouseMotion:Vector2
var client_controlled:bool

var my_player:bool = false

func _enter_tree() -> void:
    if name == "Player1":
        set_multiplayer_authority(NetworkManager.server_unique_id) 
        if NetworkManager.is_server:
            Camera.make_current()
            my_player = true
    else:
        set_multiplayer_authority(NetworkManager.client_unique_id) 
        if not NetworkManager.is_server:
            Camera.make_current()
            my_player = true
    
    $MultiplayerSynchronizer.root_path = get_path()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
   

func _input(event:InputEvent)->void:
    if event is InputEventMouseMotion:
        if event.relative.is_zero_approx() == false:
            rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
            pitch -= event.relative.y * mouse_sens
            pitch = clamp(pitch,-90,90)
            Camera.rotation_degrees.x = pitch
             
        
        
    
func _physics_process(delta: float) -> void:
    if not is_multiplayer_authority():
        return
    var input_dir:Vector2 = Input.get_vector("strafe_left","strafe_right","forward","backward")
    
    var strafe_direction:Vector3 = transform.basis.x * input_dir.x
    var forward_direction:Vector3 = Camera.global_transform.basis.z * input_dir.y
    
    velocity.x = (strafe_direction.x + forward_direction.x) * movement_multiplier
    velocity.z = (strafe_direction.z + forward_direction.z) * movement_multiplier
    move_and_slide()

    
