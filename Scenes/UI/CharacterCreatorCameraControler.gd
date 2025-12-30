extends Camera3D

# --- USTAWIENIA POZYCJI CIAŁA (ODDALONA) ---
@export_group("Body Positions (Zoom Out)")
@export var female_position: Vector3 
@export var male_position: Vector3   

# --- USTAWIENIA POZYCJI TWARZY (ZBLIŻENIE) ---
@export_group("Face Positions (Zoom In)")
@export var female_face_position: Vector3 
@export var male_face_position: Vector3   

@export_group("Settings")
@export var default_height_offset: float = 0.15 

# --- ZMIANA PRĘDKOŚCI ---
# Było 0.5, teraz 0.3 sekundy. Zmniejsz tę wartość, by było jeszcze szybciej.
@export var transition_time: float = 0.3 

# Zmienne stanu
var current_gender: String = "female"
var is_zoomed_in: bool = false 
var tween: Tween

func _ready() -> void:
	# 1. Konfiguracja domyślnych pozycji "Body"
	if female_position == Vector3.ZERO:
		female_position = position
	
	if male_position == Vector3.ZERO:
		male_position = female_position + Vector3(0, default_height_offset, 0)
		
	# 2. Konfiguracja domyślnych pozycji "Face"
	if female_face_position == Vector3.ZERO:
		female_face_position = female_position + Vector3(0, 0.4, -1.0)
		
	if male_face_position == Vector3.ZERO:
		male_face_position = male_position + Vector3(0, 0.45, -1.0)

	# Startujemy w pozycji oddalonej
	_update_camera_position()

# Obsługa wejścia (Scroll Myszki)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# Scroll w GÓRĘ -> Zbliżenie (Zoom In)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			if not is_zoomed_in:
				is_zoomed_in = true
				_update_camera_position()
				
		# Scroll w DÓŁ -> Oddalenie (Zoom Out)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			if is_zoomed_in:
				is_zoomed_in = false
				_update_camera_position()

# Funkcja wywoływana przez CharacterCreator (zmiana płci)
func move_to_gender(gender: String) -> void:
	if gender != "female" and gender != "male": return
	
	current_gender = gender
	# Aktualizujemy pozycję, zachowując stan zoomu (blisko/daleko)
	_update_camera_position()

# Centralna funkcja ruchu
func _update_camera_position() -> void:
	var target_pos = Vector3.ZERO
	
	# Wybór celu na podstawie PŁCI i ZOOMU
	if current_gender == "female":
		target_pos = female_face_position if is_zoomed_in else female_position
	else: # male
		target_pos = male_face_position if is_zoomed_in else male_position

	# Reset poprzedniego ruchu
	if tween and tween.is_running():
		tween.kill()
	
	# Nowy ruch z nową prędkością (transition_time)
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target_pos, transition_time)
