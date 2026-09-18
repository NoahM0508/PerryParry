extends Node2D
## Draws a procedural arc/cone toward the mouse cursor during the active parry window.
## Only visible for the brief parry duration, then fades out cleanly.

var is_active: bool = false
var arc_direction: Vector2 = Vector2.RIGHT
var cone_angle_rad: float = deg_to_rad(90.0)
var arc_range: float = 80.0

# Visual fade
var fade_alpha: float = 0.0
var fade_duration: float = 0.12
var fade_timer: float = 0.0
var is_fading_out: bool = false

# Sweet spot visualization
var sweet_spot_angle_rad: float = deg_to_rad(20.0)
var show_sweet_spot: bool = true

# Colors
var arc_color: Color = Color(0.2, 0.85, 1.0, 0.45)        # Cyan glow
var arc_outline_color: Color = Color(0.3, 0.9, 1.0, 0.7)   # Brighter cyan edge
var sweet_spot_color: Color = Color(1.0, 0.85, 0.2, 0.55)  # Golden center

func _process(delta: float) -> void:
	if is_active:
		fade_alpha = 1.0
		is_fading_out = false
		queue_redraw()
	elif is_fading_out:
		fade_timer -= delta
		fade_alpha = max(0.0, fade_timer / fade_duration)
		queue_redraw()
		if fade_alpha <= 0.0:
			is_fading_out = false

func activate(direction: Vector2, cone_angle_degrees: float, reach: float, sweet_spot_degrees: float) -> void:
	is_active = true
	arc_direction = direction.normalized() if direction.length_squared() > 0.0 else Vector2.RIGHT
	cone_angle_rad = deg_to_rad(cone_angle_degrees)
	arc_range = reach
	sweet_spot_angle_rad = deg_to_rad(sweet_spot_degrees)
	fade_alpha = 1.0
	is_fading_out = false
	queue_redraw()

func deactivate() -> void:
	is_active = false
	is_fading_out = true
	fade_timer = fade_duration
	queue_redraw()

func _draw() -> void:
	if fade_alpha <= 0.01:
		return

	var base_angle: float = arc_direction.angle()
	var half_cone: float = cone_angle_rad / 2.0
	var segments: int = 24

	# --- Draw the main cone fill ---
	var fill_color = Color(arc_color.r, arc_color.g, arc_color.b, arc_color.a * fade_alpha)
	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2.ZERO)
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var angle: float = base_angle - half_cone + (cone_angle_rad * t)
		points.append(Vector2(cos(angle), sin(angle)) * arc_range)
	draw_colored_polygon(points, fill_color)

	# --- Draw the cone outline arc ---
	var outline_color = Color(arc_outline_color.r, arc_outline_color.g, arc_outline_color.b, arc_outline_color.a * fade_alpha)
	var arc_points: PackedVector2Array = PackedVector2Array()
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var angle: float = base_angle - half_cone + (cone_angle_rad * t)
		arc_points.append(Vector2(cos(angle), sin(angle)) * arc_range)
	for i in range(arc_points.size() - 1):
		draw_line(arc_points[i], arc_points[i + 1], outline_color, 2.0)

	# Draw edge lines from center to cone edges
	draw_line(Vector2.ZERO, arc_points[0], outline_color, 1.5)
	draw_line(Vector2.ZERO, arc_points[arc_points.size() - 1], outline_color, 1.5)

	# --- Draw sweet spot center wedge ---
	if show_sweet_spot and sweet_spot_angle_rad > 0.0:
		var half_sweet: float = sweet_spot_angle_rad / 2.0
		var sweet_color = Color(sweet_spot_color.r, sweet_spot_color.g, sweet_spot_color.b, sweet_spot_color.a * fade_alpha)
		var sweet_segments: int = 12
		var sweet_points: PackedVector2Array = PackedVector2Array()
		sweet_points.append(Vector2.ZERO)
		for i in range(sweet_segments + 1):
			var t: float = float(i) / float(sweet_segments)
			var angle: float = base_angle - half_sweet + (sweet_spot_angle_rad * t)
			sweet_points.append(Vector2(cos(angle), sin(angle)) * arc_range)
		draw_colored_polygon(sweet_points, sweet_color)
