extends Node3D

# --- REFERENCJE DO MESHA CIALA ---

# Domyślny mesh + materiał (gołe stopy)
@onready var feet_mesh: MeshInstance3D = $Female_character_skeletalmesh/Armature/Skeleton3D/FeetSlot/Feet
var default_feet_mesh: Mesh
var default_feet_material: Material

# Domyślny mesh + materiał (gołe nogi)
@onready var legs_mesh: MeshInstance3D = $Female_character_skeletalmesh/Armature/Skeleton3D/LegsSlot/Legs
var default_legs_mesh: Mesh
var default_legs_material: Material

# Domyślny mesh + materiał (goły tors)
@onready var torso_mesh: MeshInstance3D = $Female_character_skeletalmesh/Armature/Skeleton3D/TorsoSlot/Torso
var default_torso_mesh: Mesh
var default_torso_material: Material

# Domyślny mesh + materiał (gołe rece)
@onready var hands_mesh: MeshInstance3D = $Female_character_skeletalmesh/Armature/Skeleton3D/HandsSlot/Hands
var default_hands_mesh: Mesh
var default_hands_material: Material

# Domyślny mesh + materiał (goła glowa - to może być sama czaszka, bez twarzy!)
@onready var head_mesh: MeshInstance3D = $Female_character_skeletalmesh/Armature/Skeleton3D/HeadSlot/Head
var default_head_mesh: Mesh
var default_head_material: Material


# --- NOWE REFERENCJE DO KREATORA ---

# 1. TWARZ: Przypisz tutaj obiekt, który ma materiał twarzy (ShaderMaterial)
@export var face_mesh_ref: MeshInstance3D 

# 2. PUNKT ZACZEPIENIA WŁOSÓW (To jest BoneAttachment3D wewnątrz szkieletu)
@export var hair_attachment_point: Node3D

# 3. LISTA SCEN Z WŁOSAMI (Przypisz tutaj pliki .tscn w inspektorze)
@export var hair_scenes: Array[PackedScene]

# Aktualna referencja do mesha włosów (do zmiany koloru) - ustawiana dynamicznie przez skrypt
var hair_mesh: MeshInstance3D 


# --- USTAWIENIA KOSMETYCZNE ---
var current_hair_type: int = 1 
var current_hair_color: String = "blonde"

# PALETA KOLORÓW BRWI
var eyebrow_palette = {
	"blonde": Color(0.67, 0.46, 0.34),
	"black": Color(0.12, 0.12, 0.12),
	"brown": Color(0.32, 0.22, 0.15),
	"orange": Color(0.6, 0.25, 0.05),
	"white": Color(0.6, 0.6, 0.6)
}

func _ready() -> void:
	# Inicjalizacja domyślnych części ciała
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

	# Znajdź istniejące włosy na starcie (jeśli są już w scenie jako dziecko BoneAttachment3D)
	if hair_attachment_point and hair_attachment_point.get_child_count() > 0:
		var current_hair_node = hair_attachment_point.get_child(0)
		hair_mesh = _find_mesh_recursive(current_hair_node, "Hair")

	# Aplikacja wyglądu startowego
	apply_appearance(PlayerManager.get_appearance_data())


# --- GŁÓWNA FUNKCJA KREATORA ---

func apply_appearance(data: Dictionary) -> void:
	if data.is_empty():
		return

	# 1. Zmiana MODELU włosów (musi być pierwsza, żeby znaleźć nowy mesh dla zmiany koloru)
	if data.has("hair_type"):
		var new_type = int(data["hair_type"])
		# Zmieniamy model jeśli typ jest inny LUB jeśli nie mamy przypisanego mesha (np. start gry)
		if new_type != current_hair_type or hair_mesh == null:
			current_hair_type = new_type
			change_hair_model(current_hair_type)

	# 2. Zmiana KOLORU włosów i brwi
	if data.has("hair_color_id"):
		current_hair_color = data["hair_color_id"]
		
		# Aplikuj zmiany
		update_hair_texture()
		update_eyebrow_color(current_hair_color)


func change_hair_model(type_index: int) -> void:
	if not hair_attachment_point:
		print("BŁĄD: Nie przypisano hair_attachment_point w inspektorze!")
		return
		
	# Usuń stare włosy (wszystkie dzieci punktu zaczepienia)
	for child in hair_attachment_point.get_children():
		child.queue_free()
	
	# Tablice są indeksowane od 0, a typy włosów numerujemy od 1.
	var array_index = type_index - 1
	
	if hair_scenes != null and array_index >= 0 and array_index < hair_scenes.size():
		var scene_to_spawn = hair_scenes[array_index]
		if scene_to_spawn:
			var new_hair_node = scene_to_spawn.instantiate()
			hair_attachment_point.add_child(new_hair_node)
			
			# Znajdź MeshInstance3D w nowej scenie, żeby móc zmieniać kolor
			# Szukamy rekurencyjnie noda, który ma w nazwie "Hair"
			hair_mesh = _find_mesh_recursive(new_hair_node, "Hair")
			
			# Fallback: jeśli nie znaleziono po nazwie, weź pierwszy lepszy MeshInstance3D
			if not hair_mesh:
				hair_mesh = _find_mesh_recursive(new_hair_node, "")
			
			print("Zmieniono model włosów na typ: ", type_index)
		else:
			print("BŁĄD: Pusta scena w tablicy hair_scenes pod indeksem ", array_index)
	else:
		print("BŁĄD: Nieprawidłowy indeks włosów: ", type_index, " (Dostępne: ", hair_scenes.size(), ")")


