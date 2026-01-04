extends Node

# --- BEZPIECZNA REFERENCJA DO GRACZA ---
var _player_ref: Node = null

var player: Node:
	set(value):
		_player_ref = value
	get:
		if is_instance_valid(_player_ref):
			return _player_ref
		return null

# --- DANE WYGLĄDU ---
var current_appearance_data: Dictionary = {
	"gender": "female",
	"hair_color_id": "blonde",
	"beard_type": 1 # <--- NOWE: Domyślny stan
}

func use_slot_data(slot_data: SlotData) -> void:
	if self.player and slot_data:
		slot_data.item_data.use(self.player)

# Funkcja do zapisywania danych z kreatora
func set_appearance_data(data: Dictionary) -> void:
	current_appearance_data = data.duplicate()

# Funkcja zwracająca obecne dane
func get_appearance_data() -> Dictionary:
	return current_appearance_data
