extends PanelContainer

# Referencje do elementów UI wyświetlających ikonę i ilość przedmiotu
@onready var texture_rect: TextureRect = $MarginContainer/TextureRect
@onready var quantity_label: Label = $QuantityLabel

signal slot_clicked(index: int, button: int)

func set_slot_data(slot_data: SlotData) -> void:
	# Pobiera dane przedmiotu i ustawia jego ikonę oraz opis (tooltip)
	var item_data = slot_data.item_data
	texture_rect.texture = item_data.texture
	tooltip_text = "%s\n%s" % [item_data.name, item_data.description]
	
	# Pokazuje licznik ilości tylko jeśli przedmiotów jest więcej niż 1 (stos)
	if slot_data.quantity > 1:
		quantity_label.text = "x%s" % slot_data.quantity
		quantity_label.show()
	else:
		quantity_label.hide()

func _on_gui_input(event: InputEvent) -> void:
	# Obsługuje kliknięcia myszą (LPM/PPM) i emituje sygnał do nadrzędnego systemu
	if event is InputEventMouseButton \
			and (event.button_index == MOUSE_BUTTON_LEFT \
			or event.button_index == MOUSE_BUTTON_RIGHT) \
			and event.is_pressed():
		slot_clicked.emit(get_index(), event.button_index)
