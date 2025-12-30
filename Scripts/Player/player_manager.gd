extends Node

# --- BEZPIECZNA REFERENCJA DO GRACZA ---
# Prywatna zmienna przechowująca referencję
var _player_ref: Node = null

# Publiczna właściwość, której używamy w innych skryptach
var player: Node:
	set(value):
		_player_ref = value
	get:
		# Sprawdzamy, czy obiekt nadal istnieje w pamięci
		if is_instance_valid(_player_ref):
			return _player_ref
		# Jeśli obiekt został usunięty (np. przy wyjściu do menu), zwracamy null
		return null

# --- DANE WYGLĄDU ---
# Przechowuje dane o wyglądzie wybrane w kreatorze, aby przetrwały zmianę sceny
var current_appearance_data: Dictionary = {
	"gender": "female",
	"hair_color_id": "blonde" # Domyślny kolor
}

func use_slot_data(slot_data: SlotData) -> void:
	# Używamy self.player, aby zadziałał nasz bezpieczny getter
	if self.player and slot_data:
		slot_data.item_data.use(self.player)

# Funkcja do zapisywania danych z kreatora
func set_appearance_data(data: Dictionary) -> void:
	# Kopiuje słownik z ustawieniami wyglądu (np. po kliknięciu "Start Game")
	current_appearance_data = data.duplicate()

# Funkcja zwracająca obecne dane (przydatna przy ładowaniu gry)
func get_appearance_data() -> Dictionary:
	# Udostępnia dane potrzebne do ustawienia modelu postaci po załadowaniu poziomu
	return current_appearance_data
