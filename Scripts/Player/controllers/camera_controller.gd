extends Node3D

# Parametry konfiguracyjne czułości myszy oraz zakresu i skoku zoomu
@export var mouse_sensitivity := 1.0
@export var zoom_min := 1.0
@export var zoom_max := 8.0
@export var zoom_step := 0.5

var player_head

func _ready():
	# Pobiera referencję do węzła głowy gracza, za którym kamera ma podążać
	player_head = $"../MainCharacter"/Head
	
func _physics_process(_delta):
	# Synchronizuje pozycję całego rigu kamery z pozycją głowy gracza w każdej klatce fizyki
	self.global_position = player_head.global_position

func _unhandled_input(event):
	# Obsługuje obrót kamery myszką (tylko gdy kursor jest przechwycony), ograniczając kąt w pionie
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			var temp_rotation = self.rotation.x - event.relative.y / 1000 * mouse_sensitivity
			self.rotation.y -= event.relative.x / 1000 * mouse_sensitivity
			temp_rotation = clamp(temp_rotation, deg_to_rad(-90), deg_to_rad(60))
			self.rotation.x = temp_rotation

	# Obsługuje przybliżanie i oddalanie widoku (zoom) poprzez zmianę długości ramienia w określonym zakresie
	if event.is_action_pressed("CameraZoomIn"):
		$SpringArm3D.spring_length = clamp($SpringArm3D.spring_length - zoom_step, zoom_min, zoom_max)
	elif event.is_action_pressed("CameraZoomOut"):
		$SpringArm3D.spring_length = clamp($SpringArm3D.spring_length + zoom_step, zoom_min, zoom_max)
