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
var active_hair_node: Node         
var active_beard_node: Node         

# --- DANE DOMYŚLNE ---
var default_data = {
	"female": {"feet": {}, "legs": {}, "torso": {}, "hands": {}, "head": {}},
	"male":   {"feet": {}, "legs": {}, "torso": {}, "hands": {}, "head": {}},
}

# --- LISTY FRYZUR I BRÓD ---
@export var hair_scenes: Array[PackedScene]      
@export var male_hair_scenes: Array[PackedScene] 
@export var male_beard_scenes: Array[PackedScene] 

# --- DANE KOSMETYCZNE ---
var current_hair_type: int = 1 
var current_beard_type: int = 1     
var current_hair_color: String = "blonde"
var current_skin_id: String = "Default"

# --- DANE TATUAŻY ---
var current_tattoo_index: int = 0
var current_tattoo_color_id: String = "black"

var tattoo_count_male: int = 0
var tattoo_count_female: int = 0

# --- PALETA KOLORÓW TATUAŻY ---
var tattoo_palette = {
	"black":  Color(0.15, 0.15, 0.15),
	"viking": Color(0.18, 0.35, 0.45),
	"red":    Color(0.45, 0.1, 0.1)
}

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
	tattoo_count_male = _count_existing_tattoos("res://Assets/Resources/textures/MaleCharacter/Tattoos/", "t_male_tattoo_")
	tattoo_count_female = _count_existing_tattoos("res://Assets/Resources/textures/FemaleCharacter/Tattoos/", "t_female_tattoo_")
	
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

	if data.has("tattoo_index"):
		current_tattoo_index = int(data["tattoo_index"])
		update_tattoo_texture()

	if data.has("tattoo_color_id"):
		current_tattoo_color_id = data["tattoo_color_id"]
		update_tattoo_color(current_tattoo_color_id)


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
	
	active_hair_attachment = active_root.get_node_or_null(hair_attachment_path)
	hair_mesh = null
	active_hair_node = null
	beard_mesh = null
	active_beard_node = null
	
	if gender_changed:
		var max_hair = get_hair_count()
		if current_hair_type > max_hair: current_hair_type = 1
		
		var max_beard = get_beard_count()
		if current_beard_type > max_beard: current_beard_type = 1
		
		var max_tattoo = get_tattoo_count()
		if current_tattoo_index > max_tattoo:
			current_tattoo_index = 0

	change_hair_model(current_hair_type)
	change_beard_model(current_beard_type)
	refresh_all_skin_materials()
	
	update_tattoo_texture()
	update_tattoo_color(current_tattoo_color_id)


func _count_existing_tattoos(base_path: String, prefix: String) -> int:
	var count = 0
	var index = 1
	while true:
		var full_path = base_path + prefix + str(index) + ".png"
		if ResourceLoader.exists(full_path):
			count += 1
			index += 1
		else:
			break
	return count

func get_hair_count() -> int:
	return hair_scenes.size() if current_gender == "female" else male_hair_scenes.size()

func get_beard_count() -> int:
	return 0 if current_gender == "female" else male_beard_scenes.size()

func get_tattoo_count() -> int:
	return tattoo_count_male if current_gender == "male" else tattoo_count_female


# --- LOGIKA ZMIANY MODELI ---

func change_hair_model(type_index: int) -> void:
	if not active_hair_attachment: return
	
	for child in active_hair_attachment.get_children():
		if child == active_beard_node and is_instance_valid(active_beard_node): continue 
		child.queue_free()
	
	var scenes_list = hair_scenes if current_gender == "female" else male_hair_scenes
	var array_index = type_index - 1
	
	if scenes_list != null and array_index >= 0 and array_index < scenes_list.size():
		var scene_to_spawn = scenes_list[array_index]
		if scene_to_spawn:
			var new_hair_node = scene_to_spawn.instantiate()
			active_hair_attachment.add_child(new_hair_node)
			active_hair_node = new_hair_node
			
			hair_mesh = _find_mesh_recursive(new_hair_node, "Hair")
			if not hair_mesh: hair_mesh = _find_mesh_recursive(new_hair_node, "")
			
			update_hair_texture()

func change_beard_model(type_index: int) -> void:
	if not active_hair_attachment: return
	
	for child in active_hair_attachment.get_children():
		if child == active_hair_node and is_instance_valid(active_hair_node): continue 
		child.queue_free()
	
	if current_gender == "female": return
	
	var array_index = type_index - 1
	if male_beard_scenes != null and array_index >= 0 and array_index < male_beard_scenes.size():
		var scene_to_spawn = male_beard_scenes[array_index]
		if scene_to_spawn:
			var new_beard_node = scene_to_spawn.instantiate()
			active_hair_attachment.add_child(new_beard_node)
			active_beard_node = new_beard_node
			
			beard_mesh = _find_mesh_recursive(new_beard_node, "Beard")
			if not beard_mesh: beard_mesh = _find_mesh_recursive(new_beard_node, "")
			
			update_beard_texture()

# --- HELPER: WYCIĄGANIE ID Z NAZWY PLIKU ---
func _get_model_id_from_node(node: Node) -> String:
	if not node: return ""
	
	var name_source = node.scene_file_path.get_file()
	if name_source == "":
		name_source = node.name
	
	var regex = RegEx.new()
	regex.compile("(\\d+)")
	var result = regex.search(name_source)
	
	if result:
		return result.get_string()
	return ""

