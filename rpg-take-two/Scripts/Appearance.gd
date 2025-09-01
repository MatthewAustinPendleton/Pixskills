extends Node

# Folder / naming conventions
#  For each slot, styles live in:
#   {root}/{styleName}/{prefix}_{down|up|left|right}.png

const BODY_KEY := "ovl_body_attached"

const SLOTS: Dictionary = {
	"hair": {
		"root": "res://Graphics/Player-Sprites/Hair-Sprites",
		"node_name": "Hair",
		"z": 14,
		"use_recolor": true,
		"key_color": Color("#DEEED6"),
		"allow_missing": false,
		"fallback_facing": "down"
	},
	"eyes": {
		"root": "res://Graphics/Player-Sprites/Eye-Sprites",
		"node_name": "Eyes",
		"z": 12,
		"use_recolor": true,
		"key_color": Color("#DEEED6"),
		"allow_missing": true,
		"hide_on": ["up"],
		"fallback_facing": "down"
	}
	
}

const SWATCHES: Dictionary = {
	"hair": [
		Color("#1A1A1A"), Color("#3A2F2A"), Color("#5A4337"), Color("#A1785A"),
		Color("#C9A270"), Color("#E0C78B"), Color("#F1E7C6"), Color("#B3472F"),
		Color("#D46B5E"), Color("#A7A7A7"), Color("#E3E3E3"),
		Color("#597DCE"), Color("#6DC2CA"), Color("#D04648"),
		Color("#6DAA2C"), Color("#D27D2C")
	],
	"eyes": [
		Color("#3A2F2A"), Color("#5A4337"), Color("#597DCE"),
		Color("#6DAA2C"), Color("#8595A1"), Color("#140C1C")
	]
}

const STYLE_OFFSETS: Dictionary = {
	"hair": {
		"Hair1": {
			"down": Vector2(0, -5),
			"up": Vector2(0, -5),
			"left": Vector2(1, -6),
			"right": Vector2(-1, -6)
		},
		"Hair2": {
			"down": Vector2(0, -3),
			"up": Vector2(0, -3),
			"left": Vector2(1, -4),
			"right": Vector2(-1, -4)
		}
	},
	"eyes": {
		"Eye1": {
			"down": Vector2(0, 0),
			"left": Vector2(-1, 0),
			"right": Vector2(1, 0)
		}
	}
}

# --- Registry built at runtime ---
var styles_by_slot: Dictionary = {}

# Meta keys per slot on the Body node
func _style_key(slot: String) -> String: return "ovl_style_" + slot
func _color_key(slot: String) -> String: return "ovl_color_" + slot

func _ready() -> void:
	_scan_all_slots()

# --- Public API ---
func attach(body: Node) -> void:
	# Create child Sprite2Ds, assign materials, and pick random styles/colors if needed
	if body.has_meta(BODY_KEY): return
	body.set_meta(BODY_KEY, true)
	
	for slot in SLOTS.keys():
		_ensure_node_for_slot(body, slot)
		if not body.has_meta(_style_key(slot)):
			var st := _pick_style(slot)
			if st.size() > 0:
				body.set_meta(_style_key(slot), st)
		if not body.has_meta(_color_key(slot)):
			var col := _pick_color(slot)
			body.set_meta(_color_key(slot), col)
			_apply_color(body, slot, col)
	
	# Initialize textures/offsets to current facing if body stores it; default "down"
	var facing := (str(body.get_meta("facing")) if body.has_meta("facing") else "down")
	update(body, facing)

func update(body: Node, facing: String) -> void:
	# Update ALL slots the body currently uses to the current facing
	for slot in SLOTS.keys():
		_update_slot(body, slot, facing)

func set_style(body: Node, slot: String, style_id: String) -> void:
	var st := _find_style(slot, style_id)
	if st.size() == 0: return
	body.set_meta(_style_key(slot), st)
	# Keep existing color
	var facing := (str(body.get_meta("facing")) if body.has_meta("facing") else "down")
	_update_slot(body, slot, facing)

func randomize_style(body: Node, slot: String) -> void:
	var st := _pick_style(slot)
	if st.size() == 0: return
	body.set_meta(_style_key(slot), st)
	var facing := (str(body.get_meta("facing")) if body.has_meta("facing") else "down")
	_update_slot(body, slot, facing)

func set_color(body: Node, slot: String, color: Color) -> void:
	body.set_meta(_color_key(slot), color)
	_apply_color(body, slot, color)

func randomize_color(body: Node, slot: String) -> void:
	set_color(body, slot, _pick_color(slot))

