extends ItemData
class_name ItemDataConsumable

# Wartość leczenia edytowalna w inspektorze (ile punktów życia przywraca przedmiot)
@export var heal_value: int

func use(target) -> void:
	# Nadpisuje funkcję użycia: jeśli zdefiniowano wartość leczenia, wywołuje metodę heal na celu
	if heal_value != 0:
		target.heal(heal_value)
