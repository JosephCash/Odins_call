extends Node3D

# Referencje do postaci gracza oraz elementów interfejsu (głównego ekwipunku i paska skrótów)
@onready var main_character: CharacterBody3D = $MainCharacter
@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var hot_bar_inventory: PanelContainer = $UI/HotBarInventory

func _ready() -> void:
	# Inicjalizuje połączenia sygnałów, przekazuje dane ekwipunku i wyposażenia do UI oraz ukrywa kursor
	main_character.toggle_inventory.connect(toggle_inventory_interface)
	inventory_interface.set_player_inventory_data(main_character.inventory_data)
	inventory_interface.set_equip_inventory_head(main_character.equip_inventory_head)
	inventory_interface.set_equip_inventory_torso(main_character.equip_inventory_torso)
	inventory_interface.set_equip_inventory_legs(main_character.equip_inventory_legs)
	inventory_interface.set_equip_inventory_hands(main_character.equip_inventory_hands)
	inventory_interface.set_equip_inventory_feet(main_character.equip_inventory_feet)
	inventory_interface.set_equip_inventory_weapon(main_character.equip_inventory_weapon)
	inventory_interface.set_equip_inventory_offhand(main_character.equip_inventory_offhand)
	inventory_interface.set_equip_inventory_trinkets(main_character.equip_inventory_trinket1,main_character.equip_inventory_trinket2,main_character.equip_inventory_trinket3)

	hot_bar_inventory.set_inventory_data(main_character.inventory_data)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	for node in get_tree().get_nodes_in_group("external_inventory"):
		if node.has_signal("toggle_inventory"):
			node.toggle_inventory.connect(toggle_inventory_interface)

func toggle_inventory_interface(external_inventory_owner = null) -> void:
	# Przełącza widoczność ekwipunku, zarządza zewnętrznymi kontenerami (skrzynie) i trybem kursora myszy
	inventory_interface.visible = not inventory_interface.visible

	if inventory_interface.visible and external_inventory_owner:
		inventory_interface.set_external_inventory(external_inventory_owner)
	else:
		inventory_interface.clear_external_inventory()

	if inventory_interface.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		hot_bar_inventory.hide()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		hot_bar_inventory.show()
