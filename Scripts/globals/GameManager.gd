extends Node

# ============================================================
# PARTY MEMBER
# ============================================================
class PartyMember:

	var character: Node = null
	var character_id: int = -1
	var party_slot: int = -1

	# 0 = AI
	# >0 = multiplayer peer controlling this character
	var controller_peer_id: int = 0

	var is_active: bool = true


	func _init(
		character_node: Node,
		id: int,
		slot: int
	) -> void:

		character = character_node
		character_id = id
		party_slot = slot


	func is_ai_controlled() -> bool:
		return controller_peer_id == 0


	func is_player_controlled() -> bool:
		return controller_peer_id != 0

# =====================================================
# PARTY PLAYER
# ============================================================
class PartyPlayer:

	var peer_id: int = -1

	# The character this human currently controls.
	var controlled_char: PartyMember = null


	func _init(id: int) -> void:
		peer_id = id

# ============================================================
# PARTY
# ============================================================
class Party:

	var party_id: int = -1

	var players: Array[PartyPlayer] = []

	var party_members: Array[PartyMember] = []

# ============================================================
# GLOBAL STATE
# ============================================================
var parties: Array[Party] = []

var camera: Camera3D = null

var next_character_id: int = 1

var local_peer_id: int = 1

var local_party: Party = null


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	if multiplayer.has_multiplayer_peer():
		local_peer_id = multiplayer.get_unique_id()
	else:
		# Local/offline game behaves like host peer 1.
		local_peer_id = 1


# ============================================================
# CAMERA
# ============================================================

func set_camera(camera_node: Camera3D) -> void:
	camera = camera_node


# ============================================================
# PARTY CREATION
# ============================================================

func create_party() -> Party:

	var party := Party.new()

	party.party_id = parties.size()

	parties.append(party)

	return party


func get_or_create_local_party() -> Party:

	if local_party != null:
		return local_party

	local_party = create_party()

	add_player_to_party(
		local_party,
		local_peer_id
	)

	return local_party


func get_party(party_id: int) -> Party:

	for party in parties:

		if party.party_id == party_id:
			return party

	return null


# ============================================================
# PARTY PLAYERS
# ============================================================

func add_player_to_party(
	party: Party,
	peer_id: int
) -> PartyPlayer:

	if party == null:
		return null


	var existing := get_player_from_party(
		party,
		peer_id
	)

	if existing != null:
		return existing


	var player := PartyPlayer.new(peer_id)

	party.players.append(player)

	return player


func remove_player_from_party(
	party: Party,
	peer_id: int
) -> void:

	if party == null:
		return


	var player := get_player_from_party(
		party,
		peer_id
	)

	if player == null:
		return


	if player.controlled_char != null:

		player.controlled_char.controller_peer_id = 0

		_notify_character_control_changed(
			player.controlled_char
		)

		player.controlled_char = null


	party.players.erase(player)


func get_player_from_party(
	party: Party,
	peer_id: int
) -> PartyPlayer:

	if party == null:
		return null


	for player in party.players:

		if player.peer_id == peer_id:
			return player


	return null


# ============================================================
# CHARACTER REGISTRATION
# ============================================================

func add_character_to_party(
	party: Party,
	character: Node
) -> PartyMember:

	if party == null:
		return null

	if character == null:
		return null


	var existing := get_party_member(
		party,
		character
	)

	if existing != null:
		return existing


	var character_id := next_character_id

	next_character_id += 1


	# IMPORTANT:
	#
	# The first character registered in the party
	# gets party slot 0.
	#
	# Our player registration below guarantees that
	# the human player's character is registered first.

	var party_slot := party.party_members.size()


	var member := PartyMember.new(
		character,
		character_id,
		party_slot
	)


	party.party_members.append(member)


	return member


# ============================================================
# REGISTER INITIAL PLAYER CHARACTER
#
# This is the important function for your current setup.
#
# The first player character becomes:
#
# party_members[0]
#
# and is automatically controlled by the local peer.
# ============================================================