# --- Internals ---
func _scan_all_slots() -> void:
	styles_by_slot.clear()
	for slot in SLOTS.keys():
		var root: String = SLOTS[slot]["root"]
		styles_by_slot[slot] = _scan_styles_under(root, slot)

func _scan_styles_under(root: String, slot: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var dir := DirAccess.open(root)
	if dir == null:
		push_warning("Appearance: cannot open %s" % root)
		return results
	
	var allow_missing : bool = (SLOTS.has(slot) and SLOTS[slot].has("allow_missing") and bool(SLOTS[slot]["allow_missing"]))
	
	for style_name: String in dir.get_directories():
		if style_name.is_empty(): continue
		var base: String = root + "/" + style_name + "/"
		var prefix: String = style_name.to_lower() + "_"
		var tex: Dictionary = {}
		var ok := true
		
		for d in ["down","up","left","right"]:
			var path: String = base + prefix + d + ".png"
			if ResourceLoader.exists(path):
				tex[d] = load(path)
			else:
				if not allow_missing:
					ok = false
					push_warning("Missing %s frame: %s" % [slot, path])
					break
		if ok and tex.size() > 0:
			var style: Dictionary = {"id": style_name, "tex": tex}
			if STYLE_OFFSETS.has(slot) and STYLE_OFFSETS[slot].has(style_name):
				style["offsets"] = STYLE_OFFSETS[slot][style_name]
			results.append(style)
	
	return results

func _ensure_node_for_slot(body: Node, slot: String) -> Sprite2D:
	var cfg: Dictionary = SLOTS[slot]
	var node_name: String = cfg["node_name"]
	var node := body.get_node_or_null(node_name) as Sprite2D
	if node == null:
		node = Sprite2D.new()
		node.name = node_name
		node.z_index = int(cfg["z"])
		node.centered = true
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		body.add_child(node)
		
		if bool(cfg["use_recolor"]):
			var mat := ShaderMaterial.new()
			mat.shader = load("res://Shaders/Recolor.gdshader")
			mat.set_shader_parameter("key_color", Color(cfg["key_color"]))
			node.material = mat
	return node

func _update_slot(body: Node, slot: String, facing: String) -> void:
	var cfg: Dictionary = SLOTS[slot]
	var node_name: String = cfg["node_name"]
	var node := body.get_node_or_null(node_name) as Sprite2D
	if node == null: return
	
	# Hide on specific facings
	if cfg.has("hide_on") and (facing in cfg["hide_on"]):
		node.visible = false
		return
	else:
		node.visible = true
	
	if not body.has_meta(_style_key(slot)): return
	var style: Dictionary = body.get_meta(_style_key(slot)) as Dictionary
	if not style.has("tex"): return
	
	var texs: Dictionary = style["tex"]
	var texture_to_use: Texture2D = null
	
	if texs.has(facing):
		texture_to_use = texs[facing]
	elif cfg.has("fallback_facing") and texs.has(cfg["fallback_facing"]):
		texture_to_use = texs[cfg["fallback_facing"]]
	
	node.texture = texture_to_use
	
	# Offsets (fall back to the same facing's offset, or fallback_facing's offset)
	var offsets: Dictionary = (style["offsets"] if style.has("offsets") else {})
	var off: Vector2 = Vector2.ZERO
	if offsets.has(facing):
		off = offsets[facing]
	elif cfg.has("fallback_facing") and offsets.has(cfg["fallback_facing"]):
		off = offsets[cfg["fallback_facing"]]
	node.position = off

func _apply_color(body: Node, slot: String, color: Color) -> void:
	var cfg: Dictionary = SLOTS[slot]
	if not bool(cfg["use_recolor"]): return
	var node_name: String = cfg["node_name"]
	var node := body.get_node_or_null(node_name) as Sprite2D
	if node == null:
		return
	var mat := node.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("target_color", color)

func _pick_style(slot: String) -> Dictionary:
	if not styles_by_slot.has(slot): return {}
	var arr: Array = styles_by_slot[slot]
	return (arr.pick_random() if arr.size() > 0 else {})

func _find_style(slot: String, style_id: String) -> Dictionary:
	if not styles_by_slot.has(slot): return {}
	for st in styles_by_slot[slot]:
		if st.has("id") and String(st["id"]) == style_id:
			return st
	return {}

func _pick_color(slot: String) -> Color:
	# Explicitly type as Array and give [] as a default (also typed as an Array)
	var colors: Array = SWATCHES.get(slot, []) as Array
	if colors.size() > 0:
		var v: Variant = colors.pick_random()
		if v is Color:
			return v as Color
	return Color.WHITE
	

	
	
	
