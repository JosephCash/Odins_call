extends InventoryData
class_name InventoryDataEquipTorso

func drop_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	# Sprawdza czy przedmiot to ekwipunek na tułów; jeśli nie – odrzuca go, w przeciwnym razie wywołuje bazową logikę
	if not grabbed_slot_data.item_data is ItemDataEquipTorso:
		return grabbed_slot_data
	
	return super.drop_slot_data(grabbed_slot_data, index)

func drop_single_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	# Uniemożliwia upuszczenie pojedynczego przedmiotu innego typu niż na tułów, przekazując poprawne do klasy rodzica
	if not grabbed_slot_data.item_data is ItemDataEquipTorso:
		return grabbed_slot_data
	
	return super.drop_single_slot_data(grabbed_slot_data, index)
