extends InventoryData
class_name InventoryDataEquipWeapon

func drop_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	# Sprawdza czy przedmiot to broń; jeśli nie – odrzuca go, w przeciwnym razie wywołuje bazową logikę
	if not grabbed_slot_data.item_data is ItemDataEquipWeapon:
		return grabbed_slot_data
	
	return super.drop_slot_data(grabbed_slot_data, index)

func drop_single_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	# Uniemożliwia upuszczenie pojedynczego przedmiotu innego typu niż broń, przekazując poprawne do klasy rodzica
	if not grabbed_slot_data.item_data is ItemDataEquipWeapon:
		return grabbed_slot_data
	
	return super.drop_single_slot_data(grabbed_slot_data, index)
