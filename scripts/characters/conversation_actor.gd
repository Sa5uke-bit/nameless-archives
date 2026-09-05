extends Node
## Small, foot-anchored performance on existing portraits; never moves collision bodies.

const ACTORS := {
	"detective": "侦探", "chen_mo": "陈默", "deng_shouyi": "邓守义",
	"fang_yun": "方芸", "feng_qichang": "冯启昌", "gu_haichuan": "顾海川",
	"gu_ning": "顾宁", "huang_weiguo": "黄维国", "jiang_he": "蒋禾",
	"liang_shaokang": "梁绍康", "luo_yao": "罗遥", "qiao_wen": "乔雯",
	"sun_guiqin": "孙桂琴", "wen_cen": "温岑", "xu_zheng": "徐峥",
	"yang_pei": "杨佩", "zhao_cheng": "赵成",
}

var actor_name := ""
var portrait: Sprite2D
var hud: CanvasLayer
var rest_position := Vector2.ZERO
var rest_scale := Vector2.ONE
var rest_rotation := 0.0
var phase := 0.0
var speech_weight := 0.0
var foot_offset := Vector2.ZERO


static func identify(sprite: Sprite2D) -> String:
	if sprite.texture == null:
		return ""
	var file := sprite.texture.resource_path.get_file().get_basename()
	for actor_id: String in ACTORS:
		if file.begins_with(actor_id + "_v"):
			return ACTORS[actor_id]
	return ""


func configure(sprite: Sprite2D, dialogue_hud: CanvasLayer) -> void:
	portrait = sprite
	hud = dialogue_hud
	actor_name = identify(sprite)
	rest_position = sprite.position
	rest_scale = sprite.scale
	rest_rotation = sprite.rotation
	# Alpha bounds keep the actual soles anchored, including transparent margins.
	var bounds := sprite.texture.get_image().get_used_rect()
	foot_offset = Vector2(0.0, bounds.end.y - sprite.texture.get_height() * 0.5)
	phase = float(actor_name.hash() % 1000) / 100.0


func _process(delta: float) -> void:
	if not is_instance_valid(portrait) or not is_instance_valid(hud):
		return
	phase += delta
	var speaking: bool = hud.dialogue_panel.visible and hud.speaker_label.text == actor_name
	# Stop gesturing once a voiced line ends, while allowing silent text to perform.
	if hud.dialogue_voice_player.stream != null:
		speaking = speaking and hud.dialogue_voice_player.playing
	speech_weight = move_toward(speech_weight, 1.0 if speaking else 0.0, delta * 4.0)
	var breath := sin(phase * 1.8) * 0.003
	var gesture := sin(phase * 4.3) * sin(phase * 1.1) * speech_weight
	var lean := gesture * 0.009
	portrait.scale = rest_scale * Vector2(1.0, 1.0 + breath + gesture * 0.004)
	portrait.rotation = rest_rotation + lean
	var original_foot := (foot_offset * rest_scale).rotated(rest_rotation)
	var animated_foot := (foot_offset * portrait.scale).rotated(portrait.rotation)
	portrait.position = rest_position + original_foot - animated_foot


func _exit_tree() -> void:
	if is_instance_valid(portrait):
		portrait.position = rest_position
		portrait.scale = rest_scale
		portrait.rotation = rest_rotation
