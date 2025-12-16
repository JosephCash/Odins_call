extends Resource
class_name InventoryData

# Sygnały informujące o zmianach w ekwipunku oraz o interakcji ze slotem
signal inventory_updated(inventory_data: InventoryData)
signal inventory_interact(inventory_data: InventoryData, index: int, button: int)

# Główna tablica przechowująca dane przedmiotów w poszczególnych slotach
@export var slot_datas: Array[SlotData]

func grab_slot_data(index: int) -> SlotData:
	# Zabiera przedmiot ze wskazanego slotu, zeruje go i zwraca dane (np. do kursora myszy)
	var slot_data = slot_datas[index]
	
	if slot_data:
		slot_datas[index] = null
		inventory_updated.emit(self)
		return slot_data
	else:
		return null
		
func drop_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	# Próbuje połączyć upuszczany przedmiot z obecnym w slocie lub zamienia je miejscami, jeśli łączenie niemożliwe
	var slot_data = slot_datas[index]

	var return_slot_data: SlotData
	if slot_data and slot_data.can_fully_merge_with(grabbed_slot_data):
		slot_data.fully_merge_with(grabbed_slot_data)
	else:
		slot_datas[index] = grabbed_slot_data
		return_slot_data = slot_data

	inventory_updated.emit(self)
	return return_slot_data

func drop_single_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	# Upuszcza pojedynczą sztukę przedmiotu do slotu (tworząc nowy stos lub dodając do istniejącego)
	var slot_data = slot_datas[index]

	if not slot_data:
		slot_datas[index] = grabbed_slot_data.create_single_slot_data()
	elif slot_data.can_merge_with(grabbed_slot_data):
		slot_data.fully_merge_with(grabbed_slot_data.create_single_slot_data())

	inventory_updated.emit(self)

	# Zwraca resztę trzymanego stosu (jeśli coś zostało) lub null
	if grabbed_slot_data.quantity > 0:
		return grabbed_slot_data
	else:
		return null

func use_slot_data(index: int) -> void:
	# Obsługuje użycie przedmiotu: zmniejsza ilość (jeśli konsumowalny), loguje nazwę i wywołuje efekt
	var slot_data = slot_datas[index]
	
	if not slot_data:
		return
		
	if slot_data.item_data is ItemDataConsumable:
		slot_data.quantity -= 1
		if slot_data.quantity < 1:
			slot_datas[index] = null
	
	# Logika debugowania wypisująca nazwę skryptu/typu przedmiotu do konsoli
	var script_path = slot_data.item_data.get_script().resource_path
	var script_name = script_path.get_file() 
	script_name = script_name.trim_suffix(".gd")
	script_name = script_name.replace("item_data_", "") 
	script_name = script_name.replace("Item_data_", "") 
	script_name = script_name.replace("_", " ")
	print(script_name)

	PlayerManager.use_slot_data(slot_data)
	
	inventory_updated.emit(self)

func on_slot_clicked(index: int, button: int) -> void:
	# Przekazuje zdarzenie kliknięcia na slocie wyżej (do kontrolera interfejsu)
	inventory_interact.emit(self, index, button)
