extends CharacterBody3D

@export var inventory_data: InventoryData
@export var equip_inventory_head: InventoryDataEquipHead
@export var equip_inventory_torso: InventoryDataEquipTorso
@export var equip_inventory_legs: InventoryDataEquipLegs
@export var equip_inventory_hands: InventoryDataEquipHands
@export var equip_inventory_feet: InventoryDataEquipFeet
@export var equip_inventory_weapon: InventoryDataEquipWeapon
@export var equip_inventory_offhand: InventoryDataEquipOffhand
@export var equip_inventory_trinket1: InventoryDataEquipTrinketOne
@export var equip_inventory_trinket2: InventoryDataEquipTrinketTwo
@export var equip_inventory_trinket3: InventoryDataEquipTrinketThree

signal toggle_inventory()

@onready var interact_ray: RayCast3D = $"../CameraController/InteractRay"
@onready var player: Node3D = $WorldModel/Player

# === STATYSTYKI POSTACI ===
var health: int = 5


# === PARAMETRY RUCHU ===
@export var look_sensitivity := 0.003 # Czułość myszy
@export var jump_velocity := 6.0 # Wysokość skoku
@export var auto_bhop := true # Czy trzymanie spacji pozwala na ciągłe skakanie
@export var walk_speed := 7.0 # Prędkość chodu
@export var ground_accel := 14.0 # Przyspieszenie na ziemi
@export var ground_decel := 10.0 # Opóźnienie na ziemi
@export var ground_friction := 6 # Tarcie na ziemi

@export var air_cap := 0.85 # Maksymalny współczynnik przyspieszenia w powietrzu
@export var air_accel := 800.0 # Przyspieszenie w powietrzu
@export var air_move_speed := 500 # Prędkość ruchu w powietrzu

var wish_dir := Vector3.ZERO # Oczekiwany kierunek poruszania się

# === READY ===
func _ready():
	PlayerManager.player = self
	
	equip_inventory_feet.inventory_updated.connect(_on_feet_inventory_updated)
	equip_inventory_legs.inventory_updated.connect(_on_legs_inventory_updated)
	equip_inventory_torso.inventory_updated.connect(_on_torso_inventory_updated)
	equip_inventory_hands.inventory_updated.connect(_on_hands_inventory_updated)
	equip_inventory_head.inventory_updated.connect(_on_head_inventory_updated)
	
	print("hejka")
# === FUNKCJE POMOCNICZE ===
func get_move_speed() -> float:
	return walk_speed



func clip_velocity(normal: Vector3, overbounce : float, _delta : float) -> void: # Wymagane aby działał surf Identyczne jak w grach SOURCE
	var backoff := self.velocity.dot(normal) * overbounce
	if backoff >= 0: 
		return
	var change := normal * backoff
	self.velocity -= change


func is_surface_too_steep(normal : Vector3) -> bool: # Oblicza nachylenie podłoża
	var max_slope_ang_dot = Vector3(0,1,0).rotated(Vector3(1.0,0,0), self.floor_max_angle).dot(Vector3(0,1,0))
	if normal.dot(Vector3(0,1,0)) < max_slope_ang_dot:
		return true
	return false


func reset_to_spawn():
	self.global_position = %Checkpoint_1.global_position
	self.velocity = Vector3(0, 0, 0)


# === INPUT ===
func _unhandled_input(event): 	# Obsługuje Inputy
	if event.is_action_pressed("reset"):
		reset_to_spawn()
	
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory.emit()
		
	if Input.is_action_just_pressed("interact"):
		interact()



# === FUNKCJE FIZYKI ===

# Symuluje grawitację i ruch w powietrzu z ograniczeniem prędkości, obsługuje odbicie od ścian.
func _handle_air_physics(delta) -> void: 
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)
	var add_speed_till_cap = capped_speed - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = air_accel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir
		
	if is_on_wall():
		if is_surface_too_steep(get_wall_normal()):
			self.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		else:
			self.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
		clip_velocity(get_wall_normal(), 1, delta)


# Realizuje przyspieszanie, opóźnianie i tarcie podczas ruchu na ziemi.
func _handle_ground_physics(delta) -> void:
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var add_speed_till_cap = get_move_speed() - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = ground_accel * delta * get_move_speed()
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir
		
	var control = max(self.velocity.length(), ground_decel)
	var drop = control * ground_friction * delta
	var new_speed = max(self.velocity.length() - drop, 0.0)
	if self.velocity.length() > 0:
		new_speed /= self.velocity.length()
	self.velocity *= new_speed


