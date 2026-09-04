extends Node2D

@export_enum("stage", "wardrobe", "backstage", "finale") var area := "stage"


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("0d1118"))
	draw_rect(Rect2(0, 105, 1280, 515), Color("191820"))
	draw_rect(Rect2(0, 620, 1280, 100), Color("0a0d12"))
	draw_line(Vector2(0, 620), Vector2(1280, 620), Color("6d5b4d"), 3.0)
	match area:
		"wardrobe":
			_draw_wardrobe()
		"backstage":
			_draw_backstage()
		"finale":
			_draw_finale()
		_:
			_draw_stage()


func _draw_stage() -> void:
	draw_rect(Rect2(95, 125, 1090, 415), Color("32171d"))
	draw_rect(Rect2(160, 160, 960, 330), Color("11131a"))
	for x in [125.0, 1085.0]:
		draw_polygon(
			PackedVector2Array([
				Vector2(x, 110), Vector2(x + 125, 110),
				Vector2(x + 85, 545), Vector2(x - 25, 545),
			]),
			PackedColorArray([Color("5a2027")])
		)
	for row in range(4):
		for seat in range(13):
			var center := Vector2(170 + seat * 76, 520 + row * 22)
			draw_circle(center, 8.0, Color(0.25, 0.18, 0.2, 0.7))
	draw_rect(Rect2(288, 210, 155, 205), Color("ddd2b0"), true)
	draw_rect(Rect2(305, 228, 120, 130), Color("303540"), true)
	draw_circle(Vector2(365, 282), 30, Color("d9d0bd"))
	draw_line(Vector2(350, 360), Vector2(380, 360), Color("8a724f"), 5.0)
	_draw_person(Vector2(690, 620), Color("4a4d59"), Color("a79283"))
	_draw_person(Vector2(875, 620), Color("343844"), Color("a58f80"))
	draw_rect(Rect2(1120, 230, 105, 390), Color("090b0f"))


func _draw_wardrobe() -> void:
	for x in [160.0, 365.0, 570.0, 1010.0]:
		draw_rect(Rect2(x, 145, 145, 420), Color("2d2828"))
		draw_rect(Rect2(x + 12, 165, 121, 10), Color("75634f"))
	for center in [Vector2(410, 455), Vector2(520, 455)]:
		draw_circle(center + Vector2(0, -150), 18, Color("d7cfb7"))
		draw_polygon(
			PackedVector2Array([
				center + Vector2(-42, -125), center + Vector2(42, -125),
				center + Vector2(68, 70), center + Vector2(-68, 70),
			]),
			PackedColorArray([Color("d4d0c7")])
		)
	for x in [655.0, 705.0]:
		draw_rect(Rect2(x, 515, 38, 16), Color("171719"))
	draw_rect(Rect2(780, 400, 175, 145), Color("493a2d"))
	for index in range(5):
		draw_rect(Rect2(802 + index * 28, 425, 20, 28), Color("cdbf9b"))
	draw_rect(Rect2(805, 260, 140, 130), Color("20252b"))
	for index in range(4):
		draw_line(
			Vector2(825, 285 + index * 27),
			Vector2(925, 285 + index * 27),
			Color("8a7d64"),
			3.0
		)
	draw_rect(Rect2(1135, 225, 100, 395), Color("090b0f"))


func _draw_backstage() -> void:
	draw_rect(Rect2(8, 225, 72, 395), Color("07090c"))
	draw_rect(Rect2(105, 400, 125, 145), Color("342d2a"))
	draw_rect(Rect2(125, 430, 85, 68), Color("222831"))
	for x in [143.0, 190.0]:
		draw_circle(Vector2(x, 464), 18, Color("b7aa7f"), false, 4.0)
	draw_rect(Rect2(250, 325, 120, 220), Color("20252b"))
	draw_rect(Rect2(270, 360, 80, 105), Color("11151b"))
	for y in [380.0, 412.0, 444.0]:
		draw_line(Vector2(282, y), Vector2(338, y), Color("718087"), 3.0)
	draw_rect(Rect2(405, 390, 105, 155), Color("4a3c30"))
	for index in range(3):
		draw_rect(Rect2(422, 415 + index * 34, 70, 22), Color("cdbf9b"))
	draw_rect(Rect2(540, 255, 120, 290), Color("3b3331"))
	for y in [325.0, 395.0, 465.0]:
		draw_line(Vector2(550, y), Vector2(650, y), Color("756457"), 3.0)
	draw_rect(Rect2(690, 350, 110, 195), Color("1e2529"))
	draw_rect(Rect2(707, 378, 76, 112), Color("d8cfad"))
	_draw_person(Vector2(875, 620), Color("39444d"), Color("a38d7c"))
	_draw_person(Vector2(995, 620), Color("4c3a34"), Color("9b8172"), 1.05)
	draw_rect(Rect2(1050, 265, 120, 280), Color("20252b"))
	for index in range(5):
		draw_line(
			Vector2(1068, 300 + index * 42),
			Vector2(1152, 300 + index * 42),
			Color("8a7d64"),
			3.0
		)
	draw_rect(Rect2(1210, 220, 70, 400), Color("07090c"))


func _draw_finale() -> void:
	draw_rect(Rect2(85, 125, 1110, 410), Color("32171d"))
	draw_rect(Rect2(170, 165, 940, 315), Color("101217"))
	draw_circle(Vector2(640, 235), 110, Color(0.8, 0.72, 0.52, 0.12))
	_draw_person(Vector2(270, 620), Color("28343d"), Color("b0a58f"))
	_draw_person(Vector2(515, 620), Color("4a4d59"), Color("a79283"))
	_draw_person(Vector2(765, 620), Color("343844"), Color("a58f80"))
	_draw_person(Vector2(1020, 620), Color("4c3a34"), Color("9b8172"), 1.08)
	draw_rect(Rect2(475, 535, 360, 62), Color("4b3b2e"))
	for index in range(4):
		draw_rect(Rect2(515 + index * 75, 548, 55, 32), Color("d0c49f"))


func _draw_person(base: Vector2, coat: Color, skin: Color, scale_factor: float = 1.0) -> void:
	draw_circle(base + Vector2(0, -135 * scale_factor), 22.0 * scale_factor, skin)
	draw_polygon(
		PackedVector2Array([
			base + Vector2(-30, -108) * scale_factor,
			base + Vector2(30, -108) * scale_factor,
			base + Vector2(42, 0) * scale_factor,
			base + Vector2(-42, 0) * scale_factor,
		]),
		PackedColorArray([coat])
	)
