extends CanvasLayer

@export var fit_margin := 50
@export var vertical_push := 20.0

func _ready() -> void:
	await get_tree().process_frame
	# Refit
	var root := $Root as Control
	root.connect("resized", Callable(self, "_fit_and_place"))
	_fit_and_place()

func _fit_and_place() -> void:
	var root := $Root as Control
	var layout := $Root/Layout as Control
	var window := $Root/Layout/Window as Control
	
	var vp := get_viewport().get_visible_rect().size
	var need := window.get_combined_minimum_size()
	var max_size := vp - Vector2(fit_margin * 2.0, fit_margin * 2.0)
	
	var s : float = min(max_size.x / need.x, max_size.y / need.y)
	s = clamp(s, 0.25, 1.0)
	root.scale = Vector2(s, s)
	
	var scaled_size := need * s
	
	var target_x := vp.x - scaled_size.x - fit_margin
	var target_y := (vp.y - scaled_size.y) * 0.5 + vertical_push
	
	window.position = Vector2(target_x, target_y) / s
	
	
