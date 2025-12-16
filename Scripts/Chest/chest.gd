extends StaticBody3D

# Sygnał wysyłany do systemu przy próbie otwarcia ekwipunku tego obiektu
signal toggle_inventory(external_inventory_owner)

# Pobiera referencję do panelu UI wyświetlającego zawartość zewnętrznego ekwipunku
@onready var external_inventory: PanelContainer = $"../UI/InventoryInterface/ExternalInventory"

# Przechowuje dane przedmiotów znajdujących się w tym obiekcie (zasób InventoryData)
@export var inventory_data: InventoryData

func player_interact() -> void:
	# Obsługuje interakcję gracza, emitując sygnał żądania otwarcia ekwipunku
	toggle_inventory.emit(self)

func _on_area_3d_body_exited(body: Node3D) -> void:
	# Automatycznie zamyka okno ekwipunku, gdy gracz wyjdzie poza zasięg interakcji (Area3D)
	external_inventory.hide()
