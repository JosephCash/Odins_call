extends Node3D

# Referencja do instancji gracza w scenie
@onready var player_preview = $PlayerPreview

# --- USTAWIENIA OBRACANIA ---
@export var rotation_sensitivity: float = 0.005 # Czułość obrotu myszką
var is_dragging: bool = false # Czy gracz trzyma lewy przycisk myszy

# Ustawienia początkowe postaci
var current_settings = {
	"gender": "female",
	"hair_color_id": "blonde"
}

func _ready():
	# 1. Pokaż kursor myszy
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# 2. Inicjalizacja wyglądu na start (czekamy klatkę, aż scena się załaduje)
	await get_tree().process_frame
	_update_preview()
	
	# 3. Automatyczne podpinanie przycisków
	var btn_container = $CanvasLayer/Control/Panel/VBoxContainer/HBoxContainer
	
	if btn_container:
		if btn_container.has_node("BtnBlonde"): 
			btn_container.get_node("BtnBlonde").pressed.connect(func(): _on_color_selected("blonde"))
		
		if btn_container.has_node("BtnBlack"): 
			btn_container.get_node("BtnBlack").pressed.connect(func(): _on_color_selected("black"))
			
		if btn_container.has_node("BtnBrown"): 
			btn_container.get_node("BtnBrown").pressed.connect(func(): _on_color_selected("brown"))
			
		if btn_container.has_node("BtnOrange"): 
			btn_container.get_node("BtnOrange").pressed.connect(func(): _on_color_selected("orange"))
			
		if btn_container.has_node("BtnWhite"): 
			btn_container.get_node("BtnWhite").pressed.connect(func(): _on_color_selected("white"))
	
	# Podpięcie przycisku Start
	# Szukamy przycisku Start w kontenerze pionowym lub bezpośrednio w Panelu, zależnie od Twojej struktury
	# Tutaj szukam rekurencyjnie lub po konkretnej ścieżce
	var start_btn = $CanvasLayer/Control/Panel/VBoxContainer/HBoxContainer/BtnStart
	if start_btn:
		start_btn.pressed.connect(_on_start_game_pressed)


# --- OBRACANIE POSTACI (NOWE) ---

func _unhandled_input(event: InputEvent) -> void:
	# Sprawdzamy kliknięcie myszką (LPM)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed # True jak wciśnięty, False jak puszczony

	# Sprawdzamy ruch myszką, ale tylko gdy trzymamy przycisk
	if event is InputEventMouseMotion and is_dragging:
		# Obracamy postać wokół osi Y (pionowej)
		# event.relative.x to różnica ruchu myszy w poziomie
		player_preview.rotate_y(event.relative.x * rotation_sensitivity)


# --- LOGIKA ZMIANY KOLORU ---

func _on_color_selected(color_id: String):
	print("Wybrano kolor: ", color_id)
	current_settings["hair_color_id"] = color_id
	_update_preview()

func _update_preview():
	var mesh_controller = _find_mesh_controller(player_preview)
	
	if mesh_controller:
		mesh_controller.apply_appearance(current_settings)
	else:
		# Jeśli nie znaleziono, spróbujmy znaleźć ręcznie (zabezpieczenie)
		# Czasami struktura jest inna po instancjonowaniu
		pass

# Funkcja pomocnicza do szukania kontrolera
func _find_mesh_controller(node: Node) -> Node:
	if node.has_method("apply_appearance"):
		return node
	
	for child in node.get_children():
		var result = _find_mesh_controller(child)
		if result:
			return result
	return null


# --- ZATWIERDZENIE I START ---

func _on_start_game_pressed():
	print("Start gry z ustawieniami: ", current_settings)
	
	# 1. Zapisz dane
	PlayerManager.set_appearance_data(current_settings)
	
	# 2. Przełącz scenę (Poprawiona ścieżka bez "Odins_call/")
	get_tree().change_scene_to_file("res://Scenes/world/test_world.tscn")
