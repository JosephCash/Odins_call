extends Node3D

# --- KONFIGURACJA PŁCI I REFERENCJE GŁÓWNE ---
var current_gender: String = "female"

@onready var female_root = $Female_character_skeletalmesh
@onready var male_root = $Male_character_skeletalmesh

# --- KONFIGURACJA ŚCIEŻEK ---
@export var skeleton_path: String = "Armature/Skeleton3D"
@export var hair_attachment_path: String = "Armature/Skeleton3D/HeadAttachment"

# --- ZMIENNE AKTYWNE ---
var feet_mesh: MeshInstance3D
var legs_mesh: MeshInstance3D
var torso_mesh: MeshInstance3D
var hands_mesh: MeshInstance3D
var head_mesh: MeshInstance3D       
var face_mesh_ref: MeshInstance3D   
var hair_mesh: MeshInstance3D 
var beard_mesh: MeshInstance3D      

var active_hair_attachment: Node3D 

# Te zmienne trzymają referencje, ale dla pewności będziemy też czyścić po dzieciach węzła
var active_hair_node: Node         
var active_beard_node: Node         

# --- DANE DOMYŚLNE ---
var default_data = {
	"female": {"feet": {}, "legs": {}, "torso": {}, "hands": {}, "head": {}},
	"male":   {"feet": {}, "legs": {}, "torso": {}, "hands": {}, "head": {}},
}

# --- LISTY FRYZUR I BRÓD ---
@export var hair_scenes: Array[PackedScene]      # Damskie
@export var male_hair_scenes: Array[PackedScene] # Męskie
@export var male_beard_scenes: Array[PackedScene] # Męskie brody 

# --- DANE KOSMETYCZNE ---
var current_hair_type: int = 1 
var current_beard_type: int = 1     
var current_hair_color: String = "blonde"
var current_skin_id: String = "Default"

var skin_presets = {
	"Default":   {"light": Color("eba697"), "mid": Color("de9a8f"), "dark": Color("be7e71"), "lips": 0.0},
	"Pale":      {"light": Color("ecc1ba"), "mid": Color("e8b6ac"), "dark": Color("cc9992"), "lips": -0.3},
	"Yellow":    {"light": Color("ecc6ab"), "mid": Color("e8bba0"), "dark": Color("cc9e83"), "lips": -0.1},
	"Tan":       {"light": Color("cc947a"), "mid": Color("bd846b"), "dark": Color("945f4d"), "lips": 0.1},
	"Lightdark": {"light": Color("cc9d8d"), "mid": Color("bf8d7c"), "dark": Color("996b5b"), "lips": 0.1},
	"Dark":      {"light": Color("a17263"), "mid": Color("946354"), "dark": Color("704437"), "lips": 0.2}
}

var eyebrow_palette = {
	"blonde": Color(0.67, 0.46, 0.34),
	"black": Color(0.12, 0.12, 0.12),
	"brown": Color(0.32, 0.22, 0.15),
	"orange": Color(0.6, 0.25, 0.05),
	"white": Color(0.6, 0.6, 0.6)
}

var eye_palette = {
	"blue":      {"h": 0.0,   "s": 0.0,   "v": 0.0},
	"green":     {"h": -0.35, "s": 0.2,   "v": -0.1},
	"brown":     {"h": -0.55, "s": -0.03, "v": -0.22},
	"grey":      {"h": 0.0,   "s": -1.0,  "v": -0.1},
	"turquoise": {"h": -0.15, "s": 0.1,   "v": 0.0},
	"orange":    {"h": 0.44,  "s": 0.1,   "v": 0.05}
}


func _ready() -> void:
	await get_tree().process_frame
	
	_initialize_references("female", female_root)
	_initialize_references("male", male_root)

	var data = PlayerManager.get_appearance_data()
	apply_appearance(data)


