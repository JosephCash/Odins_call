extends Control

# Sygnał, który powiadomi main.gd o chęci wznowienia gry (przycisk Kontynuuj)
signal resume_game

func _ready():
	# Ukrywamy menu na starcie
	hide()

func _on_btn_continue_pressed():
	# Emitujemy sygnał, main.gd go odbierze i wznowi grę
	resume_game.emit()

func _on_btn_options_pressed():
	print("Otwieram ustawienia (placeholder)")

func _on_btn_exit_pressed():
	# 1. BARDZO WAŻNE: Odblokuj grę! 
	# Jeśli zmienisz scenę będąc na pauzie, nowa scena (Menu Główne) też będzie zamrożona.
	get_tree().paused = false
	
	# 2. Upewnij się, że kursor jest widoczny (Menu Główne tego potrzebuje)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# 3. Zmień scenę na Menu Główne
	# Upewnij się, że ścieżka jest poprawna (wzięta z Twojej struktury plików)
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
