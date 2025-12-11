extends Control

# Funkcja wywoływana, gdy scena jest gotowa
func _ready():
	# Tutaj w przyszłości możemy np. sprawdzić czy istnieje zapis gry,
	# aby włączyć lub wyłączyć przycisk "Continue".
	pass

# --- Funkcje obsługujące kliknięcia ---

func _on_new_character_pressed():
	print("Kliknięto: New Character - Tu rozpocznie się nowa gra")

func _on_continue_pressed():
	print("Kliknięto: Continue - Tu wczytamy zapis")

func _on_options_pressed():
	print("Kliknięto: Options - Tu otworzymy ustawienia")

func _on_exit_pressed():
	print("Kliknięto: Exit - Zamykanie gry")
	get_tree().quit() # To faktycznie zamknie grę, możesz to zakomentować jeśli chcesz tylko testować print