func register_initial_player(
	character: Node
) -> PartyMember:

	var party := get_or_create_local_party()

	var member := get_party_member(
		party,
		character
	)

	if member == null:

		# Make absolutely sure the player is first.
		#
		# If there are already characters registered,
		# insert the player at index 0 and repair slots.

		member = PartyMember.new(
			character,
			next_character_id,
			0
		)

		next_character_id += 1

		party.party_members.push_front(member)

		_rebuild_party_slots(party)


	var player := get_player_from_party(
		party,
		local_peer_id
	)

	if player == null:

		player = add_player_to_party(
			party,
			local_peer_id
		)


	# If nobody controls this character, give it
	# to the local player.

	if member.controller_peer_id == 0:

		# Release whatever the local player currently controls.
		if player.controlled_char != null:

			player.controlled_char.controller_peer_id = 0

			_notify_character_control_changed(
				player.controlled_char
			)


		member.controller_peer_id = local_peer_id

		player.controlled_char = member

		_notify_character_control_changed(member)


	return member


# ============================================================
# REGISTER AI CHARACTER
#
# AI characters always start with controller_peer_id = 0.
# ============================================================

func register_ai_character(
	character: Node
) -> PartyMember:

	var party := get_or_create_local_party()

	var member := add_character_to_party(
		party,
		character
	)

	if member != null:
		member.controller_peer_id = 0

	return member


# ============================================================
# REBUILD PARTY SLOT NUMBERS
# ============================================================

func _rebuild_party_slots(party: Party) -> void:

	for i in party.party_members.size():

		party.party_members[i].party_slot = i


# ============================================================
# REMOVE CHARACTER
# ============================================================

func remove_character_from_party(
	party: Party,
	character: Node
) -> void:

	if party == null:
		return


	var member := get_party_member(
		party,
		character
	)

	if member == null:
		return


	if member.controller_peer_id != 0:

		var player := get_player_from_party(
			party,
			member.controller_peer_id
		)

		if player != null:

			if player.controlled_char == member:
				player.controlled_char = null


	party.party_members.erase(member)

	_rebuild_party_slots(party)


# ============================================================
# LOOKUP
# ============================================================

func get_party_member(
	party: Party,
	character: Node
) -> PartyMember:

	if party == null:
		return null


	for member in party.party_members:

		if member.character == character:
			return member


	return null


func get_party_member_by_id(
	party: Party,
	character_id: int
) -> PartyMember:

	if party == null:
		return null


	for member in party.party_members:

		if member.character_id == character_id:
			return member


	return null


# ============================================================
# CONTROL TAKEOVER
# ============================================================

func take_control(
	party: Party,
	player: PartyPlayer,
	target: PartyMember
) -> bool:

	if party == null:
		return false

	if player == null:
		return false

	if target == null:
		return false


	if not party.party_members.has(target):
		return false


	# Someone else currently controls this character.
	if target.controller_peer_id != 0:

		if target.controller_peer_id == player.peer_id:
			return true

		return false


	# Release player's current character.
	if player.controlled_char != null:

		var old_character := player.controlled_char

		old_character.controller_peer_id = 0

		player.controlled_char = null

		_notify_character_control_changed(
			old_character
		)


	# Take control.
	target.controller_peer_id = player.peer_id

	player.controlled_char = target


	_notify_character_control_changed(
		target
	)


	return true


# ============================================================
# RELEASE CONTROL
# ============================================================

func release_control(
	party: Party,
	player: PartyPlayer
) -> bool:

	if party == null:
		return false

	if player == null:
		return false


	if player.controlled_char == null:
		return true


	var member := player.controlled_char

	member.controller_peer_id = 0

	player.controlled_char = null


	_notify_character_control_changed(
		member
	)


	return true


# ============================================================
# GET CONTROLLED CHARACTER
# ============================================================

func get_controlled_character(
	party: Party,
	peer_id: int
) -> PartyMember:

	var player := get_player_from_party(
		party,
		peer_id
	)

	if player == null:
		return null


	return player.controlled_char


func get_local_controlled_character(
	party: Party
) -> PartyMember:

	return get_controlled_character(
		party,
		local_peer_id
	)


# ============================================================
# CONTROL STATE
# ============================================================

func is_character_controlled_by(
	member: PartyMember,
	peer_id: int
) -> bool:

	if member == null:
		return false


	return member.controller_peer_id == peer_id


func is_character_ai_controlled(
	member: PartyMember
) -> bool:

	if member == null:
		return false


	return member.controller_peer_id == 0


# ============================================================
# NOTIFY CHARACTER
# ============================================================

func _notify_character_control_changed(
	member: PartyMember
) -> void:

	if member == null:
		return

	if member.character == null:
		return


	if member.character.has_method(
		"set_controller_peer"
	):

		member.character.set_controller_peer(
			member.controller_peer_id
	)
