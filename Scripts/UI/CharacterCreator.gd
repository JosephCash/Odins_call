extends Node3D

# Referencja do modelu postaci wyświetlanego w podglądzie
@onready var player_preview = $PlayerPreview

# --- USTAWIENIA UI ---
@export_group("Gender Selection")
@export var btn_gender_male: Button
@export var btn_gender_female: Button

@export_group("Navigation Buttons")
@export var btn_hair_next: Button
@export var btn_hair_prev: Button

@export var btn_beard_next: Button
@export var btn_beard_prev: Button

# NOWE: Zmienna do przypisania Label7 (napis "Beard Type")
@export var label_beard_title: Label 

@export var btn_start: Button

@export_group("Color Containers")
@export var hair_colors_container: Control 
@export var eye_colors_container: Control 
@export var skin_colors_container: Control

# --- USTAWIENIA OBRACANIA ---
@export var rotation_sensitivity: float = 0.005
var is_dragging: bool = false 

# --- USTAWIENIA OFFSETU KAMERY ---
@export_group("Scene References")
@export var camera_controller: Camera3D 

# --- DOMYŚLNE DANE ---
var current_settings = {
	"gender": "female",
	"hair_color_id": "blonde",
	"hair_type": 1,
	"beard_type": 1,
	"eye_color_id": "blue",
	"skin_id": "Default"
}

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	await get_tree().process_frame
	
	if btn_gender_male:   btn_gender_male.pressed.connect(func(): _on_gender_selected("male"))
	if btn_gender_female: btn_gender_female.pressed.connect(func(): _on_gender_selected("female"))
	
	if btn_hair_next: btn_hair_next.pressed.connect(_on_hair_next_pressed)
	if btn_hair_prev: btn_hair_prev.pressed.connect(_on_hair_prev_pressed)
	
	if btn_beard_next: btn_beard_next.pressed.connect(_on_beard_next_pressed)
	if btn_beard_prev: btn_beard_prev.pressed.connect(_on_beard_prev_pressed)
	
	if btn_start:     btn_start.pressed.connect(_on_start_game_pressed)
	
	if hair_colors_container:
		for child in hair_colors_container.get_children():
			if child is Button and child.name.begins_with("Btn") and not "Eye" in child.name and not "Skin" in child.name:
				var color_name = child.name.replace("Btn", "").to_lower()
				if "hair" in color_name or "start" in color_name: continue
				child.pressed.connect(func(): _on_hair_color_selected(color_name))

	if eye_colors_container:
		for child in eye_colors_container.get_children():
			if child is Button and child.name.begins_with("BtnEye"):
				var eye_color = child.name.replace("BtnEye", "").to_lower()
				child.pressed.connect(func(): _on_eye_color_selected(eye_color))

	if skin_colors_container:
		for child in skin_colors_container.get_children():
			if child is Button and child.name.begins_with("BtnSkin"):
				var skin_id = child.name.replace("BtnSkin", "")
				child.pressed.connect(func(): _on_skin_color_selected(skin_id))

	_update_preview()
	_update_beard_ui_visibility()

# --- FUNKCJE WYBORU ---

func _on_gender_selected(gender_id: String):
	if current_settings["gender"] != gender_id:
		current_settings["hair_type"] = 1
		# Przy zmianie płci resetujemy też brodę
		current_settings["beard_type"] = 1 

	current_settings["gender"] = gender_id
	_update_preview()
	_update_beard_ui_visibility()
	
	if camera_controller and camera_controller.has_method("move_to_gender"):
			camera_controller.move_to_gender(gender_id)

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
func _on_hair_next_pressed():
	current_settings["hair_type"] += 1
	var limit = _get_hair_limit_from_controller()
	if current_settings["hair_type"] > limit: 
		current_settings["hair_type"] = 1
	_update_preview()

func _on_hair_prev_pressed():
	current_settings["hair_type"] -= 1
	var limit = _get_hair_limit_from_controller()
	if current_settings["hair_type"] < 1:
		current_settings["hair_type"] = limit
	_update_preview()

# --- BRODA ---
func _on_beard_next_pressed():
	current_settings["beard_type"] += 1
	var limit = _get_beard_limit_from_controller()
	if current_settings["beard_type"] > limit: 
		current_settings["beard_type"] = 1
	_update_preview()

func _on_beard_prev_pressed():
	current_settings["beard_type"] -= 1
	var limit = _get_beard_limit_from_controller()
	if current_settings["beard_type"] < 1:
		current_settings["beard_type"] = limit
	_update_preview()

func _update_beard_ui_visibility():
	var is_male = (current_settings["gender"] == "male")
	
	# Ukrywamy/pokazujemy przyciski
	if btn_beard_next: btn_beard_next.visible = is_male
	if btn_beard_prev: btn_beard_prev.visible = is_male
	
	# NOWE: Ukrywamy/pokazujemy napis (Label7)
	if label_beard_title: label_beard_title.visible = is_male

# --- POMOCNICZE ---
func _get_hair_limit_from_controller() -> int:
	var controller = _find_mesh_controller(player_preview)
	if controller and controller.has_method("get_hair_count"):
		return controller.get_hair_count()
	return 1

func _get_beard_limit_from_controller() -> int:
	var controller = _find_mesh_controller(player_preview)
	if controller and controller.has_method("get_beard_count"):
		return controller.get_beard_count()
	return 1

# --- START ---
func _on_start_game_pressed():
	PlayerManager.set_appearance_data(current_settings)
	get_tree().change_scene_to_file("res://Scenes/world/test_world.tscn")

# --- AKTUALIZACJA ---
func _update_preview():
	var mesh_controller = _find_mesh_controller(player_preview)
	if mesh_controller:
		mesh_controller.apply_appearance(current_settings)

func _find_mesh_controller(node: Node) -> Node:
	if node.has_method("apply_appearance"): return node
	for child in node.get_children():
		var res = _find_mesh_controller(child)
		if res: return res
	return null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_dragging = event.pressed
	if event is InputEventMouseMotion and is_dragging:
		player_preview.rotate_y(event.relative.x * rotation_sensitivity)
