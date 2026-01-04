extends Node3D

# Referencje do drzewa animacji
@export var animation_tree: AnimationTree 

# --- KONFIGURACJA NAZW WĘZŁÓW (Do ustawienia w Inspektorze) ---
# Nazwa głównego węzła StateMachine (np. "FemaleLocomotion" lub "MaleLocomotion")
@export var locomotion_state_machine_name: String = "FemaleLocomotion" 
# Nazwa węzła BlendSpace1D wewnątrz StateMachine (np. "Idle_to_jog_Female" lub "Idle_to_jog_Male")
@export var blend_space_node_name: String = "Idle_to_jog_Female"
# Nazwa węzła animacji skoku w StateMachine (musi pasować dokładnie do nazwy węzła w grafie)
@export var jump_node_name: String = "Female_Animlib_Female_Jump"
# --------------------------------------------------------------

var state_machine_locomotion: AnimationNodeStateMachinePlayback
var player: CharacterBody3D

# Zmienne fizyki i stanów animacji
var total_speed: float = 0.0
var normalized_horizontal_speed
var moving: bool = false
var grounded: bool = false
var jump_now: bool = false

func _ready():
	# Pobiera referencję do gracza
	player = PlayerManager.player as CharacterBody3D
	
	# Dynamicznie budujemy ścieżkę do playbacku na podstawie nazwy ustawionej w zmiennej export
	# Np. "parameters/FemaleLocomotion/playback"
	var playback_path = "parameters/" + locomotion_state_machine_name + "/playback"
	state_machine_locomotion = animation_tree.get(playback_path) as AnimationNodeStateMachinePlayback

func _physics_process(_delta: float) -> void:
	# Zabezpieczenie: sprawdza czy gracz istnieje
	if player == null:
		player = PlayerManager.player as CharacterBody3D
		if player == null:
			return

	# Oblicza aktualną prędkość gracza i normalizuje ją
	total_speed = player.velocity.length()
	var normalized_horizontal_speed_buffer = inverse_lerp(0.0, 6.0, Vector3(player.velocity.x, 0, player.velocity.z).length())
	normalized_horizontal_speed = clampf(normalized_horizontal_speed_buffer, 0.0, 1.0)
	
	# Jeśli wciśnięto skok i gracz jest na ziemi, wymusza przejście do animacji skoku
	if Input.is_action_just_pressed("jump") and grounded:
		state_machine_locomotion.travel(jump_node_name)

	AnimUpdate()

func AnimUpdate():
	if player == null:
		return

	# Aktualizuje flagi stanów
	grounded = player.is_on_floor()
	moving = grounded and total_speed > 0.1
	jump_now = Input.is_action_just_pressed("jump") and grounded

	# Budujemy prefiks ścieżki, np. "parameters/FemaleLocomotion"
	var path_prefix = "parameters/" + locomotion_state_machine_name
	
	# Ustawiamy warunki w AnimationTree używając dynamicznych ścieżek
	animation_tree.set(path_prefix + "/conditions/fall", not grounded and not jump_now)
	animation_tree.set(path_prefix + "/conditions/idle_jog", grounded)
	
	# Ustawiamy blend position. Pełna ścieżka np.: "parameters/FemaleLocomotion/Idle_to_jog_Female/blend_position"
	var blend_path = path_prefix + "/" + blend_space_node_name + "/blend_position"
	animation_tree.set(blend_path, normalized_horizontal_speed)
