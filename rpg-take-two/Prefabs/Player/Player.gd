extends CharacterBody2D

@onready var body: Node2D = $Body
@onready var spr: Sprite2D = $Body/Base

# Use a PackedScene reference and instantiate inside _ready()
const INVENTORY_UI_SCENE: PackedScene = preload("res://UI/InventoryUI.tscn")
var inventory_ui: CanvasLayer

const TILE_SIZE := Vector2(32, 32)
const TEXTURE := {
	"down": preload("res://Graphics/Player-Sprites/player_down.png"),
	"up": preload("res://Graphics/Player-Sprites/player_up.png"),
	"left": preload("res://Graphics/Player-Sprites/player_left.png"),
	"right": preload("res://Graphics/Player-Sprites/player_right.png")
}

# Wobble Tunining
const MOVE_TIME := 0.185
const WOBBLE_DEGREE := 3.0
const WOBBLE_DEGREE_BIG := 6.0
const WOBBLE_EASE := Tween.EASE_IN_OUT
const WOBBLE_TRANS := Tween.TRANS_SINE

var is_moving := false
var facing: String = "down"
var wobble_tween: Tween = null

func _ready() -> void:
	print("[Player] _ready() start")
	
	spr.centered = true
	spr.rotation_degrees = 0.0
	body.rotation_degrees = 0.0
	spr.texture = TEXTURE[facing]
	global_position = (global_position / TILE_SIZE).round() * TILE_SIZE + TILE_SIZE * 0.5
	
	set_meta("facing", facing)
	Appearance.attach($Body)
	
	# Instantiate UI and add it
	if INVENTORY_UI_SCENE == null:
		push_error("[Player] INVENTORY_UI_SCENE is null (bad path?)")
		return
		
	inventory_ui = INVENTORY_UI_SCENE.instantiate() as CanvasLayer
	if inventory_ui == null:
		push_error("[Player] InventoryUI root is not a CanvasLayer?")
		inventory_ui = INVENTORY_UI_SCENE.instantiate()
	
	# Use deferred add to avoid any "tree locked" timing issues
	get_tree().root.call_deferred("add_child", inventory_ui)
	
	# Defer visibility set until after it's added
	call_deferred("_finish_setup_ui")

func _finish_setup_ui() -> void:
	if inventory_ui:
		inventory_ui.visible = false
		print("[Player] UI added. parent = ", inventory_ui.get_parent(), "  visible = ", inventory_ui.visible)
	else:
		push_error("[Player] UI instance missing after add_child.")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory_toggle"):
		if inventory_ui and is_instance_valid(inventory_ui):
			inventory_ui.visible = !inventory_ui.visible
			print("[UI] toggled ->", inventory_ui.visible)
		else:
			push_warning("[UI] toggle pressed but UI not instantiated yet.")

func _physics_process(_delta: float) -> void:
	if is_moving:
		return
		
	if Input.is_action_pressed("ui_up") and !$Directions/Up.is_colliding():
		_face("up")
		_move(Vector2.UP, "up")
	elif Input.is_action_pressed("ui_down") and !$Directions/Down.is_colliding():
		_face("down")
		_move(Vector2.DOWN, "down")
	elif Input.is_action_pressed("ui_left") and !$Directions/Left.is_colliding():
		_face("left")
		_move(Vector2.LEFT, "left")
	elif Input.is_action_pressed("ui_right") and !$Directions/Right.is_colliding():
		_face("right")
		_move(Vector2.RIGHT, "right")
	else:
		if Input.is_action_pressed("ui_up"): _face("up")
		if Input.is_action_pressed("ui_down"): _face("down")
		if Input.is_action_pressed("ui_right"): _face("right")
		if Input.is_action_pressed("ui_left"): _face("left")

func _face(direction: String) -> void:
	if direction == facing: return
	facing = direction
	set_meta("facing", facing)
	spr.texture = TEXTURE[direction]
	Appearance.update($Body, facing)
	
func _move(direction: Vector2, direction_name: String) -> void:
	is_moving = true
	var target := global_position + direction * TILE_SIZE
	
	var move_tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	move_tween.tween_property(self, "global_position", target, MOVE_TIME).set_trans(Tween.TRANS_SINE)
	_start_wobble(direction_name, MOVE_TIME)
	move_tween.finished.connect(func():
		is_moving = false
		body.rotation_degrees = 0.0	
	)

func _start_wobble(direction_name: String, total_time: float) -> void:
	if wobble_tween and wobble_tween.is_running():
		wobble_tween.kill()
	body.rotation_degrees = 0.0
	
	var seq: Array[float]
	match direction_name:
		"down": seq = [ +WOBBLE_DEGREE, 0.0, -WOBBLE_DEGREE, 0.0 ]
		"up": seq = [ -WOBBLE_DEGREE, 0.0, +WOBBLE_DEGREE, 0.0 ]
		"left": seq = [ +WOBBLE_DEGREE, 0.0, -WOBBLE_DEGREE_BIG, 0.0 ]
		"right": seq = [ -WOBBLE_DEGREE, 0.0, +WOBBLE_DEGREE_BIG, 0.0 ]
		_: seq = [ 0.0 ]
	
	var seg_time := total_time / float(seq.size())
	wobble_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	for ang in seq:
		wobble_tween.tween_property(body, "rotation_degrees", ang, seg_time)\
			.set_trans(WOBBLE_TRANS).set_ease(WOBBLE_EASE)
	
	
