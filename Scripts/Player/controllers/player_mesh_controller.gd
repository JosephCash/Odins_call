extends Node3D

# --- REFERENCJE DO MESHA CIALA ---

# Domyślny mesh + materiał (gołe stopy)
@onready var feet_mesh: MeshInstance3D = $Female_character_skeletalmesh/Armature/Skeleton3D/FeetSlot/Feet
var default_feet_mesh: Mesh
var default_feet_material: Material

# Domyślny mesh + materiał (gołe nogi)
@onready var legs_mesh: MeshInstance3D = $Female_character_skeletalmesh/Armature/Skeleton3D/LegsSlot/Legs
var default_legs_mesh: Mesh
var default_legs_material: Material

# Domyślny mesh + materiał (goły tors)
@onready var torso_mesh: MeshInstance3D = $Female_character_skeletalmesh/Armature/Skeleton3D/TorsoSlot/Torso
var default_torso_mesh: Mesh
var default_torso_material: Material

# Domyślny mesh + materiał (gołe rece)
@onready var hands_mesh: MeshInstance3D = $Female_character_skeletalmesh/Armature/Skeleton3D/HandsSlot/Hands
var default_hands_mesh: Mesh
var default_hands_material: Material

# Domyślny mesh + materiał (goła glowa)
@onready var head_mesh: MeshInstance3D = $Female_character_skeletalmesh/Armature/Skeleton3D/HeadSlot/Head
var default_head_mesh: Mesh
var default_head_material: Material



func _ready() -> void:
	#Stopy
	default_feet_mesh = feet_mesh.mesh
	default_feet_material = feet_mesh.get_active_material(0)
	
	#Nogi
	default_legs_mesh = legs_mesh.mesh
	default_legs_material = legs_mesh.get_active_material(0)

	#Torso
	default_torso_mesh = torso_mesh.mesh
	default_torso_material = torso_mesh.get_active_material(0)
	
	#Rece
	default_hands_mesh = hands_mesh.mesh
	default_hands_material = hands_mesh.get_active_material(0)
	
	#Glowa
	default_head_mesh = head_mesh.mesh
	default_head_material = head_mesh.get_active_material(0)
	
# --- FUNKCJA, KTÓRĄ PÓŹNIEJ BĘDZIE WOŁAŁ INVENTORY ---

func apply_feet_item(item: ItemDataEquipFeet) -> void:
	if item:
		# jeśli item ma własny mesh, użyj go, inaczej zostaw domyślny
		if item.mesh:
			feet_mesh.mesh = item.mesh
		else:
			feet_mesh.mesh = default_feet_mesh

		# jeśli item ma własny materiał, użyj go, inaczej domyślny
		if item.material:
			feet_mesh.set_surface_override_material(0, item.material)
		else:
			feet_mesh.set_surface_override_material(0, default_feet_material)
	else:
		# brak itemu w slocie -> wracamy do "gołych" stóp
		feet_mesh.mesh = default_feet_mesh
		feet_mesh.set_surface_override_material(0, default_feet_material)
		
func apply_legs_item(item: ItemDataEquipLegs) -> void:
	if item:
		# jeśli item ma własny mesh, użyj go; inaczej domyślne nogi
		if item.mesh:
			legs_mesh.mesh = item.mesh
		else:
			legs_mesh.mesh = default_legs_mesh

		# jeśli item ma własny materiał, użyj go; inaczej domyślny
		if item.material:
			legs_mesh.set_surface_override_material(0, item.material)
		else:
			legs_mesh.set_surface_override_material(0, default_legs_material)
	else:
		# brak itemu w slocie -> wracamy do domyślnego mesha + materiału
		legs_mesh.mesh = default_legs_mesh
		legs_mesh.set_surface_override_material(0, default_legs_material)
		
func apply_torso_item(item: ItemDataEquipTorso) -> void:
	if item:
		# jeśli item ma własny mesh, użyj go; inaczej domyślny tors
		if item.mesh:
			torso_mesh.mesh = item.mesh
		else:
			torso_mesh.mesh = default_torso_mesh

		# jeśli item ma własny materiał, użyj go; inaczej domyślny
		if item.material:
			torso_mesh.set_surface_override_material(0, item.material)
		else:
			torso_mesh.set_surface_override_material(0, default_torso_material)
	else:
		# brak itemu w slocie -> wracamy do domyślnego mesha + materiału
		torso_mesh.mesh = default_torso_mesh
		torso_mesh.set_surface_override_material(0, default_torso_material)
		
func apply_hands_item(item: ItemDataEquipHands) -> void:
	if item:
		# jeśli item ma własny mesh, użyj go; inaczej domyślne ręce
		if item.mesh:
			hands_mesh.mesh = item.mesh
		else:
			hands_mesh.mesh = default_hands_mesh

		# jeśli item ma własny materiał, użyj go; inaczej domyślny
		if item.material:
			hands_mesh.set_surface_override_material(0, item.material)
		else:
			hands_mesh.set_surface_override_material(0, default_hands_material)
	else:
		# brak itemu w slocie -> wracamy do domyślnego mesha + materiału
		hands_mesh.mesh = default_hands_mesh
		hands_mesh.set_surface_override_material(0, default_hands_material)
		

func apply_head_item(item: ItemDataEquipHead) -> void:
	if item:
		# jeśli item ma własny mesh, użyj go; inaczej domyślny
		if item.mesh:
			head_mesh.mesh = item.mesh
		else:
			head_mesh.mesh = default_head_mesh

		# jeśli item ma własny materiał, użyj go; inaczej domyślny
		if item.material:
			head_mesh.set_surface_override_material(0, item.material)
		else:
			head_mesh.set_surface_override_material(0, default_head_material)
	else:
		# brak itemu w slocie -> wracamy do domyślnego mesha + materiału
		head_mesh.mesh = default_head_mesh
		head_mesh.set_surface_override_material(0, default_head_material)
