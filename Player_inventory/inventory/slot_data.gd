extends Resource
class_name SlotData

const MAX_STACK_SIZE: int = 64

@export var item_data: ItemData
@export_range(1, MAX_STACK_SIZE) var quantity: int = 1: set = set_quantity

func can_merge_with(other_slot_data: SlotData) -> bool:
	# Sprawdza czy sloty są kompatybilne (ten sam typ, stackowalne i jest miejsce w stosie)
	if not item_data or not other_slot_data.item_data:
		return false

	return item_data == other_slot_data.item_data \
			and item_data.stackable \
			and quantity < MAX_STACK_SIZE

func can_fully_merge_with(other_slot_data: SlotData) -> bool:
	# Sprawdza czy cała zawartość drugiego slotu zmieści się w tym bez przekraczania limitu (64)
	if not item_data or not other_slot_data.item_data:
		return false

	return item_data == other_slot_data.item_data \
			and item_data.stackable \
			and quantity + other_slot_data.quantity <= MAX_STACK_SIZE

func fully_merge_with(other_slot_data: SlotData) -> void:
	# Fizycznie łączy dwa stosy (dodaje ilość z drugiego slotu do obecnego)
	quantity += other_slot_data.quantity

func create_single_slot_data() -> SlotData:
	# Tworzy nowy obiekt slotu z 1 sztuką przedmiotu (do rozdzielania stosu, np. PPM) i odejmuje ją z obecnego
	var new_slot_data = duplicate()
	new_slot_data.quantity = 1
	quantity -= 1
	return new_slot_data

func set_quantity(value: int) -> void:
	# Setter pilnujący logiki: jeśli przedmiot nie jest stackowalny, wymusza ilość na 1 i zgłasza błąd
	quantity = value
	if quantity > 1 and item_data and not item_data.stackable:
		quantity = 1
		push_error("%s is not stackable, setting quantity to 1" % item_data.name)
