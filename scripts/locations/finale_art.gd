extends Node2D


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("070c12"))
	draw_rect(Rect2(0, 95, 1280, 525), Color("18222d"))
	draw_rect(Rect2(0, 620, 1280, 100), Color("080b0f"))
	draw_line(Vector2(0, 620), Vector2(1280, 620), Color("5c625e"), 3.0)

	# Rain windows and old hotel sign
	draw_rect(Rect2(65, 170, 180, 280), Color("0c2637"))
	for x in range(82, 235, 26):
		draw_line(Vector2(x, 185), Vector2(x - 20, 430), Color(0.4, 0.62, 0.72, 0.25), 2.0)
	draw_rect(Rect2(500, 125, 280, 65), Color("242b31"))

	# Four figures facing each other
	_draw_figure(Vector2(330, 620), Color("26333d"), Color("b0a58f"))
	_draw_figure(Vector2(540, 620), Color("555b68"), Color("aa9b8d"))
	_draw_figure(Vector2(760, 620), Color("494844"), Color("918577"))
	_draw_figure(Vector2(980, 620), Color("2c2d2c"), Color("a28f7b"), 1.18)

	# Evidence table between the detective and Gu Haichuan
	draw_rect(Rect2(570, 535, 360, 70), Color("3d342d"))
	draw_rect(Rect2(550, 520, 400, 18), Color("75624f"))
	for index in range(4):
		draw_rect(Rect2(600 + index * 75, 530, 55, 37), Color("c7bb98"))


func _draw_figure(base: Vector2, coat: Color, skin: Color, scale_factor: float = 1.0) -> void:
	draw_circle(base + Vector2(0, -132 * scale_factor), 23.0 * scale_factor, skin)
	draw_polygon(
		PackedVector2Array([
			base + Vector2(-31, -103) * scale_factor,
			base + Vector2(31, -103) * scale_factor,
			base + Vector2(42, 0) * scale_factor,
			base + Vector2(-42, 0) * scale_factor,
		]),
		PackedColorArray([coat])
	)
