extends Control

# Funkcja wywoływana, gdy scena jest gotowa
func _ready():
	# Tutaj w przyszłości możemy sprawdzić zapis gry
	pass

# --- Funkcje obsługujące kliknięcia ---

func _on_new_character_pressed():
	print("Kliknięto: New Character - Otwieranie kreatora")
	# Pamiętaj, aby utworzyć scenę CharacterCreation.tscn w folderze Scenes/UI/
	get_tree().change_scene_to_file("res://Scenes/UI/CharacterCreation.tscn")

func _on_continue_pressed():
	print("Kliknięto: Continue - Tu wczytamy zapis")

func _on_options_pressed():
	print("Kliknięto: Options - Tu otworzymy ustawienia")

func _on_exit_pressed():
	print("Kliknięto: Exit - Zamykanie gry")
	get_tree().quit()
