extends Node3D

# Referencja do instancji gracza w scenie
@onready var player_preview = $PlayerPreview

# --- PRZYCISKI (PRZYPISZ JE W INSPEKTORZE!) ---
@export_group("UI References")
@export var btn_hair_next: Button  # Przeciągnij tu przycisk Next
@export var btn_hair_prev: Button  # Przeciągnij tu przycisk Prev
@export var btn_start: Button      # Przeciągnij tu przycisk Start

# Opcjonalnie kolory (jeśli chcesz je też ręcznie, lub zostawiamy szukanie)
# Dla uproszczenia zostawiam starą metodę szukania kolorów, bo ona chyba działała?

# --- USTAWIENIA OBRACANIA ---
@export var rotation_sensitivity: float = 0.005
var is_dragging: bool = false 

var current_settings = {
	"gender": "female",
	"hair_color_id": "blonde",
	"hair_type": 1
}

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Czekamy klatkę na załadowanie
	await get_tree().process_frame
	
	# --- DIAGNOSTYKA I PODPINANIE ---
	print("--- INICJALIZACJA KREATORA ---")
	
	if btn_hair_next:
		btn_hair_next.pressed.connect(_on_hair_next_pressed)
		print("Przycisk Hair Next: PODPIĘTY")
	else:
		printerr("BŁĄD: Nie przypisano przycisku btn_hair_next w Inspektorze!")

	if btn_hair_prev:
		btn_hair_prev.pressed.connect(_on_hair_prev_pressed)
		print("Przycisk Hair Prev: PODPIĘTY")
	else:
		printerr("BŁĄD: Nie przypisano przycisku btn_hair_prev w Inspektorze!")
		
	if btn_start:
		btn_start.pressed.connect(_on_start_game_pressed)
	
	# Podpinanie kolorów (stara metoda - jeśli działała, to zostawiamy)
	var ui_root = $CanvasLayer/Control/Panel/VBoxContainer/HBoxContainer
	if ui_root:
		for child in ui_root.get_children():
			if child is Button and child.name.begins_with("Btn"):
				# Wyciągamy kolor z nazwy np. BtnBlonde -> blonde
				var color_name = child.name.replace("Btn", "").to_lower()
				# Ignorujemy przyciski nawigacji jeśli są w tym samym kontenerze
				if "hair" in color_name or "start" in color_name:
					continue
				
				child.pressed.connect(func(): _on_color_selected(color_name))

	_update_preview()


# --- OBSŁUGA KLIKNIĘĆ ---

func _on_hair_next_pressed():
	print("KLIKNIĘTO: Następna fryzura")
	current_settings["hair_type"] += 1
	if current_settings["hair_type"] > 2: 
		current_settings["hair_type"] = 1
	_update_preview()

func _on_hair_prev_pressed():
	print("KLIKNIĘTO: Poprzednia fryzura")
	current_settings["hair_type"] -= 1
	if current_settings["hair_type"] < 1:
		current_settings["hair_type"] = 2
	_update_preview()

func _on_color_selected(color_id: String):
	print("KLIKNIĘTO: Kolor ", color_id)
	current_settings["hair_color_id"] = color_id
	_update_preview()

func _on_start_game_pressed():
	print("Start gry!")
	PlayerManager.set_appearance_data(current_settings)
	get_tree().change_scene_to_file("res://Scenes/world/test_world.tscn")

# --- AKTUALIZACJA POSTACI ---

func _update_preview():
	print("Aktualizuję wygląd: ", current_settings)
	var mesh_controller = _find_mesh_controller(player_preview)
	
	if mesh_controller:
		mesh_controller.apply_appearance(current_settings)
	else:
		printerr("BŁĄD: Nie znaleziono skryptu player_mesh_controller na postaci!")

# --- FUNKCJE POMOCNICZE ---

func _find_mesh_controller(node: Node) -> Node:
	if node.has_method("apply_appearance"):
		return node
	for child in node.get_children():
		var result = _find_mesh_controller(child)
		if result: return result
	return null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_dragging = event.pressed
	if event is InputEventMouseMotion and is_dragging:
		player_preview.rotate_y(event.relative.x * rotation_sensitivity)
