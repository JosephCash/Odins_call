extends Node3D

# Ścieżki
@export var animation_tree_path: NodePath = ^"../AnimationTree"

var state_machine_locomotion: AnimationNodeStateMachinePlayback
var player: CharacterBody3D

# Zmienne Postaci
var total_speed: float = 0.0
var normalized_horizontal_speed
var moving: bool = false
var grounded: bool = false
var jump_now: bool = false

func _ready():
	player = GameRefs.player as CharacterBody3D
	state_machine_locomotion = %AnimationTree.get("parameters/Locomotion/playback") as AnimationNodeStateMachinePlayback

func _physics_process(_delta: float) -> void:
	if player == null:
		player = GameRefs.player as CharacterBody3D
		if player == null:
			return  # jeszcze nie ma gracza – wyjdź z klatki
	total_speed = player.velocity.length()
	# Normalizowanie prędkości postaci do wartości miedzy 1 a 0
	var normalized_horizontal_speed_buffer = inverse_lerp(0.0, 6.0, Vector3(player.velocity.x, 0, player.velocity.z).length())   # 0..1
	normalized_horizontal_speed = clampf(normalized_horizontal_speed_buffer, 0.0, 1.0)
	
	
	
	if Input.is_action_just_pressed("jump") and grounded:
		state_machine_locomotion.travel("Female_Animlib_Female_Jump")

	AnimUpdate()

func AnimUpdate():
	if player == null:
		return

	grounded = player.is_on_floor()
	moving = grounded and total_speed > 0.1  # mały próg, żeby nie migało przy lądowaniu
	jump_now = Input.is_action_just_pressed("jump") and grounded

	%AnimationTree.set("parameters/Locomotion/conditions/fall", not grounded and not jump_now)
	%AnimationTree.set("parameters/Locomotion/conditions/idle_jog", grounded)
	%AnimationTree.set("parameters/Locomotion/Idle_to_jog/blend_position", normalized_horizontal_speed)
