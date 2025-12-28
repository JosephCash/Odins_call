extends Node3D

# Referencje do postaci gracza oraz elementów interfejsu
@onready var main_character: CharacterBody3D = $MainCharacter
@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var hot_bar_inventory: PanelContainer = $UI/HotBarInventory
@onready var pause_menu: Control = $UI/PauseMenu 

var is_paused: bool = false

func _ready() -> void:
	# === KLUCZOWA ZMIANA ===
	# Ustawiamy main.gd na "Always", żeby działał nawet gdy gra jest zapauzowana (słuchał Escape)
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	# Ale postać gracza musi się pauzować, więc wymuszamy na niej tryb "Pausable"
	main_character.process_mode = Node.PROCESS_MODE_PAUSABLE
	# =======================

	# Inicjalizacja połączeń
	main_character.toggle_inventory.connect(toggle_inventory_interface)
	
	inventory_interface.set_player_inventory_data(main_character.inventory_data)
	inventory_interface.set_equip_inventory_head(main_character.equip_inventory_head)
	inventory_interface.set_equip_inventory_torso(main_character.equip_inventory_torso)
	inventory_interface.set_equip_inventory_legs(main_character.equip_inventory_legs)
	inventory_interface.set_equip_inventory_hands(main_character.equip_inventory_hands)
	inventory_interface.set_equip_inventory_feet(main_character.equip_inventory_feet)
	inventory_interface.set_equip_inventory_weapon(main_character.equip_inventory_weapon)
	inventory_interface.set_equip_inventory_offhand(main_character.equip_inventory_offhand)
	inventory_interface.set_equip_inventory_trinkets(
		main_character.equip_inventory_trinket1,
		main_character.equip_inventory_trinket2,
		main_character.equip_inventory_trinket3
	)

	hot_bar_inventory.set_inventory_data(main_character.inventory_data)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Konfiguracja menu pauzy
	pause_menu.visible = false 
	if pause_menu.has_signal("resume_game"):
		pause_menu.resume_game.connect(toggle_pause_menu)

	# Zewnętrzne ekwipunki
	for node in get_tree().get_nodes_in_group("external_inventory"):
		if node.has_signal("toggle_inventory"):
			node.toggle_inventory.connect(toggle_inventory_interface)

func _unhandled_input(event: InputEvent) -> void:
	# Dzięki zmianie w _ready, ta funkcja działa teraz nawet na pauzie!
	if event.is_action_pressed("pause"):
		if inventory_interface.visible:
			# Jeśli ekwipunek otwarty -> zamknij go (priorytet)
			toggle_inventory_interface()
		else:
			# Jeśli ekwipunek zamknięty -> przełącz pauzę (włącz/wyłącz)
			toggle_pause_menu()

func toggle_pause_menu() -> void:
	is_paused = !is_paused
	
	if is_paused:
		# WŁĄCZAMY PAUZĘ
		get_tree().paused = true            
		pause_menu.show()                   
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 
		hot_bar_inventory.hide()            
	else:
		# WYŁĄCZAMY PAUZĘ
		pause_menu.hide()
		get_tree().paused = false           
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 
		hot_bar_inventory.show()

func toggle_inventory_interface(external_inventory_owner = null) -> void:
	if is_paused:
		return

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