func _initialize_references(gender_key: String, root_node: Node3D) -> void:
	if not root_node: return
		
	var full_skel_path = skeleton_path
	if not full_skel_path.ends_with("/"): full_skel_path += "/"
	
	var f_feet = root_node.get_node_or_null(full_skel_path + "FeetSlot/Feet")
	var f_legs = root_node.get_node_or_null(full_skel_path + "LegsSlot/Legs")
	var f_torso = root_node.get_node_or_null(full_skel_path + "TorsoSlot/Torso")
	var f_hands = root_node.get_node_or_null(full_skel_path + "HandsSlot/Hands")
	var f_head = root_node.get_node_or_null(full_skel_path + "HeadSlot/Head")
	
	if f_feet: default_data[gender_key]["feet"] = {"mesh": f_feet.mesh, "mat": f_feet.get_active_material(0)}
	if f_legs: default_data[gender_key]["legs"] = {"mesh": f_legs.mesh, "mat": f_legs.get_active_material(0)}
	if f_torso: default_data[gender_key]["torso"] = {"mesh": f_torso.mesh, "mat": f_torso.get_active_material(0)}
	if f_hands: default_data[gender_key]["hands"] = {"mesh": f_hands.mesh, "mat": f_hands.get_active_material(0)}
	if f_head: default_data[gender_key]["head"] = {"mesh": f_head.mesh, "mat": f_head.get_active_material(0)}
	
	# POPRAWKA: Wyczyść wszelkie "śmieciowe" fryzury z edytora przy starcie
	var attachment = root_node.get_node_or_null(hair_attachment_path)
	if attachment:
		for child in attachment.get_children():
			child.queue_free()


func apply_appearance(data: Dictionary) -> void:
	if data.is_empty(): return

	if data.has("gender"):
		set_gender(data["gender"])
	elif current_gender == "":
		set_gender("female")

	if data.has("hair_type"):
		var new_type = int(data["hair_type"])
		# Zawsze wymuszamy zmianę jeśli nie mamy mesha (np. po zmianie płci)
		if new_type != current_hair_type or hair_mesh == null or active_hair_node == null:
			current_hair_type = new_type
			change_hair_model(current_hair_type)
	
	if data.has("beard_type"):
		var new_beard = int(data["beard_type"])
		if new_beard != current_beard_type or beard_mesh == null:
			current_beard_type = new_beard
			change_beard_model(current_beard_type)

	if data.has("hair_color_id"):
		current_hair_color = data["hair_color_id"]
		if hair_mesh: update_hair_texture()
		if beard_mesh: update_beard_texture()
		update_eyebrow_color(current_hair_color)
		
	if data.has("eye_color_id"):
		update_eye_color(data["eye_color_id"])
		
	if data.has("skin_id"):
		current_skin_id = data["skin_id"]
		refresh_all_skin_materials()


func set_gender(new_gender: String) -> void:
	if new_gender != "female" and new_gender != "male": return
	
	var gender_changed = (current_gender != new_gender)
	current_gender = new_gender
	
	if female_root: female_root.visible = (current_gender == "female")
	if male_root:   male_root.visible   = (current_gender == "male")
	
	var active_root = female_root if current_gender == "female" else male_root
	if not active_root: return
	
	var full_skel_path = skeleton_path
	if not full_skel_path.ends_with("/"): full_skel_path += "/"
	
	feet_mesh  = active_root.get_node_or_null(full_skel_path + "FeetSlot/Feet")
	legs_mesh  = active_root.get_node_or_null(full_skel_path + "LegsSlot/Legs")
	torso_mesh = active_root.get_node_or_null(full_skel_path + "TorsoSlot/Torso")
	hands_mesh = active_root.get_node_or_null(full_skel_path + "HandsSlot/Hands")
	head_mesh  = active_root.get_node_or_null(full_skel_path + "HeadSlot/Head")
	
	face_mesh_ref = _find_mesh_recursive(active_root, "Face")
	
	# Ustawiamy attachment point dla nowej płci
	active_hair_attachment = active_root.get_node_or_null(hair_attachment_path)
	
	# Resetujemy referencje do obiektów, bo zmieniło się całe drzewo
	hair_mesh = null
	active_hair_node = null
	beard_mesh = null
	active_beard_node = null
	
	# Zabezpieczenie limitów przy zmianie płci
	if gender_changed:
		var max_hair = get_hair_count()
		if current_hair_type > max_hair: current_hair_type = 1
		
		var max_beard = get_beard_count()
		if current_beard_type > max_beard: current_beard_type = 1

	change_hair_model(current_hair_type)
	change_beard_model(current_beard_type)
	refresh_all_skin_materials()

