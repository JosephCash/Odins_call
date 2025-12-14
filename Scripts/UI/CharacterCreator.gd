extends Node3D

# Referencja do instancji gracza w scenie
@onready var player_preview = $PlayerPreview

# --- USTAWIENIA UI ---
@export_group("Navigation Buttons")
@export var btn_hair_next: Button
@export var btn_hair_prev: Button
@export var btn_start: Button

@export_group("Color Containers")
@export var hair_colors_container: Control 
@export var eye_colors_container: Control 
@export var skin_colors_container: Control # Tu muszą być przyciski BtnSkinPale, BtnSkinTan itp.

# --- USTAWIENIA OBRACANIA ---
@export var rotation_sensitivity: float = 0.005
var is_dragging: bool = false 

# --- DOMYŚLNE DANE ---
var current_settings = {
	"gender": "female",
	"hair_color_id": "blonde",
	"hair_type": 1,
	"eye_color_id": "blue",
	"skin_id": "Default" # Ważne: Musi pasować do klucza w słowniku
}

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	await get_tree().process_frame
	
	# Podpinanie przycisków
	if btn_hair_next: btn_hair_next.pressed.connect(_on_hair_next_pressed)
	if btn_hair_prev: btn_hair_prev.pressed.connect(_on_hair_prev_pressed)
	if btn_start:     btn_start.pressed.connect(_on_start_game_pressed)
	
	# 1. WŁOSY
	if hair_colors_container:
		for child in hair_colors_container.get_children():
			if child is Button and child.name.begins_with("Btn") and not "Eye" in child.name and not "Skin" in child.name:
				var color_name = child.name.replace("Btn", "").to_lower()
				if "hair" in color_name or "start" in color_name: continue
				child.pressed.connect(func(): _on_hair_color_selected(color_name))

	# 2. OCZY
	if eye_colors_container:
		for child in eye_colors_container.get_children():
			if child is Button and child.name.begins_with("BtnEye"):
				var eye_color = child.name.replace("BtnEye", "").to_lower()
				child.pressed.connect(func(): _on_eye_color_selected(eye_color))

	# 3. SKÓRA (Dynamiczne podpinanie)
	if skin_colors_container:
		for child in skin_colors_container.get_children():
			# Kod szuka przycisków zaczynających się od "BtnSkin"
			if child is Button and child.name.begins_with("BtnSkin"):
				# Wyciąga nazwę: BtnSkinYellow -> Yellow
				var skin_id = child.name.replace("BtnSkin", "")
				child.pressed.connect(func(): _on_skin_color_selected(skin_id))
	else:
		printerr("UWAGA: Nie przypisano skin_colors_container!")

	_update_preview()

# --- FUNKCJE WYBORU ---
func _on_hair_color_selected(color_id: String):
	current_settings["hair_color_id"] = color_id
	_update_preview()

func _on_eye_color_selected(color_id: String):
	current_settings["eye_color_id"] = color_id
	_update_preview()

func _on_skin_color_selected(skin_id: String):
	print("Wybrano skórę: ", skin_id)
	current_settings["skin_id"] = skin_id
	_update_preview()

# --- FRYZURA ---
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
