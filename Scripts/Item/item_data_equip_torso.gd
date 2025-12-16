extends ItemData
class_name ItemDataEquipTorso

# Zasoby wizualne (siatka 3D i materiał) używane do wyświetlania przedmiotu na modelu postaci
@export var mesh: Mesh
@export var material: Material

# Statystyka rozgrywki określająca wartość obrony zapewnianą przez ten przedmiot
@export var defence: int