func update_hair_texture() -> void:
	if not hair_mesh: 
		# print("Brak hair_mesh do zmiany koloru") 
		return

	# Budowanie ścieżki do tekstury włosów
	# Np. t_female_hair1_blonde.png
	var base_path = "res://Assets/Resources/textures/FemaleCharacter/Hair/"
	var texture_name = "t_female_hair" + str(current_hair_type) + "_" + current_hair_color + ".png"
	var full_path = base_path + texture_name
	
	if ResourceLoader.exists(full_path):
		var new_texture = load(full_path)
		var current_mat = hair_mesh.get_active_material(0) as StandardMaterial3D
		
		# Używamy override material, aby nie zmieniać oryginalnego zasobu na dysku
		if current_mat:
			# Jeśli nie mamy jeszcze override'a, tworzymy go na bazie oryginału
			if hair_mesh.get_surface_override_material(0) == null:
				var mat_copy = current_mat.duplicate()
				hair_mesh.set_surface_override_material(0, mat_copy)
				mat_copy.albedo_texture = new_texture
			else:
				# Jeśli już mamy override, edytujemy go
				hair_mesh.get_surface_override_material(0).albedo_texture = new_texture
	else:
		print("Błąd: Brak tekstury włosów: ", full_path)


func update_eyebrow_color(color_id: String) -> void:
	# 1. Wybór mesha: Używamy face_mesh_ref jeśli przypisany, w przeciwnym razie head_mesh
	var target_mesh = head_mesh
	if face_mesh_ref:
		target_mesh = face_mesh_ref
	
	if not target_mesh:
		return
	
	# 2. Pobieramy materiał
	var mat = target_mesh.get_active_material(0)
	
	if mat == null or not (mat is ShaderMaterial):
		return

	# 3. Zmiana koloru w shaderze
	if eyebrow_palette.has(color_id):
		var new_col = eyebrow_palette[color_id]
		mat.set_shader_parameter("new_eyebrow_color", new_col)


# Funkcja pomocnicza do szukania mesha wewnątrz instancjonowanej sceny
func _find_mesh_recursive(node: Node, target_name_part: String) -> MeshInstance3D:
	if node is MeshInstance3D:
		# Jeśli target_name_part jest pusty, zwracamy pierwszy znaleziony mesh
		# Jeśli nie jest pusty, sprawdzamy czy nazwa zawiera ten ciąg
		if target_name_part == "" or node.name.contains(target_name_part):
			return node
	
	for child in node.get_children():
		var result = _find_mesh_recursive(child, target_name_part)
		if result:
			return result
	return null


# --- EKWIPUNEK (STANDARDOWY KOD) ---

func apply_feet_item(item: ItemDataEquipFeet) -> void:
	if item:
		if item.mesh: feet_mesh.mesh = item.mesh
		else: feet_mesh.mesh = default_feet_mesh
		if item.material: feet_mesh.set_surface_override_material(0, item.material)
		else: feet_mesh.set_surface_override_material(0, default_feet_material)
	else:
		feet_mesh.mesh = default_feet_mesh
		feet_mesh.set_surface_override_material(0, default_feet_material)
		
func apply_legs_item(item: ItemDataEquipLegs) -> void:
	if item:
		if item.mesh: legs_mesh.mesh = item.mesh
		else: legs_mesh.mesh = default_legs_mesh
		if item.material: legs_mesh.set_surface_override_material(0, item.material)
		else: legs_mesh.set_surface_override_material(0, default_legs_material)
	else:
		legs_mesh.mesh = default_legs_mesh
		legs_mesh.set_surface_override_material(0, default_legs_material)
		
func apply_torso_item(item: ItemDataEquipTorso) -> void:
	if item:
		if item.mesh: torso_mesh.mesh = item.mesh
		else: torso_mesh.mesh = default_torso_mesh
		if item.material: torso_mesh.set_surface_override_material(0, item.material)
		else: torso_mesh.set_surface_override_material(0, default_torso_material)
	else:
		torso_mesh.mesh = default_torso_mesh
		torso_mesh.set_surface_override_material(0, default_torso_material)
		
func apply_hands_item(item: ItemDataEquipHands) -> void:
	if item:
		if item.mesh: hands_mesh.mesh = item.mesh
		else: hands_mesh.mesh = default_hands_mesh
		if item.material: hands_mesh.set_surface_override_material(0, item.material)
		else: hands_mesh.set_surface_override_material(0, default_hands_material)
	else:
		hands_mesh.mesh = default_hands_mesh
		hands_mesh.set_surface_override_material(0, default_hands_material)

func apply_head_item(item: ItemDataEquipHead) -> void:
	if item:
		if item.mesh: head_mesh.mesh = item.mesh
		else: head_mesh.mesh = default_head_mesh
		if item.material: head_mesh.set_surface_override_material(0, item.material)
		else: head_mesh.set_surface_override_material(0, default_head_material)
	else:
		head_mesh.mesh = default_head_mesh
		head_mesh.set_surface_override_material(0, default_head_material)
