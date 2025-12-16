extends Control

# Dane aktualnie trzymanego w "łapie" przedmiotu oraz referencja do otwartej skrzyni
var grabbed_slot_data: SlotData
var external_inventory_owner

# Referencje do kontenerów UI dla głównego plecaka, slotu przeciągania i poszczególnych slotów wyposażenia
@onready var player_inventory: PanelContainer = $PlayerInventory
@onready var grabbed_slot: PanelContainer = $GrabbedSlot
@onready var equip_inventory_head: PanelContainer = $"Equip inventory Head"
@onready var equip_inventory_torso: PanelContainer = $"Equip inventory Torso"
@onready var equip_inventory_legs: PanelContainer = $"Equip inventory Legs"
@onready var equip_inventory_hands: PanelContainer = $"Equip inventory Hands"
@onready var equip_inventory_feet: PanelContainer = $"Equip inventory Feet"
@onready var equip_inventory_weapon: PanelContainer = $"Equip inventory Weapon"
@onready var equip_inventory_offhand: PanelContainer = $"Equip inventory Offhand"
@onready var equip_inventory_trinket: PanelContainer = $"Equip inventory Trinket"
@onready var equip_inventory_trinket_2: PanelContainer = $"Equip inventory Trinket2"
@onready var equip_inventory_trinket_3: PanelContainer = $"Equip inventory Trinket3"


func _process(_delta: float) -> void:
	# Jeśli trzymamy przedmiot, aktualizuje jego pozycję tak, aby podążał za kursorem myszy
	if grabbed_slot.visible:
		grabbed_slot.global_position = get_global_mouse_position() + Vector2(5, 5)

func set_player_inventory_data(inventory_data: InventoryData) -> void:
	# Podpina sygnały interakcji i inicjuje widok głównego ekwipunku gracza
	inventory_data.inventory_interact.connect(on_inventory_interact)
	player_inventory.set_inventory_data(inventory_data)

# --- Funkcje inicjalizujące poszczególne sloty wyposażenia (podpinanie danych i sygnałów) ---
func set_equip_inventory_head(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	equip_inventory_head.set_inventory_data(inventory_data)
	
func set_equip_inventory_torso(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	equip_inventory_torso.set_inventory_data(inventory_data)
	
func set_equip_inventory_legs(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	equip_inventory_legs.set_inventory_data(inventory_data)
	
func set_equip_inventory_hands(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	equip_inventory_hands.set_inventory_data(inventory_data)
	
func set_equip_inventory_feet(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	equip_inventory_feet.set_inventory_data(inventory_data)
	
func set_equip_inventory_weapon(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	equip_inventory_weapon.set_inventory_data(inventory_data)
	
func set_equip_inventory_offhand(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	equip_inventory_offhand.set_inventory_data(inventory_data)
	
func set_equip_inventory_trinkets(inv1, inv2, inv3):
	# Obsługuje masowe przypisanie danych dla trzech slotów biżuterii
	for inv in [inv1, inv2, inv3]:
		inv.inventory_interact.connect(on_inventory_interact)

		equip_inventory_trinket.set_inventory_data(inv1)
		equip_inventory_trinket_2.set_inventory_data(inv2)
		equip_inventory_trinket_3.set_inventory_data(inv3)


func on_inventory_interact(inventory_data: InventoryData, index: int, button: int) -> void:
	# Centralna logika myszy: LPM (podnoszenie/upuszczanie), PPM (użycie/rozdzielanie stosu)
	match [grabbed_slot_data, button]:
		[null, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.grab_slot_data(index)
		[_, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.drop_slot_data(grabbed_slot_data, index)
		[null, MOUSE_BUTTON_RIGHT]:
			inventory_data.use_slot_data(index)
		[_, MOUSE_BUTTON_RIGHT]:
			grabbed_slot_data = inventory_data.drop_single_slot_data(grabbed_slot_data, index)

	update_grabbed_slot()


func update_grabbed_slot() -> void:
	# Pokazuje lub ukrywa "pływającą" ikonę przedmiotu w zależności od tego, czy coś trzymamy
	if grabbed_slot_data:
		grabbed_slot.show()
		grabbed_slot.set_slot_data(grabbed_slot_data)
	else:
		grabbed_slot.hide()

func set_external_inventory(external_owner) -> void:
	# Otwiera panel zewnętrznego ekwipunku (np. skrzyni), podpina jego sygnały i wyświetla zawartość
	external_inventory_owner = external_owner
	if "inventory_data" in external_owner and external_owner.inventory_data:
		if has_node("ExternalInventory"):
			var external_inventory = $ExternalInventory
			external_inventory.visible = true
			external_owner.inventory_data.inventory_interact.connect(on_inventory_interact)
			external_inventory.set_inventory_data(external_owner.inventory_data)
		else:
			push_warning("ExternalInventory node not found - create it in scene to show chest inventory")

func clear_external_inventory() -> void:
	# Zamyka panel zewnętrznego ekwipunku, odłącza sygnały i czyści referencje do obiektu
	if external_inventory_owner and "inventory_data" in external_inventory_owner and external_inventory_owner.inventory_data:
		if external_inventory_owner.inventory_data.inventory_interact.is_connected(on_inventory_interact):
			external_inventory_owner.inventory_data.inventory_interact.disconnect(on_inventory_interact)

	if has_node("ExternalInventory"):
		$ExternalInventory.visible = false

	external_inventory_owner = null
