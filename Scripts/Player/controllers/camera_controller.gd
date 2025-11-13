extends Node3D

@export var mouse_sensitivity := 1.0

# --- USTAWIENIA ZOOMU ---
@export var zoom_min := 1.0
@export var zoom_max := 8.0
@export var zoom_step := 0.5

var player_head

func _ready():
	player_head = $"../MainCharacter"/Head
	
func _physics_process(_delta):
	self.global_position = player_head.global_position

func _unhandled_input(event):
	# Mouse mode zarządzany przez Main.gd (toggle_inventory_interface)
	# Rotacja kamery działa tylko gdy mysz jest przechwycona
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			var temp_rotation = self.rotation.x - event.relative.y / 1000 * mouse_sensitivity
			self.rotation.y -= event.relative.x / 1000 * mouse_sensitivity
			temp_rotation = clamp(temp_rotation, deg_to_rad(-90), deg_to_rad(60))
			self.rotation.x = temp_rotation

	# --- ZOOM NA GOTOWYCH AKCJACH ---
	if event.is_action_pressed("CameraZoomIn"):
		$SpringArm3D.spring_length = clamp($SpringArm3D.spring_length - zoom_step, zoom_min, zoom_max)
	elif event.is_action_pressed("CameraZoomOut"):
		$SpringArm3D.spring_length = clamp($SpringArm3D.spring_length + zoom_step, zoom_min, zoom_max)
