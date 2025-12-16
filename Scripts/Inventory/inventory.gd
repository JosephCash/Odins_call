extends PanelContainer

# Załadowanie sceny pojedynczego slotu oraz referencja do kontenera siatki (Grid) w UI
const Slot = preload("uid://clw23l0nxsi3s")

@onready var item_grid: GridContainer = $MarginContainer/ItemGrid

func set_inventory_data(inventory_data: InventoryData) -> void:
	# Podpina sygnał odświeżania ekwipunku (jeśli nie jest jeszcze podpięty) i inicjuje wypełnienie siatki
	if not inventory_data.inventory_updated.is_connected(populate_item_grid):
		inventory_data.inventory_updated.connect(populate_item_grid)
	populate_item_grid(inventory_data)

func populate_item_grid(inventory_data: InventoryData) -> void:
	# Usuwa wszystkie istniejące sloty z siatki przed wygenerowaniem nowych (czyszczenie widoku)
	for child in item_grid.get_children():
		child.queue_free()
		
	# Tworzy nowe instancje slotów dla każdego elementu danych, dodaje je do siatki i podpina interakcje
	for slot_data in inventory_data.slot_datas:
		var slot = Slot.instantiate()
		item_grid.add_child(slot)
		
		slot.slot_clicked.connect(inventory_data.on_slot_clicked)
		
		if slot_data:
			slot.set_slot_data(slot_data)
