extends Node2D


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("0b1118"))
	draw_rect(Rect2(0, 100, 1280, 520), Color("22272c"))
	draw_rect(Rect2(0, 570, 1280, 50), Color("292621"))
	draw_rect(Rect2(0, 620, 1280, 100), Color("0a0d11"))
	draw_line(Vector2(0, 620), Vector2(1280, 615), Color("665d4d"), 3.0)

	# Entrance door and warped frame
	draw_rect(Rect2(45, 205, 120, 415), Color("12171b"))
	draw_rect(Rect2(58, 225, 92, 390), Color("34302b"))
	draw_line(Vector2(52, 205), Vector2(161, 220), Color("796e5a"), 4.0)
	draw_circle(Vector2(132, 430), 5.0, Color("b59b66"))

	# Bed
	draw_rect(Rect2(430, 410, 300, 150), Color("34383a"))
	draw_rect(Rect2(415, 390, 330, 45), Color("827b68"))
	draw_rect(Rect2(445, 400, 95, 30), Color("a6a08d"))
	draw_line(Vector2(435, 560), Vector2(425, 620), Color("6b6255"), 8.0)
	draw_line(Vector2(725, 560), Vector2(735, 620), Color("6b6255"), 8.0)

	# Mixed luggage
	draw_rect(Rect2(275, 515, 120, 95), Color("56483e"))
	draw_rect(Rect2(292, 480, 85, 55), Color("716052"))
	draw_line(Vector2(315, 480), Vector2(315, 455), Color("81715e"), 4.0)
	draw_line(Vector2(355, 480), Vector2(355, 455), Color("81715e"), 4.0)

	# Photo strip
	for index in range(3):
		var photo_x := 770 + index * 70
		draw_rect(Rect2(photo_x, 245, 55, 80), Color("d1c6aa"))
		draw_circle(Vector2(photo_x + 28, 270), 11.0 + index, Color("5c5750"))
		draw_rect(Rect2(photo_x + 16, 283, 25, 30), Color("8e8879"))

	# Vent and sound pipe
	draw_rect(Rect2(945, 390, 105, 80), Color("11161a"))
	for y in range(402, 464, 12):
		draw_line(Vector2(955, y), Vector2(1040, y), Color("70777a"), 2.0)
	draw_line(Vector2(997, 470), Vector2(997, 620), Color("40494c"), 9.0)

	# Frosted window and moving tarp shadow
	draw_rect(Rect2(1075, 170, 150, 245), Color("283b46"))
	draw_rect(Rect2(1087, 182, 126, 221), Color("4d626b"))
	draw_polygon(
		PackedVector2Array([Vector2(1125, 205), Vector2(1188, 230), Vector2(1162, 365), Vector2(1102, 340)]),
		PackedColorArray([Color(0.08, 0.11, 0.13, 0.58)])
	)

	# Writing table used as the player's deduction point
	draw_rect(Rect2(1070, 505, 165, 95), Color("463a31"))
	draw_rect(Rect2(1055, 493, 190, 18), Color("756150"))
	draw_rect(Rect2(1090, 520, 115, 55), Color("d0c4a2"))
