extends CanvasLayer

@export var margin_right_px := 1.0        # gap from right edge
@export var margin_vertical_px := 10.0     # top/bottom safety margin
@export var vertical_push_px := 40.0      # nudge down from perfect vertical center
@export var desired_size_px := Vector2(80, 100)  # final on-screen size

func _ready() -> void:
	await get_tree().process_frame
	# re-run on resize
	get_viewport().size_changed.connect(_fit_and_place)
	_fit_and_place()

func _fit_and_place() -> void:
	var window := $Root/Layout/Window as Control

	# Make this node ignore parent layout/scale entirely.
	window.top_level = true

	# Choose final on-screen size that fits the viewport margins.
	var vp := get_viewport().get_visible_rect().size
	var max_w := vp.x - margin_right_px * 2.0
	var max_h := vp.y - margin_vertical_px * 2.0
	var size_px := Vector2(
		min(desired_size_px.x, max_w),
		min(desired_size_px.y, max_h)
	)

	# Enforce that size (children can’t make it grow bigger than this).
	window.custom_minimum_size = size_px
	window.size = size_px

	# Place at right edge, slightly below vertical center.
	var left_px := vp.x - size_px.x - margin_right_px
	var top_px  := (vp.y - size_px.y) * 0.5 + vertical_push_px
	window.global_position = Vector2(left_px, top_px)
