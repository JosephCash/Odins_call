extends Control

# Funkcja wywoływana, gdy scena jest gotowa
func _ready():
	# Tutaj w przyszłości możemy sprawdzić czy istnieją zapisy gry, aby np. aktywować przycisk "Kontynuuj"
	pass

# --- Funkcje obsługujące kliknięcia ---

func _on_new_character_pressed():
	# Przełącza na scenę tworzenia postaci (należy upewnić się, że plik istnieje w podanej ścieżce)
	get_tree().change_scene_to_file("res://Scenes/UI/CharacterCreation.tscn")

func _on_continue_pressed():
	# Placeholder: tutaj trafi logika wczytywania zapisanego stanu gry
	print("Kliknięto: Continue - Tu wczytamy zapis")

func _on_options_pressed():
	# Placeholder: tutaj trafi logika otwierania panelu opcji/ustawień
	print("Kliknięto: Options - Tu otworzymy ustawienia")

func _on_exit_pressed():
	# Całkowicie zamyka aplikację (wychodzi do pulpitu)
	get_tree().quit()
