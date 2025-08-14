extends HTTPRequest

var request_in_progress: bool = false
var server_url: String = "https://vwhfvenfogqqzhhxecqh.supabase.co/rest/v1/lobbies?select=*"
var headers: PackedStringArray = ["apikey: sb_publishable_pC0DCSh_2_ciwahPpezNJQ_j4m0XZrH", "Authorization: Bearer sb_publishable_pC0DCSh_2_ciwahPpezNJQ_j4m0XZrH"]
signal lobbies_updated(lobbies: Array)

func _ready() -> void:
    request_completed.connect(_on_request_completed)


#called when server gets back with results
func _on_request_completed(_result: int, response_code: int, _received_headers: PackedStringArray, body: PackedByteArray) -> void:
    if response_code == 200:
        var json: Array = JSON.parse_string(body.get_string_from_utf8())
        print(json)
        lobbies_updated.emit(json)
    else:
        print("No lobbies found")
        lobbies_updated.emit([])
    request_in_progress = false

#request lobbies from server
func request_lobbies() -> void:
    if request_in_progress:
        return
    request_in_progress = true
    
    request(server_url, headers, HTTPClient.METHOD_GET)
    
#send data to server
func send_data(data_to_send: Dictionary) -> void:
    if request_in_progress:
        return
    request_in_progress = true
    var json: String = JSON.stringify(data_to_send)
    var send_headers: PackedStringArray = headers
    send_headers.append("Content-Type: application/json")
    request(server_url, send_headers, HTTPClient.METHOD_POST, json)  

#add lobby to server
func add_lobby(online_id: String, host_name: String) -> void:
    var data_to_send: Dictionary = {
        "online_id": online_id,
        "host_name": host_name,
    }
    send_data(data_to_send)

#remove lobby from server
func remove_lobby(online_id: String) -> void:
    
    var delete_url: String = "https://vwhfvenfogqqzhhxecqh.supabase.co/rest/v1/lobbies?" + "&online_id=eq." + online_id
    var error: int = request(delete_url, headers, HTTPClient.METHOD_DELETE)
    if error != OK:
        push_error("Failed to send DELETE request for lobby: " + online_id)

func _exit_tree() -> void:
    remove_lobby(NetworkManager.local_id)