# --- POMOCNICZE FUNKCJE DLA UI ---
func get_hair_count() -> int:
	if current_gender == "female":
		return hair_scenes.size() if hair_scenes else 0
	else:
		return male_hair_scenes.size() if male_hair_scenes else 0

func get_beard_count() -> int:
	if current_gender == "female":
		return 0
	else:
		return male_beard_scenes.size() if male_beard_scenes else 0

func change_hair_model(type_index: int) -> void:
	if not active_hair_attachment: return
	
	# POPRAWKA: Pętla czyszcząca wszystkie stare fryzury
	# Usuwamy wszystko co NIE JEST obecną brodą
	for child in active_hair_attachment.get_children():
		if child == active_beard_node and is_instance_valid(active_beard_node):
			continue # To jest broda, zostawiamy
		child.queue_free() # To jest stara fryzura lub śmieć, usuwamy
	
	# Teraz tworzymy nową fryzurę
	var scenes_list = hair_scenes if current_gender == "female" else male_hair_scenes
	var array_index = type_index - 1
	
	if scenes_list != null and array_index >= 0 and array_index < scenes_list.size():
		var scene_to_spawn = scenes_list[array_index]
		if scene_to_spawn:
			var new_hair_node = scene_to_spawn.instantiate()
			active_hair_attachment.add_child(new_hair_node)
			
			active_hair_node = new_hair_node # Aktualizujemy referencję
			
			hair_mesh = _find_mesh_recursive(new_hair_node, "Hair")
			if not hair_mesh: hair_mesh = _find_mesh_recursive(new_hair_node, "")
			update_hair_texture()

func change_beard_model(type_index: int) -> void:
	if not active_hair_attachment: return
	
	# POPRAWKA: Pętla czyszcząca stare brody
	# Usuwamy wszystko co NIE JEST obecnymi włosami
	for child in active_hair_attachment.get_children():
		if child == active_hair_node and is_instance_valid(active_hair_node):
			continue # To są włosy, zostawiamy
		child.queue_free() # To stara broda lub śmieć, usuwamy
	
	if current_gender == "female": return
	
	var array_index = type_index - 1
	
	if male_beard_scenes != null and array_index >= 0 and array_index < male_beard_scenes.size():
		var scene_to_spawn = male_beard_scenes[array_index]
		if scene_to_spawn:
			var new_beard_node = scene_to_spawn.instantiate()
			active_hair_attachment.add_child(new_beard_node)
			
			active_beard_node = new_beard_node # Aktualizujemy referencję
			
			beard_mesh = _find_mesh_recursive(new_beard_node, "Beard")
			if not beard_mesh: beard_mesh = _find_mesh_recursive(new_beard_node, "")
			
			update_beard_texture()

func update_hair_texture() -> void:
	if not hair_mesh: return
	
	var base_path = ""
	var texture_name = ""

	if current_gender == "female":
		base_path = "res://Assets/Resources/textures/FemaleCharacter/Hair/"
		texture_name = "t_female_hair" + str(current_hair_type) + "_" + current_hair_color + ".png"
	elif current_gender == "male":
		base_path = "res://Assets/Resources/textures/MaleCharacter/Hair/"
		texture_name = "t_male_hair" + str(current_hair_type) + "_" + current_hair_color + ".png"

	var full_path = base_path + texture_name
	
	if ResourceLoader.exists(full_path):
		var new_texture = load(full_path)
		var current_mat = hair_mesh.get_active_material(0) as StandardMaterial3D
		if current_mat:
			if hair_mesh.get_surface_override_material(0) == null:
				var mat_copy = current_mat.duplicate()
				hair_mesh.set_surface_override_material(0, mat_copy)
				mat_copy.albedo_texture = new_texture
			else:
				hair_mesh.get_surface_override_material(0).albedo_texture = new_texture

