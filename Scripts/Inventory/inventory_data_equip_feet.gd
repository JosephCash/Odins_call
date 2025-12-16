extends InventoryData
class_name InventoryDataEquipFeet

func drop_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	# Sprawdza czy przedmiot to obuwie; jeśli nie – zwraca go (odrzuca), jeśli tak – wywołuje logikę bazową
	if not grabbed_slot_data.item_data is ItemDataEquipFeet:
		return grabbed_slot_data
	
	return super.drop_slot_data(grabbed_slot_data, index)

func drop_single_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	# Blokuje upuszczenie pojedynczego przedmiotu jeśli nie pasuje typem (stopy), inaczej przekazuje do rodzica
	if not grabbed_slot_data.item_data is ItemDataEquipFeet:
		return grabbed_slot_data
	
	return super.drop_single_slot_data(grabbed_slot_data, index)
