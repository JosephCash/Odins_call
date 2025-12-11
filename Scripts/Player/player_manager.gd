extends Node

var player

# Domyślne dane wyglądu
var current_appearance_data: Dictionary = {
	"gender": "female",
	"hair_color_id": "blonde" # Domyślny kolor
}

func use_slot_data(slot_data: SlotData) -> void:
	if player and slot_data:
		slot_data.item_data.use(player)

# Funkcja do zapisywania danych z kreatora
func set_appearance_data(data: Dictionary) -> void:
	current_appearance_data = data.duplicate()

# Funkcja zwracająca obecne dane (przydatna przy ładowaniu gry)
func get_appearance_data() -> Dictionary:
	return current_appearance_data
