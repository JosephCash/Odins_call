extends Camera3D

# --- USTAWIENIA POZYCJI ---
# Możesz ustawić te wektory ręcznie w Inspektorze, klikając na kamerę
@export_group("Camera Positions")
@export var female_position: Vector3
@export var male_position: Vector3

# Domyślny offset, jeśli zapomnisz ustawić male_position (np. 15 cm w górę)
@export var default_height_offset: float = 0.15 
@export var transition_time: float = 0.5 # Czas trwania ruchu w sekundach

func _ready() -> void:
	# Jeśli w inspektorze zostawisz wektory jako (0,0,0), skrypt sam ustawi domyślne wartości
	# Zakładamy, że obecna pozycja kamery w edytorze to pozycja dla KOBIETY
	if female_position == Vector3.ZERO:
		female_position = position
	
	if male_position == Vector3.ZERO:
		male_position = female_position + Vector3(0, default_height_offset, 0)

# Funkcja wywoływana przez CharacterCreator.gd
func move_to_gender(gender: String) -> void:
	var target_pos = female_position
	
	if gender == "male":
		target_pos = male_position
	
	# Używamy Tween, żeby ruch był płynny, a nie "skokowy"
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE) # Typ ruchu (gładki start i stop)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target_pos, transition_time)
