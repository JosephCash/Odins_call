extends Node3D

# Konfiguracja ścieżek, tekstur oczu oraz interwałów czasowych mrugania
@export var face_mesh_path: NodePath = ^"Face"
@export var surface_index: int = 0
@export var normal_tex: Texture2D
@export var closed_eyes_tex: Texture2D
@export var interval: float = 5.0
@export var blink_duration: float = 0.2

# Przechowuje referencje do obiektu mesha i jego unikalnej instancji materiału
var face_mesh: MeshInstance3D
var mat: Material

func _ready():
	# Próbuje pobrać węzeł mesha ze ścieżki lub szuka dziecka o nazwie "Face" jako fallback
	if has_node(face_mesh_path):
		face_mesh = get_node(face_mesh_path) as MeshInstance3D
	else:
		face_mesh = find_child("Face", true)
		if not face_mesh:
			print("BŁĄD: Nie znaleziono mesha twarzy w face_texture_change.gd")
			return

	# Pobiera i duplikuje materiał, aby mruganie jednej postaci nie wpływało na inne (unikalność)
	var base_mat = face_mesh.get_active_material(surface_index)
	
	if base_mat:
		mat = base_mat.duplicate()
		face_mesh.set_surface_override_material(surface_index, mat)
		
		# Jeśli brak przypisanej tekstury, automatycznie pobiera ją z materiału (obsługuje Standard i Shader)
		if normal_tex == null:
			if mat is StandardMaterial3D:
				normal_tex = mat.albedo_texture
			elif mat is ShaderMaterial:
				normal_tex = mat.get_shader_parameter("texture_albedo")
	else:
		print("BŁĄD: Mesh twarzy nie ma przypisanego materiału!")
		return

	_blink_loop()

func _blink_loop() -> void:
	# Cykliczna pętla: czeka interwał, zamyka oczy, czeka czas mrugnięcia, otwiera oczy i powtarza
	await get_tree().create_timer(interval).timeout
	_set_texture(closed_eyes_tex)
	await get_tree().create_timer(blink_duration).timeout
	_set_texture(normal_tex)
	_blink_loop()

func _set_texture(tex: Texture2D) -> void:
	# Przypisuje teksturę do odpowiedniego parametru w zależności od typu materiału (Standard/Shader)
	if not mat or not tex:
		return
		
	if mat is StandardMaterial3D:
		mat.albedo_texture = tex
	elif mat is ShaderMaterial:
		mat.set_shader_parameter("texture_albedo", tex)
