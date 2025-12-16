extends Resource
class_name ItemData

# Podstawowe właściwości przedmiotu edytowalne w inspektorze (nazwa, opis, czy się stackuje, ikona)
@export var name: String = ""
@export_multiline var description: String = ""
@export var stackable: bool = false
@export var texture: AtlasTexture

func use(target) -> void:
	pass
