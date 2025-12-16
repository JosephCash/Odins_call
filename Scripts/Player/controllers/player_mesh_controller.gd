extends Node3D

# --- REFERENCJE DO MESH'Y CZĘŚCI CIAŁA ---
# Przechowujemy referencje do aktywnych MeshInstance3D oraz ich domyślne stany (gdy postać jest naga)
@onready var feet_mesh: MeshInstance3D = $Female_character_skeletalmesh/Armature/Skeleton3D/FeetSlot/Feet
var default_feet_mesh: Mesh
var default_feet_material: Material

@onready var legs_mesh: MeshInstance3D = $Female_character_skeletalmesh/Armature/Skeleton3D/LegsSlot/Legs
var default_legs_mesh: Mesh
var default_legs_material: Material

@onready var torso_mesh: MeshInstance3D = $Female_character_skeletalmesh/Armature/Skeleton3D/TorsoSlot/Torso
var default_torso_mesh: Mesh
var default_torso_material: Material

@onready var hands_mesh: MeshInstance3D = $Female_character_skeletalmesh/Armature/Skeleton3D/HandsSlot/Hands
var default_hands_mesh: Mesh
var default_hands_material: Material

@onready var head_mesh: MeshInstance3D = $Female_character_skeletalmesh/Armature/Skeleton3D/HeadSlot/Head
var default_head_mesh: Mesh
var default_head_material: Material


# --- REFERENCJE DO KREATORA (Twarz i Włosy) ---
@export var face_mesh_ref: MeshInstance3D 
@export var hair_attachment_point: Node3D
@export var hair_scenes: Array[PackedScene]

var hair_mesh: MeshInstance3D 


# --- DANE KOSMETYCZNE ---
var current_hair_type: int = 1 
var current_hair_color: String = "blonde"
var current_skin_id: String = "Default"

# Słownik presetów skóry: definiuje kolory dla cieniowania (Light/Mid/Dark) oraz tint ust
var skin_presets = {
	"Default":   {"light": Color("eba697"), "mid": Color("de9a8f"), "dark": Color("be7e71"), "lips": 0.0},
	"Pale":      {"light": Color("ecc1ba"), "mid": Color("e8b6ac"), "dark": Color("cc9992"), "lips": -0.3},
	"Yellow":    {"light": Color("ecc6ab"), "mid": Color("e8bba0"), "dark": Color("cc9e83"), "lips": -0.1},
	"Tan":       {"light": Color("cc947a"), "mid": Color("bd846b"), "dark": Color("945f4d"), "lips": 0.1},
	"Lightdark": {"light": Color("cc9d8d"), "mid": Color("bf8d7c"), "dark": Color("996b5b"), "lips": 0.1},
	"Dark":      {"light": Color("a17263"), "mid": Color("946354"), "dark": Color("704437"), "lips": 0.2}
}

# Paleta kolorów brwi
var eyebrow_palette = {
	"blonde": Color(0.67, 0.46, 0.34),
	"black": Color(0.12, 0.12, 0.12),
	"brown": Color(0.32, 0.22, 0.15),
	"orange": Color(0.6, 0.25, 0.05),
	"white": Color(0.6, 0.6, 0.6)
}

# Paleta oczu (przesunięcia HSV w shaderze)
var eye_palette = {
	"blue":      {"h": 0.0,   "s": 0.0,   "v": 0.0},
	"green":     {"h": -0.35, "s": 0.2,   "v": -0.1},
	"brown":     {"h": -0.55, "s": -0.03, "v": -0.22},
	"grey":      {"h": 0.0,   "s": -1.0,  "v": -0.1},
	"turquoise": {"h": -0.15, "s": 0.1,   "v": 0.0},
	"orange":    {"h": 0.44,  "s": 0.1,   "v": 0.05}
}


func _ready() -> void:
	# Zapisuje domyślne zasoby (by móc do nich wrócić po zdjęciu zbroi)
	default_feet_mesh = feet_mesh.mesh
	default_feet_material = feet_mesh.get_active_material(0)
	default_legs_mesh = legs_mesh.mesh
	default_legs_material = legs_mesh.get_active_material(0)
	default_torso_mesh = torso_mesh.mesh
	default_torso_material = torso_mesh.get_active_material(0)
	default_hands_mesh = hands_mesh.mesh
	default_hands_material = hands_mesh.get_active_material(0)
	default_head_mesh = head_mesh.mesh
	default_head_material = head_mesh.get_active_material(0)

	# Znajduje mesh włosów w drzewie sceny
	if hair_attachment_point and hair_attachment_point.get_child_count() > 0:
		var current_hair_node = hair_attachment_point.get_child(0)
		hair_mesh = _find_mesh_recursive(current_hair_node, "Hair")

	# Aplikuje zapisany wygląd z globalnego managera
	apply_appearance(PlayerManager.get_appearance_data())


