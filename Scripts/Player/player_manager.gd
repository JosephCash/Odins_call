extends Node

# Globalna referencja do aktywnej instancji gracza (ustawiana w _ready gracza)
var player

# Przechowuje dane o wyglądzie wybrane w kreatorze, aby przetrwały zmianę sceny
var current_appearance_data: Dictionary = {
	"gender": "female",
	"hair_color_id": "blonde" # Domyślny kolor
}

func use_slot_data(slot_data: SlotData) -> void:
	# Pośredniczy w użyciu przedmiotu (np. mikstury) na aktualnym graczu
	if player and slot_data:
		slot_data.item_data.use(player)

# Funkcja do zapisywania danych z kreatora
func set_appearance_data(data: Dictionary) -> void:
	# Kopiuje słownik z ustawieniami wyglądu (np. po kliknięciu "Start Game")
	current_appearance_data = data.duplicate()

# Funkcja zwracająca obecne dane (przydatna przy ładowaniu gry)
func get_appearance_data() -> Dictionary:
	# Udostępnia dane potrzebne do ustawienia modelu postaci po załadowaniu poziomu
	return current_appearance_data