# === PROCESY ===
func _physics_process(delta: float) -> void:
	# ===== CHODZENIE: kierunek względem kamery =====
	var input_dir: Vector2 = Input.get_vector("move_left","move_right","move_forward","move_back")

	var cam: Camera3D = $"../CameraController/SpringArm3D/Camera3D"
	# Jeśli ścieżka inna – zmień powyżej.
	var cam_basis: Basis = cam.global_transform.basis

	var forward: Vector3 = -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right: Vector3 = cam_basis.x
	right.y = 0.0
	right = right.normalized()

	var move_dir: Vector3 = right * input_dir.x + forward * (-input_dir.y)
	if move_dir.length_squared() > 0.000001:
		move_dir = move_dir.normalized()
	else:
		move_dir = Vector3.ZERO

	wish_dir = move_dir
	
	
	# ===== SKOK + FIZYKA =====
	if is_on_floor():
		if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_pressed("jump")):
			self.velocity.y = jump_velocity
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)



	# ===== ROTACJA: patrz w stronę ruchu =====
	if input_dir != Vector2.ZERO and move_dir != Vector3.ZERO:
		var target_angle: float = atan2((-move_dir.x), (-move_dir.z)) + PI
		var current_angle: float = rotation.y
		rotation.y = lerp_angle(current_angle, target_angle, 15.0 * delta)

	move_and_slide()


func interact() -> void:
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider.has_method("player_interact"):
			collider.player_interact()

func heal(heal_value: int) -> void:
	health += heal_value
	
func _on_feet_inventory_updated(_inv) -> void:
	_update_feet_visual()

#UPDATE MESHY ZBROJI#

func _update_feet_visual() -> void:
	# bierzemy inventory stóp z MainCharacter
	var feet_inventory = equip_inventory_feet

	# zakładam, że jest tylko 1 slot w equip inventory stóp
	var slot_data: SlotData = feet_inventory.slot_datas[0]

	# jeśli w slocie jest item i jest typu ItemDataEquipFeet -> zakładamy go
	if slot_data and slot_data.item_data is ItemDataEquipFeet:
		var item: ItemDataEquipFeet = slot_data.item_data
		player.apply_feet_item(item)
	else:
		# brak itemu w slocie -> wracamy do domyślnego mesha + materiału
		player.apply_feet_item(null)
		
func _on_legs_inventory_updated(_inv) -> void:
	_update_legs_visual()


func _update_legs_visual() -> void:
	var legs_inventory = equip_inventory_legs
	var slot_data: SlotData = legs_inventory.slot_datas[0]

	if slot_data and slot_data.item_data is ItemDataEquipLegs:
		var item: ItemDataEquipLegs = slot_data.item_data
		player.apply_legs_item(item)
	else:
		player.apply_legs_item(null)

func _on_torso_inventory_updated(_inv) -> void:
	_update_torso_visual()


func _update_torso_visual() -> void:
	var torso_inventory = equip_inventory_torso
	var slot_data: SlotData = torso_inventory.slot_datas[0]

	if slot_data and slot_data.item_data is ItemDataEquipTorso:
		var item: ItemDataEquipTorso = slot_data.item_data
		player.apply_torso_item(item)
	else:
		player.apply_torso_item(null)

func _on_hands_inventory_updated(_inv) -> void:
	_update_hands_visual()


func _update_hands_visual() -> void:
	var hands_inventory = equip_inventory_hands
	var slot_data: SlotData = hands_inventory.slot_datas[0]

	if slot_data and slot_data.item_data is ItemDataEquipHands:
		var item: ItemDataEquipHands = slot_data.item_data
		player.apply_hands_item(item)
	else:
		player.apply_hands_item(null)
		

func _on_head_inventory_updated(_inv) -> void:
	_update_head_visual()


func _update_head_visual() -> void:
	var head_inventory = equip_inventory_head
	var slot_data: SlotData = head_inventory.slot_datas[0]

	if slot_data and slot_data.item_data is ItemDataEquipHead:
		var item: ItemDataEquipHead = slot_data.item_data
		player.apply_head_item(item)
	else:
		player.apply_head_item(null)
