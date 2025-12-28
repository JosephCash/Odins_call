extends Node3D

# Referencje do drzewa animacji
@export var animation_tree: AnimationTree 


var state_machine_locomotion: AnimationNodeStateMachinePlayback
var player: CharacterBody3D

# Zmienne fizyki i stanów animacji
var total_speed: float = 0.0
var normalized_horizontal_speed
var moving: bool = false
var grounded: bool = false
var jump_now: bool = false

func _ready():
	# Pobiera referencję do gracza oraz obiekt kontrolujący odtwarzanie animacji (playback)
	player = PlayerManager.player as CharacterBody3D
	state_machine_locomotion = animation_tree.get("parameters/Locomotion/playback") as AnimationNodeStateMachinePlayback

func _physics_process(_delta: float) -> void:
	# Zabezpieczenie: sprawdza czy gracz istnieje, jeśli nie – próbuje go pobrać lub przerywa funkcję
	if player == null:
		player = PlayerManager.player as CharacterBody3D
		if player == null:
			return

	# Oblicza aktualną prędkość gracza i normalizuje ją do zakresu 0-1 dla BlendSpace'a (ignorując oś Y)
	total_speed = player.velocity.length()
	var normalized_horizontal_speed_buffer = inverse_lerp(0.0, 6.0, Vector3(player.velocity.x, 0, player.velocity.z).length())
	normalized_horizontal_speed = clampf(normalized_horizontal_speed_buffer, 0.0, 1.0)
	
	# Jeśli wciśnięto skok i gracz jest na ziemi, wymusza przejście do animacji skoku
	if Input.is_action_just_pressed("jump") and grounded:
		state_machine_locomotion.travel("Female_Animlib_Female_Jump")

	AnimUpdate()

func AnimUpdate():
	if player == null:
		return

	# Aktualizuje flagi stanów (czy na ziemi, czy w ruchu, czy skacze) na podstawie fizyki
	grounded = player.is_on_floor()
	moving = grounded and total_speed > 0.1
	jump_now = Input.is_action_just_pressed("jump") and grounded

	# Przekazuje obliczone warunki i wartości prędkości do parametrów w AnimationTree
	animation_tree.set("parameters/Locomotion/conditions/fall", not grounded and not jump_now)
	animation_tree.set("parameters/Locomotion/conditions/idle_jog", grounded)
	animation_tree.set("parameters/Locomotion/Idle_to_jog/blend_position", normalized_horizontal_speed)
