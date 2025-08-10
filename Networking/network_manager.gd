extends Node

var steam_enabled = true
var is_online: bool = false


const PACKET_READ_LIMIT: int = 32

var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 2
var lobby_vote_kick: bool = false
var steam_id: int = 0
var steam_username: String = ""

var send_channel: int = 0
var handshake_valid:bool = false

signal lobby_joined

func _init() -> void:
    OS.set_environment("SteamAppId", str(3945870))
    OS.set_environment("SteamGameId", str(3945870))
    initialize_steam()


   


func initialize_steam() -> void:
    var initialize_response: Dictionary = Steam.steamInitEx()
    print("Did Steam initialize?: %s " % initialize_response)
    if initialize_response['status'] > Steam.STEAM_API_INIT_RESULT_OK:
        print("Failed to initialize Steam, shutting down: %s" % initialize_response)
        # Show some kind of prompt so the game doesn't suddently stop working
        #show_warning_prompt()
        steam_enabled = false
        get_tree().quit()

func _process(_delta: float) -> void:
    Steam.run_callbacks()
    # If the player is connected, read packets
    if lobby_id > 0:
        read_messages()

func _ready() -> void:
    Steam.join_requested.connect(_on_lobby_join_requested)
    Steam.lobby_created.connect(_on_lobby_created)
    Steam.lobby_invite.connect(join_lobby)
    Steam.lobby_joined.connect(_on_lobby_joined)
    Steam.lobby_match_list.connect(_on_lobby_match_list)
    Steam.persona_state_change.connect(_on_persona_change)
    steam_id = Steam.getSteamID()
    steam_username = Steam.getPersonaName()
    is_online = Steam.loggedOn()
    
    Steam.network_messages_session_request.connect(_on_network_messages_session_request)
    Steam.network_messages_session_failed.connect(_on_network_messages_session_failed)
    # Check for command line arguments
    check_command_line()
    
    
func _on_network_messages_session_request(remote_id: int) -> void:
    # Get the requester's name
    var this_requester: String = Steam.getFriendPersonaName(remote_id)
    print("%s is requesting a P2P session" % this_requester)

    # Accept the P2P session; can apply logic to deny this request if needed
    Steam.acceptSessionWithUser(remote_id)

    # Make the initial handshake
    make_p2p_handshake()
    
func read_messages() -> void:
    # The maximum number of messages you want to read per call
    var max_messages: int = 10
    var messages: Array = Steam.receiveMessagesOnChannel(send_channel, max_messages)

    # There is a packet
    for message in messages:
        if message.is_empty() or message == null:
            print("WARNING: read an empty message with non-zero size!")
        else:
            message.payload = bytes_to_var(message.payload)
            # Get the remote user's ID
            var message_sender: int = message.identity

            # Print the packet to output
            print("Message Payload: %s" % message.payload)
            
            if(message.payload["message"] == "handshake"):
                handshake_valid = true
            
            # Append logic here to deal with message data.
            message.release
    
    
func send_message(this_target: int, packet_data: Dictionary) -> void:
            # Set the send_type and channel
    var send_type: int = Steam.NETWORKING_SEND_RELIABLE_NO_NAGLE
    

    # Create a data array to send the data through
    var this_data: PackedByteArray
    this_data.append_array(var_to_bytes(packet_data))

    # If sending a packet to everyone
    if this_target == 0:
        # If there is more than one user, send packets
        if lobby_members.size() > 1:
            # Loop through all members that aren't you
            for this_member in lobby_members:
                if this_member['steam_id'] != steam_id:
                    Steam.sendMessageToUser(this_member['steam_id'], this_data, send_type, send_channel)

    # Else send it to someone specific
    else:
        Steam.sendMessageToUser(this_target, this_data, send_type, send_channel)
        

func check_command_line() -> void:
    var these_arguments: Array = OS.get_cmdline_args()

    # There are arguments to process
    if these_arguments.size() > 0:

        # A Steam connection argument exists
        if these_arguments[0] == "+connect_lobby":

            # Lobby invite exists so try to connect to it
            if int(these_arguments[1]) > 0:

                # At this point, you'll probably want to change scenes
                # Something like a loading into lobby screen
                print("Command line lobby ID: %s" % these_arguments[1])
                join_lobby(int(these_arguments[1]))
                

func create_lobby() -> void:
    # Make sure a lobby is not already set
    if lobby_id == 0:
        Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, lobby_members_max)
        
        
