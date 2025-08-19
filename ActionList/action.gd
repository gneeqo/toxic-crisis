class_name Action extends Node

var is_started:bool = false
var is_complete:bool = false

var blocking:bool = false
var start_params:Array
var run_params:Array
var end_params:Array

var start_function:Callable
var run_function:Callable
var end_function:Callable
 
signal action_completed

func start_action()->void:
    is_started = true

func run_action()->void:
    if not is_started:
        start_action()
    else:
        pass

func reset()->void:
    is_complete = false
    is_started = false

func end_action()->void:
    is_complete = true
    action_completed.emit()    