func apply_appearance(data: Dictionary) -> void:
	# Główna funkcja sterująca wyglądem - rozdziela dane na odpowiednie podsystemy
	if data.is_empty(): return

	if data.has("hair_type"):
		var new_type = int(data["hair_type"])
		if new_type != current_hair_type or hair_mesh == null:
			current_hair_type = new_type
			change_hair_model(current_hair_type)

	if data.has("hair_color_id"):
		current_hair_color = data["hair_color_id"]
		update_hair_texture()
		update_eyebrow_color(current_hair_color)
		
	if data.has("eye_color_id"):
		update_eye_color(data["eye_color_id"])
		
	if data.has("skin_id"):
		current_skin_id = data["skin_id"]
		refresh_all_skin_materials()


func change_hair_model(type_index: int) -> void:
	# Usuwa stare włosy i instancjonuje nową scenę fryzury
	if not hair_attachment_point: return
		
	for child in hair_attachment_point.get_children():
		child.queue_free()
	
	var array_index = type_index - 1
	if hair_scenes != null and array_index >= 0 and array_index < hair_scenes.size():
		var scene_to_spawn = hair_scenes[array_index]
		if scene_to_spawn:
			var new_hair_node = scene_to_spawn.instantiate()
			hair_attachment_point.add_child(new_hair_node)
			
			hair_mesh = _find_mesh_recursive(new_hair_node, "Hair")
			if not hair_mesh:
				hair_mesh = _find_mesh_recursive(new_hair_node, "")

func update_hair_texture() -> void:
	# Ładuje teksturę albedo dla włosów na podstawie typu i koloru
	if not hair_mesh: return

	var base_path = "res://Assets/Resources/textures/FemaleCharacter/Hair/"
	var texture_name = "t_female_hair" + str(current_hair_type) + "_" + current_hair_color + ".png"
	var full_path = base_path + texture_name
	
	if ResourceLoader.exists(full_path):
		var new_texture = load(full_path)
		var current_mat = hair_mesh.get_active_material(0) as StandardMaterial3D
		
		# Używa surface_override, aby nie psuć oryginalnego zasobu materiału
		if current_mat:
			if hair_mesh.get_surface_override_material(0) == null:
				var mat_copy = current_mat.duplicate()
				hair_mesh.set_surface_override_material(0, mat_copy)
				mat_copy.albedo_texture = new_texture
			else:
				hair_mesh.get_surface_override_material(0).albedo_texture = new_texture


# --- LOGIKA SKÓRY (SHADER PARAMETERS) ---

func refresh_all_skin_materials() -> void:
	# Przesyła parametry koloru skóry do WSZYSTKICH części ciała
	if not skin_presets.has(current_skin_id):
		current_skin_id = "Default"
	
	var colors = skin_presets[current_skin_id]
	
	if head_mesh: _inject_colors_to_mesh(head_mesh, colors)
	if torso_mesh: _inject_colors_to_mesh(torso_mesh, colors)
	if legs_mesh: _inject_colors_to_mesh(legs_mesh, colors)
	if hands_mesh: _inject_colors_to_mesh(hands_mesh, colors)
	if feet_mesh: _inject_colors_to_mesh(feet_mesh, colors)
	
	if face_mesh_ref: _inject_colors_to_mesh(face_mesh_ref, colors)

func _inject_colors_to_mesh(mesh_instance: MeshInstance3D, colors: Dictionary) -> void:
	# Ustawia parametry shader uniform (skin_light, skin_mid, etc.) dla danego mesha
	var mat_count = mesh_instance.get_surface_override_material_count()
	if mat_count == 0 and mesh_instance.mesh:
		mat_count = mesh_instance.mesh.get_surface_count()
		
	for i in range(mat_count):
		var mat = mesh_instance.get_active_material(i)
		
		if mat is ShaderMaterial:
			mat.set_shader_parameter("skin_light", colors["light"])
			mat.set_shader_parameter("skin_mid",   colors["mid"])
			mat.set_shader_parameter("skin_dark",  colors["dark"])
			
			# Parametr "lips" ustawiamy tylko dla twarzy
			if mesh_instance == face_mesh_ref:
				var lip_val = colors.get("lips", 0.0)
				mat.set_shader_parameter("lip_darkness", lip_val)


