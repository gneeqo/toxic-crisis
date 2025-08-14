extends Node

var peer: NodeTunnelPeer = NodeTunnelPeer.new()

#onlineID of players
var server_id: String = ""
var client_id: String = ""
var local_id: String = ""


#becomes true when player connects
var player_connected: bool = false

#becomes true when player hosts
var is_server: bool = false

signal lobby_joined
signal lobby_hosted

func _ready() -> void:
    
    #use NodeTunnel relay to get online ID
    multiplayer.multiplayer_peer = peer
    peer.connect_to_relay("relay.nodetunnel.io", 9998)
    
    await peer.relay_connected
    local_id = peer.online_id

func host() -> void:
    peer.host()
    await peer.hosting
    #copy host ID to clipboard
    DisplayServer.clipboard_set(local_id)
    #this player hosted, so they are the server
    server_id = local_id
    is_server = true
    lobby_hosted.emit()
    #call on_peer_connected when someone joins
    multiplayer.peer_connected.connect(on_peer_connected)

#join lobby by ID
func join(id: String) -> void:
    peer.join(id)
    await peer.joined
    
    player_connected = true
    
    #this player joined, so they are not the server
    is_server = false
    server_id = id
    client_id = local_id

    lobby_joined.emit()

func on_peer_connected(id: int) -> void:
    client_id = peer._numeric_to_online_id[id]
    player_connected = true
    ServerBrowser.remove_lobby(server_id)
    
