extends Node2D


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("0a1014"))
	draw_rect(Rect2(0, 95, 1280, 525), Color("1b2426"))
	draw_rect(Rect2(0, 560, 1280, 60), Color("252a27"))
	draw_rect(Rect2(0, 620, 1280, 100), Color("080c0e"))
	draw_line(Vector2(0, 620), Vector2(1280, 620), Color("53605a"), 3.0)

	# Back stair door
	draw_rect(Rect2(25, 230, 110, 390), Color("111619"))
	draw_rect(Rect2(38, 250, 84, 365), Color("343b3a"))
	draw_circle(Vector2(105, 440), 5.0, Color("9e8b62"))

	# Report table
	draw_rect(Rect2(210, 510, 165, 95), Color("3b3530"))
	draw_rect(Rect2(195, 495, 195, 18), Color("64594c"))
	draw_rect(Rect2(230, 505, 120, 70), Color("c5b995"))

	# Laundry cart
	draw_rect(Rect2(420, 455, 125, 125), Color("3f4a49"), false, 8.0)
	draw_circle(Vector2(440, 595), 13.0, Color("161b1b"))
	draw_circle(Vector2(530, 595), 13.0, Color("161b1b"))
	draw_line(Vector2(545, 470), Vector2(575, 435), Color("586463"), 6.0)

	# Rear door and old rain photo
	draw_rect(Rect2(590, 215, 100, 405), Color("101517"))
	draw_rect(Rect2(603, 235, 74, 380), Color("29302f"))
	draw_rect(Rect2(615, 315, 48, 70), Color("a9a18b"))

	# Wage locker
	draw_rect(Rect2(705, 245, 105, 375), Color("37403e"))
	for y in range(275, 590, 65):
		draw_line(Vector2(716, y), Vector2(799, y), Color("697370"), 2.0)
		draw_circle(Vector2(785, y - 20), 3.0, Color("a89b73"))

	# Gu Ning placeholder
	draw_circle(Vector2(850, 490), 22.0, Color("a99a8c"))
	draw_polygon(
		PackedVector2Array([Vector2(820, 518), Vector2(880, 518), Vector2(890, 620), Vector2(810, 620)]),
		PackedColorArray([Color("525864")])
	)

	# Central deduction table
	draw_rect(Rect2(900, 515, 130, 85), Color("44392f"))
	draw_rect(Rect2(888, 502, 154, 15), Color("71604d"))
	draw_rect(Rect2(920, 522, 90, 48), Color("c1b58f"))

	# Repair board and cistern section
	draw_rect(Rect2(1035, 240, 90, 145), Color("544b3e"))
	draw_rect(Rect2(1048, 253, 64, 118), Color("c8bb94"))
	draw_ellipse_placeholder(Vector2(1115, 585), Vector2(70, 24), Color("1a2020"))
	draw_ellipse_placeholder(Vector2(1115, 585), Vector2(70, 24), Color("73756e"), false, 5.0)

	# Zhao Cheng placeholder
	draw_circle(Vector2(1195, 490), 23.0, Color("8f8375"))
	draw_polygon(
		PackedVector2Array([Vector2(1165, 518), Vector2(1225, 518), Vector2(1235, 620), Vector2(1155, 620)]),
		PackedColorArray([Color("4a4945")])
	)

	# Final exit edge
	draw_rect(Rect2(1250, 220, 30, 400), Color("050809"))


func draw_ellipse_placeholder(
		center: Vector2,
		radii: Vector2,
		color: Color,
		filled: bool = true,
		width: float = -1.0
	) -> void:
	var points := PackedVector2Array()
	for index in range(33):
		var angle := TAU * float(index) / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	if filled:
		draw_colored_polygon(points, color)
	else:
		draw_polyline(points, color, width, true)