func update_beard_texture() -> void:
	if not beard_mesh: return
	
	var base_path = "res://Assets/Resources/textures/MaleCharacter/Beard/"
	var texture_name = "t_male_beard" + str(current_beard_type) + "_" + current_hair_color + ".png"
	var full_path = base_path + texture_name
	
	if ResourceLoader.exists(full_path):
		var new_texture = load(full_path)
		var current_mat = beard_mesh.get_active_material(0) as StandardMaterial3D
		if current_mat:
			if beard_mesh.get_surface_override_material(0) == null:
				var mat_copy = current_mat.duplicate()
				beard_mesh.set_surface_override_material(0, mat_copy)
				mat_copy.albedo_texture = new_texture
			else:
				beard_mesh.get_surface_override_material(0).albedo_texture = new_texture

# --- LOGIKA SKÓRY ---

func refresh_all_skin_materials() -> void:
	if not skin_presets.has(current_skin_id): current_skin_id = "Default"
	var colors = skin_presets[current_skin_id]
	
	if head_mesh: _inject_colors_to_mesh(head_mesh, colors)
	if torso_mesh: _inject_colors_to_mesh(torso_mesh, colors)
	if legs_mesh: _inject_colors_to_mesh(legs_mesh, colors)
	if hands_mesh: _inject_colors_to_mesh(hands_mesh, colors)
	if feet_mesh: _inject_colors_to_mesh(feet_mesh, colors)
	
	if face_mesh_ref: _inject_colors_to_mesh(face_mesh_ref, colors)

func _inject_colors_to_mesh(mesh_instance: MeshInstance3D, colors: Dictionary) -> void:
	var check_count = 1
	if mesh_instance.mesh: check_count = mesh_instance.mesh.get_surface_count()
	if mesh_instance.get_surface_override_material_count() > 0:
		check_count = max(check_count, mesh_instance.get_surface_override_material_count())

	for i in range(check_count):
		var mat = mesh_instance.get_active_material(i)
		if mat is ShaderMaterial:
			mat.set_shader_parameter("skin_light", colors["light"])
			mat.set_shader_parameter("skin_mid",   colors["mid"])
			mat.set_shader_parameter("skin_dark",  colors["dark"])
			if mesh_instance == face_mesh_ref:
				mat.set_shader_parameter("lip_darkness", colors.get("lips", 0.0))

# --- LOGIKA TWARZY ---

func update_eyebrow_color(color_id: String) -> void:
	if not face_mesh_ref: return
	var mat = face_mesh_ref.get_active_material(0)
	if mat is ShaderMaterial and eyebrow_palette.has(color_id):
		mat.set_shader_parameter("new_eyebrow_color", eyebrow_palette[color_id])

func update_eye_color(color_id: String) -> void:
	if not face_mesh_ref: return
	var mat = face_mesh_ref.get_active_material(0)
	if mat is ShaderMaterial and eye_palette.has(color_id):
		var val = eye_palette[color_id]
		mat.set_shader_parameter("eye_hue_shift", val["h"])
		mat.set_shader_parameter("eye_sat_shift", val["s"])
		mat.set_shader_parameter("eye_val_shift", val["v"])

func _find_mesh_recursive(node: Node, target_name_part: String) -> MeshInstance3D:
	if node is MeshInstance3D:
		if target_name_part == "" or node.name.contains(target_name_part): return node
	for child in node.get_children():
		var res = _find_mesh_recursive(child, target_name_part)
		if res: return res
	return null

# --- EKWIPUNEK ---
func apply_feet_item(item): _apply_item(item, feet_mesh, "feet")
func apply_legs_item(item): _apply_item(item, legs_mesh, "legs")
func apply_torso_item(item): _apply_item(item, torso_mesh, "torso")
func apply_hands_item(item): _apply_item(item, hands_mesh, "hands")
func apply_head_item(item): _apply_item(item, head_mesh, "head")

func _apply_item(item, mesh_ref, part_key):
	if not mesh_ref: return
	var def = default_data[current_gender][part_key]
	if item:
		mesh_ref.mesh = item.mesh if item.mesh else def.get("mesh")
		mesh_ref.set_surface_override_material(0, item.material if item.material else def.get("mat"))
	else:
		mesh_ref.mesh = def.get("mesh")
		mesh_ref.set_surface_override_material(0, def.get("mat"))
	refresh_all_skin_materials()
