extends Node2D


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# Walls and floor
	draw_rect(Rect2(0, 0, 1280, 720), Color("111824"))
	draw_rect(Rect2(0, 105, 1280, 515), Color("1b2633"))
	draw_rect(Rect2(0, 570, 1280, 80), Color("17202a"))
	draw_rect(Rect2(0, 620, 1280, 100), Color("0b1017"))
	draw_line(Vector2(0, 620), Vector2(1280, 620), Color("52606d"), 3.0)

	# Rain-streaked windows
	draw_rect(Rect2(60, 170, 165, 250), Color("263b4c"))
	draw_rect(Rect2(70, 180, 145, 230), Color("0b2435"))
	draw_line(Vector2(142, 180), Vector2(142, 410), Color("496477"), 3.0)
	draw_line(Vector2(70, 295), Vector2(215, 295), Color("496477"), 3.0)
	for x in range(82, 210, 24):
		draw_line(Vector2(x, 190), Vector2(x - 11, 245), Color(0.45, 0.65, 0.74, 0.25), 2.0)

	# Front desk
	draw_rect(Rect2(275, 445, 235, 175), Color("3a2f2a"))
	draw_rect(Rect2(260, 430, 265, 25), Color("655047"))
	draw_rect(Rect2(300, 480, 185, 20), Color("27201d"))
	draw_rect(Rect2(310, 515, 165, 75), Color("44352f"), false, 3.0)

	# Qiao Wen placeholder silhouette
	draw_circle(Vector2(242, 485), 22.0, Color("9b9083"))
	draw_polygon(
		PackedVector2Array([Vector2(213, 513), Vector2(271, 513), Vector2(280, 620), Vector2(204, 620)]),
		PackedColorArray([Color("454b4b")])
	)

	# Staff photo and key board
	draw_rect(Rect2(555, 220, 100, 120), Color("6f6253"))
	draw_rect(Rect2(565, 230, 80, 100), Color("262a2d"))
	draw_rect(Rect2(700, 215, 125, 145), Color("332b27"))
	for row in range(3):
		for column in range(3):
			var key_pos := Vector2(722 + column * 40, 245 + row * 42)
			draw_circle(key_pos, 4.0, Color("b9a77a"))
			draw_line(key_pos, key_pos + Vector2(0, 16), Color("8e805f"), 2.0)

	# Hallway and stair door
	draw_rect(Rect2(1060, 205, 150, 415), Color("0b1118"))
	draw_rect(Rect2(1080, 255, 105, 365), Color("20252b"))
	draw_rect(Rect2(1090, 270, 85, 340), Color("15191e"), false, 3.0)
	draw_circle(Vector2(1160, 445), 5.0, Color("ac9366"))

	# Gu Ning placeholder silhouette
	draw_circle(Vector2(930, 485), 23.0, Color("aa9b8d"))
	draw_polygon(
		PackedVector2Array([Vector2(900, 515), Vector2(960, 515), Vector2(972, 620), Vector2(890, 620)]),
		PackedColorArray([Color("535865")])
	)

	# Dim overhead lights
	for light_x in [350, 770, 1080]:
		draw_line(Vector2(light_x, 105), Vector2(light_x, 135), Color("605d50"), 3.0)
		draw_rect(Rect2(light_x - 38, 135, 76, 10), Color("b5a77b"))
