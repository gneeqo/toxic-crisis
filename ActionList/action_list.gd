class_name ActionList extends Node

var tags:Array[String]
var actions:Array[Action]
var destroy_on_complete:bool = true
var list_name:String
var looping:bool = false

#emitted when all actions are finished
signal list_complete
var completed:bool = false
func run_actions()->void:
    if completed:
        return
    var all_complete:bool = true
    for action in actions:
        if not action.is_complete:
            all_complete = false
            action.run_action()
            if action.blocking:
                break
    if all_complete:
        end_list()
        
func end_list()->void:
    completed = true
    list_complete.emit()
    if destroy_on_complete:
        GlobalList.remove_list(list_name)
        for action in actions:
            action.queue_free()
        queue_free()
    else:
        for action in actions:
            action.reset()
        if looping:
            restart()
        
            
func restart()->void:
    completed = false

func add_action(action:Action)->void:
    actions.push_back(action)
