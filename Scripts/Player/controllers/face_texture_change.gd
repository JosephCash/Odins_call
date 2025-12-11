extends Node3D

@export var face_mesh_path: NodePath = ^"Face"   # Ścieżka do Mesha twarzy
@export var surface_index: int = 0               # Index powierzchni (zazwyczaj 0)
@export var normal_tex: Texture2D                # Tekstura otwartych oczu
@export var closed_eyes_tex: Texture2D           # Tekstura zamkniętych oczu
@export var interval: float = 5.0                # Co ile mrugać
@export var blink_duration: float = 0.2          # Jak długo oczy są zamknięte

var face_mesh: MeshInstance3D
var mat: Material # ZMIANA: Używamy ogólnego typu Material, nie StandardMaterial3D

func _ready():
	if has_node(face_mesh_path):
		face_mesh = get_node(face_mesh_path) as MeshInstance3D
	else:
		# Fallback: spróbuj znaleźć dziecko o nazwie "Face" lub podobnej
		face_mesh = find_child("Face", true)
		if not face_mesh:
			print("BŁĄD: Nie znaleziono mesha twarzy w face_texture_change.gd")
			return

	# Pobieramy aktywny materiał (czy to Shader, czy Standard)
	var base_mat = face_mesh.get_active_material(surface_index)
	
	if base_mat:
		# Duplikujemy materiał, żeby mruganie jednej postaci nie wpływało na inne
		mat = base_mat.duplicate()
		face_mesh.set_surface_override_material(surface_index, mat)
		
		# Jeśli nie przypisałeś tekstury "normal_tex" w inspektorze, spróbujmy ją pobrać z materiału
		if normal_tex == null:
			if mat is StandardMaterial3D:
				normal_tex = mat.albedo_texture
			elif mat is ShaderMaterial:
				# UWAGA: W shaderze parametr nazywa się zazwyczaj "texture_albedo"
				normal_tex = mat.get_shader_parameter("texture_albedo")
	else:
		print("BŁĄD: Mesh twarzy nie ma przypisanego materiału!")
		return

	_blink_loop()

func _blink_loop() -> void:
	await get_tree().create_timer(interval).timeout
	_set_texture(closed_eyes_tex)
	await get_tree().create_timer(blink_duration).timeout
	_set_texture(normal_tex)
	_blink_loop()

# Funkcja pomocnicza, która wie jak ustawić teksturę w zależności od typu materiału
func _set_texture(tex: Texture2D) -> void:
	if not mat or not tex:
		return
		
	if mat is StandardMaterial3D:
		mat.albedo_texture = tex
	elif mat is ShaderMaterial:
		# Tutaj kluczowa poprawka: nazwa parametru w shaderze to "texture_albedo"
		mat.set_shader_parameter("texture_albedo", tex)