# --- LOGIKA TEKSTUR WŁOSÓW/BRODY (POPRAWIONA) ---

func update_hair_texture() -> void:
	if not hair_mesh: return
	
	# Podstawowa ścieżka zależna od płci
	var base_path = "res://Assets/Resources/textures/FemaleCharacter/Hair/"
	if current_gender == "male":
		base_path = "res://Assets/Resources/textures/MaleCharacter/Hair/"
	
	# 1. Próbujemy pobrać ID z załadowanego modelu
	var model_id = _get_model_id_from_node(active_hair_node)
	
	# 2. Fallback
	if model_id == "":
		model_id = str(current_hair_type)

	# POPRAWKA: Dodanie podfolderu 'HairX' dla postaci męskiej
	if current_gender == "male":
		base_path += "Hair" + model_id + "/"

	var prefix = "t_female_hair" if current_gender == "female" else "t_male_hair"
	var texture_name = prefix + model_id + "_" + current_hair_color + ".png"
	
	_apply_texture_to_mesh(hair_mesh, base_path + texture_name)

func update_beard_texture() -> void:
	if not beard_mesh: return
	var base_path = "res://Assets/Resources/textures/MaleCharacter/Beard/"
	
	# 1. Próbujemy pobrać ID z załadowanego modelu
	var model_id = _get_model_id_from_node(active_beard_node)
	
	# 2. Fallback
	if model_id == "":
		model_id = str(current_beard_type)

	# POPRAWKA: Dodanie podfolderu 'BeardX'
	base_path += "Beard" + model_id + "/"

	var texture_name = "t_male_beard" + model_id + "_" + current_hair_color + ".png"
	_apply_texture_to_mesh(beard_mesh, base_path + texture_name)

# --- UNIWERSALNA FUNKCJA NAKŁADANIA TEKSTURY ---
func _apply_texture_to_mesh(mesh_ref: MeshInstance3D, full_path: String) -> void:
	if ResourceLoader.exists(full_path):
		var new_texture = load(full_path)
		var current_mat = mesh_ref.get_active_material(0)
		
		if current_mat is BaseMaterial3D:
			if mesh_ref.get_surface_override_material(0) == null:
				var mat_copy = current_mat.duplicate()
				mesh_ref.set_surface_override_material(0, mat_copy)
				mat_copy.albedo_texture = new_texture
			else:
				var override = mesh_ref.get_surface_override_material(0)
				if override is BaseMaterial3D:
					override.albedo_texture = new_texture

# --- LOGIKA TATUAŻY ---

func update_tattoo_texture() -> void:
	if current_tattoo_index <= 0:
		_set_tattoo_parameter(null)
		return
	
	var base_path = "res://Assets/Resources/textures/MaleCharacter/Tattoos/" if current_gender == "male" else "res://Assets/Resources/textures/FemaleCharacter/Tattoos/"
	var texture_name = ("t_male_tattoo_" if current_gender == "male" else "t_female_tattoo_") + str(current_tattoo_index) + ".png"
	var full_path = base_path + texture_name
	
	if ResourceLoader.exists(full_path):
		var tex = load(full_path)
		_set_tattoo_parameter(tex)
	else:
		_set_tattoo_parameter(null)

func update_tattoo_color(color_id: String) -> void:
	if not tattoo_palette.has(color_id): return
	var color = tattoo_palette[color_id]
	current_tattoo_color_id = color_id
	
	var body_parts = [torso_mesh, hands_mesh, legs_mesh, feet_mesh] 
	for mesh_inst in body_parts:
		if not mesh_inst: continue
		var count = 1
		if mesh_inst.mesh: count = mesh_inst.mesh.get_surface_count()
		if mesh_inst.get_surface_override_material_count() > 0:
			count = max(count, mesh_inst.get_surface_override_material_count())
		for i in range(count):
			var mat = mesh_inst.get_active_material(i)
			if mat is ShaderMaterial:
				mat.set_shader_parameter("tattoo_color", color)

func _set_tattoo_parameter(tex: Texture2D) -> void:
	var body_parts = [torso_mesh, hands_mesh, legs_mesh, feet_mesh] 
	for mesh_inst in body_parts:
		if not mesh_inst: continue
		var count = 1
		if mesh_inst.mesh: count = mesh_inst.mesh.get_surface_count()
		if mesh_inst.get_surface_override_material_count() > 0:
			count = max(count, mesh_inst.get_surface_override_material_count())
		for i in range(count):
			var mat = mesh_inst.get_active_material(i)
			if mat is ShaderMaterial:
				mat.set_shader_parameter("tattoo_tex", tex)
				mat.set_shader_parameter("tattoo_opacity", 1.0 if tex else 0.0)
	
	update_tattoo_color(current_tattoo_color_id)

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

	update_tattoo_texture()

func _inject_colors_to_mesh(mesh_instance: MeshInstance3D, colors: Dictionary) -> void:
	var count = 1
	if mesh_instance.mesh: count = mesh_instance.mesh.get_surface_count()
	if mesh_instance.get_surface_override_material_count() > 0:
		count = max(count, mesh_instance.get_surface_override_material_count())

	for i in range(count):
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