# --- LOGIKA TWARZY (SHADER PARAMETERS) ---

func update_eyebrow_color(color_id: String) -> void:
	var target_mesh = head_mesh
	if face_mesh_ref: target_mesh = face_mesh_ref
	if not target_mesh: return
	
	var mat = target_mesh.get_active_material(0)
	if mat is ShaderMaterial and eyebrow_palette.has(color_id):
		mat.set_shader_parameter("new_eyebrow_color", eyebrow_palette[color_id])


func update_eye_color(color_id: String) -> void:
	var target_mesh = head_mesh
	if face_mesh_ref: target_mesh = face_mesh_ref
	if not target_mesh: return
	
	var mat = target_mesh.get_active_material(0)
	if mat is ShaderMaterial and eye_palette.has(color_id):
		var val = eye_palette[color_id]
		mat.set_shader_parameter("eye_hue_shift", val["h"])
		mat.set_shader_parameter("eye_sat_shift", val["s"])
		mat.set_shader_parameter("eye_val_shift", val["v"])


func _find_mesh_recursive(node: Node, target_name_part: String) -> MeshInstance3D:
	if node is MeshInstance3D:
		if target_name_part == "" or node.name.contains(target_name_part):
			return node
	for child in node.get_children():
		var res = _find_mesh_recursive(child, target_name_part)
		if res: return res
	return null


# --- SYSTEM EKWIPUNKU (WIZUALIZACJA) ---
# Każda funkcja podmienia mesh/materiał ALBO wraca do domyślnego, a następnie odświeża kolor skóry

func apply_feet_item(item: ItemDataEquipFeet) -> void:
	if item:
		if item.mesh: feet_mesh.mesh = item.mesh
		else: feet_mesh.mesh = default_feet_mesh
		if item.material: feet_mesh.set_surface_override_material(0, item.material)
		else: feet_mesh.set_surface_override_material(0, default_feet_material)
	else:
		feet_mesh.mesh = default_feet_mesh
		feet_mesh.set_surface_override_material(0, default_feet_material)
	refresh_all_skin_materials() 

func apply_legs_item(item: ItemDataEquipLegs) -> void:
	if item:
		if item.mesh: legs_mesh.mesh = item.mesh
		else: legs_mesh.mesh = default_legs_mesh
		if item.material: legs_mesh.set_surface_override_material(0, item.material)
		else: legs_mesh.set_surface_override_material(0, default_legs_material)
	else:
		legs_mesh.mesh = default_legs_mesh
		legs_mesh.set_surface_override_material(0, default_legs_material)
	refresh_all_skin_materials()

func apply_torso_item(item: ItemDataEquipTorso) -> void:
	if item:
		if item.mesh: torso_mesh.mesh = item.mesh
		else: torso_mesh.mesh = default_torso_mesh
		if item.material: torso_mesh.set_surface_override_material(0, item.material)
		else: torso_mesh.set_surface_override_material(0, default_torso_material)
	else:
		torso_mesh.mesh = default_torso_mesh
		torso_mesh.set_surface_override_material(0, default_torso_material)
	refresh_all_skin_materials()

func apply_hands_item(item: ItemDataEquipHands) -> void:
	if item:
		if item.mesh: hands_mesh.mesh = item.mesh
		else: hands_mesh.mesh = default_hands_mesh
		if item.material: hands_mesh.set_surface_override_material(0, item.material)
		else: hands_mesh.set_surface_override_material(0, default_hands_material)
	else:
		hands_mesh.mesh = default_hands_mesh
		hands_mesh.set_surface_override_material(0, default_hands_material)
	refresh_all_skin_materials()

func apply_head_item(item: ItemDataEquipHead) -> void:
	if item:
		if item.mesh: head_mesh.mesh = item.mesh
		else: head_mesh.mesh = default_head_mesh
		if item.material: head_mesh.set_surface_override_material(0, item.material)
		else: head_mesh.set_surface_override_material(0, default_head_material)
	else:
		head_mesh.mesh = default_head_mesh
		head_mesh.set_surface_override_material(0, default_head_material)
	refresh_all_skin_materials()
