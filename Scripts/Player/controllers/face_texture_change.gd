extends Node3D

# --- KONFIGURACJA ŚCIEŻEK ---
@export var face_mesh_path_female: NodePath = ^"../WorldModel/Player/Female_character_skeletalmesh/Armature/Skeleton3D/HeadSlot/Head"
@export var face_mesh_path_male: NodePath = ^"../WorldModel/Player/Male_character_skeletalmesh/Armature/Skeleton3D/HeadSlot/Head"
@export var surface_index: int = 0

# --- TEKSTURY DAMSKIE ---
@export_group("Female Textures")
@export var female_normal_tex: Texture2D
@export var female_closed_eyes_tex: Texture2D

# --- TEKSTURY MĘSKIE ---
@export_group("Male Textures")
@export var male_normal_tex: Texture2D
@export var male_closed_eyes_tex: Texture2D

# --- USTAWIENIA CZASOWE ---
@export var interval: float = 5.0
@export var blink_duration: float = 0.2

# Zmienne wewnętrzne
var face_mesh_female: MeshInstance3D
var face_mesh_male: MeshInstance3D
var current_gender: String = "female"

func _ready():
	# Znajdź oba meshe na starcie
	if has_node(face_mesh_path_female):
		face_mesh_female = get_node(face_mesh_path_female) as MeshInstance3D
	
	if has_node(face_mesh_path_male):
		face_mesh_male = get_node(face_mesh_path_male) as MeshInstance3D

	# Rozpocznij pętlę mrugania
	_blink_loop()

func _blink_loop() -> void:
	# Czekamy na następne mrugnięcie
	await get_tree().create_timer(interval).timeout
	
	# --- KLUCZOWA ZMIANA ---
	# Sprawdzamy, który mesh jest faktycznie widoczny w drzewie sceny.
	# To naprawia problem w kreatorze postaci, gdzie PlayerManager ma stare dane.
	if face_mesh_female and face_mesh_female.is_visible_in_tree():
		current_gender = "female"
	elif face_mesh_male and face_mesh_male.is_visible_in_tree():
		current_gender = "male"
	else:
		# Fallback do Managera (np. w grze FPP, gdy modelu nie widać, ale chcemy mieć poprawne dane)
		var data = PlayerManager.get_appearance_data()
		if data.has("gender"):
			current_gender = data["gender"]
	
	# Zamknij oczy
	_apply_texture_to_active(true)
	
	await get_tree().create_timer(blink_duration).timeout
	
	# Otwórz oczy
	_apply_texture_to_active(false)
	
	# Powtórz pętlę
	_blink_loop()

func _apply_texture_to_active(closed: bool) -> void:
	var target_mesh: MeshInstance3D
	var target_tex: Texture2D
	
	# Wybór mesha i tekstury na podstawie wykrytej płci
	if current_gender == "male":
		target_mesh = face_mesh_male
		target_tex = male_closed_eyes_tex if closed else male_normal_tex
	else:
		target_mesh = face_mesh_female
		target_tex = female_closed_eyes_tex if closed else female_normal_tex
	
	# Aplikacja tekstury
	if target_mesh and target_tex:
		# Pobierz lub stwórz override material
		var mat = target_mesh.get_surface_override_material(surface_index)
		if not mat:
			var base_mat = target_mesh.get_active_material(surface_index)
			if base_mat:
				mat = base_mat.duplicate()
				target_mesh.set_surface_override_material(surface_index, mat)
		
		# Przypisz teksturę do odpowiedniego parametru
		if mat:
			if mat is StandardMaterial3D:
				mat.albedo_texture = target_tex
			elif mat is ShaderMaterial:
				# Dla ShaderMaterial używamy parametru 'texture_albedo' (standard w Godot)
				# Jeśli Twój shader używa innej nazwy (np. 'albedo'), zmień to tutaj!
				mat.set_shader_parameter("texture_albedo", target_tex)
