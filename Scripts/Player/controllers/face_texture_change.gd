extends Node3D

@export var face_mesh_path: NodePath = ^"Face"   # MeshInstance3D twarzy
@export var surface_index: int = 0               # który surface
@export var normal_tex: Texture2D                # t_female_face_normal
@export var closed_eyes_tex: Texture2D           # t_female_face_closedeyes
@export var interval: float = 5.0
@export var blink_duration: float = 0.2

var face_mesh: MeshInstance3D
var mat: StandardMaterial3D

func _ready():
	face_mesh = get_node(face_mesh_path) as MeshInstance3D

	# weź materiał aktywny na danym surface i sklonuj, potem włóż do Surface Override
	var base_mat := face_mesh.get_active_material(surface_index) as StandardMaterial3D
	if base_mat == null:
		base_mat = StandardMaterial3D.new()
	mat = base_mat.duplicate() as StandardMaterial3D
	face_mesh.set_surface_override_material(surface_index, mat)

	# jeśli nie podano normal_tex, użyj tej z materiału
	if normal_tex == null:
		normal_tex = mat.albedo_texture

	_blink_loop()

func _blink_loop() -> void:
	await get_tree().create_timer(interval).timeout
	mat.albedo_texture = closed_eyes_tex
	await get_tree().create_timer(blink_duration).timeout
	mat.albedo_texture = normal_tex
	_blink_loop()
