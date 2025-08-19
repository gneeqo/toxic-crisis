extends Node

#key:String, 
var all_lists:Dictionary
var tags:Dictionary
#register list to a name in this dictionary
#run all lists in this dictionary, but check if TAG is blocked
#register actions to a specific list
#tag lists when created
#block tags from this script

func run_lists()->void:
    for list:ActionList in all_lists.values():
        var list_blocked:bool = false
        #check tags for blocked lists
        for tag:String in list.tags:
            if tags[tag] == false:
                list_blocked = true
                break
        if list_blocked:
            break
        list.run_actions()

func register_list(key:String,list:ActionList)->void:
    all_lists.set(key,list)
    #check tags on list and add to tags
    for tag in list.tags:
        if not tag in tags:
            tags.set(tag,true) 

func remove_list(key:String)->void:
    all_lists.erase(key)

#tag setting functions
func edit_tag(tag:String, value:bool)->void:
    tags[tag] = value

func toggle_tag(tag:String)->void:
    tags[tag] = !tags[tag]

func enable_tag(tag:String)->void:
    edit_tag(tag,true)

func disable_tag(tag:String)->void:
    edit_tag(tag,false)


func add_to_list(list_name:String,action:Action)->void:
    if list_name in all_lists:
        all_lists[list_name].add_action(action)
    else:
        push_error("list " + list_name + " is not registered.")


func on_list_complete(list_name:String) ->Signal:
    return all_lists[list_name].list_completed     