func _on_lobby_created(connect: int, this_lobby_id: int) -> void:
    if connect == 1:
        # Set the lobby ID
        lobby_id = this_lobby_id
        print("Created a lobby: %s" % lobby_id)

        # Set this lobby as joinable, just in case, though this should be done by default
        Steam.setLobbyJoinable(lobby_id, true)

        # Set some lobby data
        Steam.setLobbyData(lobby_id, "name", "Gramps' Lobby")
        Steam.setLobbyData(lobby_id, "mode", "GodotSteam test")

        # Allow P2P connections to fallback to being relayed through Steam if needed
        var set_relay: bool = Steam.allowP2PPacketRelay(true)
        print("Allowing Steam to be relay backup: %s" % set_relay)
        
       #TODO change this 
func _on_lobby_match_list(these_lobbies: Array) -> void:
    for this_lobby in these_lobbies:
        # Pull lobby data from Steam, these are specific to our example
        var lobby_name: String = Steam.getLobbyData(this_lobby, "name")
        var lobby_mode: String = Steam.getLobbyData(this_lobby, "mode")

        # Get the current number of members
        var lobby_num_members: int = Steam.getNumLobbyMembers(this_lobby)

        # Create a button for the lobby
        var lobby_button: Button = Button.new()
        lobby_button.set_text("Lobby %s: %s [%s] - %s Player(s)" % [this_lobby, lobby_name, lobby_mode, lobby_num_members])
        lobby_button.set_size(Vector2(800, 50))
        lobby_button.set_name("lobby_%s" % this_lobby)
        lobby_button.connect("pressed", Callable(self, "join_lobby").bind(this_lobby))

        # Add the new lobby to the list
        $Lobbies/Scroll/List.add_child(lobby_button)
        
        
        
func join_lobby(this_lobby_id: int) -> void:
    print("Attempting to join lobby %s" % lobby_id)

    # Clear any previous lobby members lists, if you were in a previous lobby
    lobby_members.clear()

    # Make the lobby join request to Steam
    Steam.joinLobby(this_lobby_id)
    
    
func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
    # If joining was successful
    if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
        # Set this lobby ID as your lobby ID
        lobby_id = this_lobby_id

        # Get the lobby members
        get_lobby_members()

        # Make the initial handshake
        make_p2p_handshake()
        
        lobby_joined.emit()
        
    # Else it failed for some reason
    else:
        # Get the failure reason
        var fail_reason: String

        match response:
            Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: fail_reason = "This lobby no longer exists."
            Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: fail_reason = "You don't have permission to join this lobby."
            Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: fail_reason = "The lobby is now full."
            Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: fail_reason = "Uh... something unexpected happened!"
            Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: fail_reason = "You are banned from this lobby."
            Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: fail_reason = "You cannot join due to having a limited account."
            Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: fail_reason = "This lobby is locked or disabled."
            Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: fail_reason = "This lobby is community locked."
            Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: fail_reason = "A user in the lobby has blocked you from joining."
            Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: fail_reason = "A user you have blocked is in the lobby."

        print("Failed to join this chat room: %s" % fail_reason)

        #Reopen the lobby list
        #_on_open_lobby_list_pressed()
        
        
func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
    # Get the lobby owner's name
    var owner_name: String = Steam.getFriendPersonaName(friend_id)

    print("Joining %s's lobby..." % owner_name)

    # Attempt to join the lobby
    join_lobby(this_lobby_id)
    
    
func get_lobby_members() -> void:
    # Clear your previous lobby list
    lobby_members.clear()

    # Get the number of members from this lobby from Steam
    var num_of_members: int = Steam.getNumLobbyMembers(lobby_id)

    # Get the data of these players from Steam
    for this_member in range(0, num_of_members):
        # Get the member's Steam ID
        var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)

        # Get the member's Steam name
        var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)

        # Add them to the list
        lobby_members.append({"steam_id":member_steam_id, "steam_name":member_steam_name})
        
        
# A user's information has changed
func _on_persona_change(this_steam_id: int, _flag: int) -> void:
    # Make sure you're in a lobby and this user is valid or Steam might spam your console log
    if lobby_id > 0:
        print("A user (%s) had information change, update the lobby list" % this_steam_id)

        # Update the player list
        get_lobby_members()
        
func make_p2p_handshake() -> void:
    print("Sending P2P handshake to the lobby")
    send_message(0, {"message": "handshake", "from": steam_id})
    
    
 
func leave_lobby() -> void:
    # If in a lobby, leave it
    if lobby_id != 0:
        # Send leave request to Steam
        Steam.leaveLobby(lobby_id)

        # Wipe the Steam lobby ID then display the default lobby ID and player list title
        lobby_id = 0

        # Close session with all users
        for this_member in lobby_members:
            # Make sure this isn't your Steam ID
            if this_member['steam_id'] != steam_id:

                # Close the P2P session using the Networking class
                Steam.closeP2PSessionWithUser(this_member['steam_id'])

        # Clear the local lobby list
        lobby_members.clear()
        handshake_valid = false


func _on_network_messages_session_failed(steam_id: int, session_error: int, state: int, debug_msg: String) -> void:
    print(debug_msg)
