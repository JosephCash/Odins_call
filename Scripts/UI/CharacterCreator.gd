extends Node3D

# Referencja do modelu postaci wyświetlanego w podglądzie
@onready var player_preview = $PlayerPreview

# --- USTAWIENIA UI ---
# Grupy zmiennych eksportowanych do przypisania przycisków i kontenerów w edytorze
@export_group("Navigation Buttons")
@export var btn_hair_next: Button
@export var btn_hair_prev: Button
@export var btn_start: Button

@export_group("Color Containers")
@export var hair_colors_container: Control 
@export var eye_colors_container: Control 
@export var skin_colors_container: Control

# --- USTAWIENIA OBRACANIA ---
# Parametry sterujące czułością i stanem obracania modelu myszką
@export var rotation_sensitivity: float = 0.005
var is_dragging: bool = false 

# --- DOMYŚLNE DANE ---
# Słownik przechowujący aktualny stan wyboru wyglądu postaci
var current_settings = {
	"gender": "female",
	"hair_color_id": "blonde",
	"hair_type": 1,
	"eye_color_id": "blue",
	"skin_id": "Default"
}

func _ready():
	# Ustawia widoczność kursora i podpina stałe przyciski interfejsu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	await get_tree().process_frame
	
	if btn_hair_next: btn_hair_next.pressed.connect(_on_hair_next_pressed)
	if btn_hair_prev: btn_hair_prev.pressed.connect(_on_hair_prev_pressed)
	if btn_start:     btn_start.pressed.connect(_on_start_game_pressed)
	
	# Dynamicznie podpina sygnały do przycisków kolorów włosów na podstawie ich nazw
	if hair_colors_container:
		for child in hair_colors_container.get_children():
			if child is Button and child.name.begins_with("Btn") and not "Eye" in child.name and not "Skin" in child.name:
				var color_name = child.name.replace("Btn", "").to_lower()
				if "hair" in color_name or "start" in color_name: continue
				child.pressed.connect(func(): _on_hair_color_selected(color_name))

	# Dynamicznie podpina sygnały do przycisków kolorów oczu
	if eye_colors_container:
		for child in eye_colors_container.get_children():
			if child is Button and child.name.begins_with("BtnEye"):
				var eye_color = child.name.replace("BtnEye", "").to_lower()
				child.pressed.connect(func(): _on_eye_color_selected(eye_color))

	# Dynamicznie podpina sygnały do przycisków kolorów skóry
	if skin_colors_container:
		for child in skin_colors_container.get_children():
			if child is Button and child.name.begins_with("BtnSkin"):
				var skin_id = child.name.replace("BtnSkin", "")
				child.pressed.connect(func(): _on_skin_color_selected(skin_id))
	else:
		printerr("UWAGA: Nie przypisano skin_colors_container!")

	_update_preview()

# --- FUNKCJE WYBORU ---
# Aktualizuje wybrany kolor (włosy/oczy/skóra) w słowniku i odświeża podgląd
func _on_hair_color_selected(color_id: String):
	current_settings["hair_color_id"] = color_id
	_update_preview()

func _on_eye_color_selected(color_id: String):
	current_settings["eye_color_id"] = color_id
	_update_preview()

func _on_skin_color_selected(skin_id: String):
	current_settings["skin_id"] = skin_id
	_update_preview()

# --- FRYZURA ---
# Zmienia typ fryzury (cyklicznie w górę lub w dół) i odświeża podgląd
func _on_hair_next_pressed():
	current_settings["hair_type"] += 1
	if current_settings["hair_type"] > 2: 
		current_settings["hair_type"] = 1
	_update_preview()

func _on_hair_prev_pressed():
	current_settings["hair_type"] -= 1
	if current_settings["hair_type"] < 1:
		current_settings["hair_type"] = 2
	_update_preview()

# --- START ---
# Przekazuje wybrane dane do globalnego menedżera gracza i zmienia scenę na świat gry
func _on_start_game_pressed():
	PlayerManager.set_appearance_data(current_settings)
	get_tree().change_scene_to_file("res://Scenes/world/test_world.tscn")

# --- AKTUALIZACJA ---
# Znajduje skrypt kontrolujący siatkę modelu i aplikuje aktualne ustawienia wyglądu
func _update_preview():
	var mesh_controller = _find_mesh_controller(player_preview)
	if mesh_controller:
		mesh_controller.apply_appearance(current_settings)

# Rekurencyjnie przeszukuje dzieci węzła w poszukiwaniu metody 'apply_appearance'
func _find_mesh_controller(node: Node) -> Node:
	if node.has_method("apply_appearance"): return node
	for child in node.get_children():
		var res = _find_mesh_controller(child)
		if res: return res
	return null

# Obsługuje obracanie modelu postaci poprzez przeciąganie myszką z wciśniętym lewym przyciskiem
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_dragging = event.pressed
	if event is InputEventMouseMotion and is_dragging:
		player_preview.rotate_y(event.relative.x * rotation_sensitivity)
