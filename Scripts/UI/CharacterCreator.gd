extends Node3D

# Referencja do instancji gracza w scenie
@onready var player_preview = $PlayerPreview

# --- USTAWIENIA UI (PRZYPISZ W INSPEKTORZE!) ---
@export_group("Navigation Buttons")
@export var btn_hair_next: Button # Przycisk zmiany modelu fryzury (Lewo/Prawo)
@export var btn_hair_prev: Button # Przycisk zmiany modelu fryzury (Lewo/Prawo)
@export var btn_start: Button

@export_group("Color Containers")
# Przeciągnij tu kontener (np. HBoxContainer), w którym są przyciski kolorów WŁOSÓW (BtnBlonde, BtnBlack...)
@export var hair_colors_container: Control 

# Przeciągnij tu kontener (np. HBoxContainer), w którym są przyciski kolorów OCZU (BtnEyeBlue, BtnEyeGreen...)
@export var eye_colors_container: Control 

# --- USTAWIENIA OBRACANIA ---
@export var rotation_sensitivity: float = 0.005
var is_dragging: bool = false 

# Domyślne ustawienia
var current_settings = {
	"gender": "female",
	"hair_color_id": "blonde",
	"hair_type": 1,
	"eye_color_id": "blue"
}

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Czekamy klatkę na pełne załadowanie drzewa sceny
	await get_tree().process_frame
	
	# 1. Podpinanie przycisków nawigacji (Fryzura Typ + Start)
	if btn_hair_next: btn_hair_next.pressed.connect(_on_hair_next_pressed)
	if btn_hair_prev: btn_hair_prev.pressed.connect(_on_hair_prev_pressed)
	if btn_start:     btn_start.pressed.connect(_on_start_game_pressed)
	
	# 2. Podpinanie przycisków KOLORU WŁOSÓW (z kontenera)
	if hair_colors_container:
		for child in hair_colors_container.get_children():
			# Szukamy przycisków typu BtnBlonde, BtnBlack...
			if child is Button and child.name.begins_with("Btn") and not "Eye" in child.name:
				# Wyciągamy nazwę koloru: BtnBlonde -> blonde
				var color_name = child.name.replace("Btn", "").to_lower()
				
				# Ignorujemy przyciski nawigacyjne jeśli przypadkiem tam są
				if "hair" in color_name or "start" in color_name: continue
				
				child.pressed.connect(func(): _on_hair_color_selected(color_name))
	else:
		printerr("UWAGA: Nie przypisano hair_colors_container w Inspektorze!")

	# 3. Podpinanie przycisków KOLORU OCZU (z kontenera)
	if eye_colors_container:
		for child in eye_colors_container.get_children():
			# Szukamy przycisków typu BtnEyeBlue, BtnEyeGreen...
			if child is Button and child.name.begins_with("BtnEye"):
				# Wyciągamy nazwę: BtnEyeBlue -> blue
				var eye_color = child.name.replace("BtnEye", "").to_lower()
				child.pressed.connect(func(): _on_eye_color_selected(eye_color))
	else:
		printerr("UWAGA: Nie przypisano eye_colors_container w Inspektorze!")

	# Odśwież wygląd na starcie
	_update_preview()


# --- ZMIANA MODELU FRYZURY (Typ 1, 2...) ---

func _on_hair_next_pressed():
	current_settings["hair_type"] += 1
	if current_settings["hair_type"] > 2: # Zmień na max liczbę fryzur
		current_settings["hair_type"] = 1
	_update_preview()

func _on_hair_prev_pressed():
	current_settings["hair_type"] -= 1
	if current_settings["hair_type"] < 1:
		current_settings["hair_type"] = 2
	_update_preview()


# --- WYBÓR KOLORÓW (BEZPOŚREDNI) ---

func _on_hair_color_selected(color_id: String):
	print("Wybrano kolor włosów: ", color_id)
	current_settings["hair_color_id"] = color_id
	_update_preview()

func _on_eye_color_selected(color_id: String):
	print("Wybrano kolor oczu: ", color_id)
	current_settings["eye_color_id"] = color_id
	_update_preview()


# --- START GRY ---

func _on_start_game_pressed():
	print("Start gry: ", current_settings)
	PlayerManager.set_appearance_data(current_settings)
	get_tree().change_scene_to_file("res://Scenes/world/test_world.tscn")


# --- AKTUALIZACJA POSTACI ---

func _update_preview():
	var mesh_controller = _find_mesh_controller(player_preview)
	if mesh_controller:
		mesh_controller.apply_appearance(current_settings)
	else:
		printerr("BŁĄD: Nie znaleziono player_mesh_controller!")

func _find_mesh_controller(node: Node) -> Node:
	if node.has_method("apply_appearance"): return node
	for child in node.get_children():
		var res = _find_mesh_controller(child)
		if res: return res
	return null

# Obracanie postaci
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_dragging = event.pressed
	if event is InputEventMouseMotion and is_dragging:
		player_preview.rotate_y(event.relative.x * rotation_sensitivity)
