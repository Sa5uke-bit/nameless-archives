class_name DetectivePlayer
extends CharacterBody2D

signal interaction_requested(target: Investigable)
signal target_changed(prompt_text: String)

@export var move_speed := 230.0
@export var acceleration := 1400.0
@export var deceleration := 1800.0
@export var mouse_arrival_distance := 10.0
@export var interaction_arrival_distance := 58.0

@onready var interaction_area: Area2D = $InteractionArea
@onready var body_visual: Polygon2D = $BodyVisual
@onready var character_sprite: Sprite2D = $CharacterSprite
@onready var walk_sprite: AnimatedSprite2D = $WalkSprite

var controls_enabled := true
var current_target: Investigable
var hovered_target: Investigable
var pending_interaction: Investigable
var mouse_destination := NAN
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)


func _physics_process(delta: float) -> void:
	var direction := 0.0
	if controls_enabled:
		direction = Input.get_axis("move_left", "move_right")
		if not is_zero_approx(direction):
			_cancel_mouse_movement()
		elif not is_nan(mouse_destination):
			var distance_to_destination := mouse_destination - global_position.x
			var arrival_distance := (
				interaction_arrival_distance
				if is_instance_valid(pending_interaction)
				else mouse_arrival_distance
			)
			if absf(distance_to_destination) > arrival_distance:
				direction = signf(distance_to_destination)
			else:
				mouse_destination = NAN
				velocity.x = 0.0

	if not is_zero_approx(direction):
		velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * delta)
		character_sprite.flip_h = direction < 0.0
		walk_sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()
	_update_walk_visual(delta)
	_update_interaction_target()
	_update_hovered_target()
	_try_pending_interaction()


func _unhandled_input(event: InputEvent) -> void:
	if controls_enabled and event.is_action_pressed("interact") and is_instance_valid(current_target):
		_cancel_mouse_movement()
		interaction_requested.emit(current_target)
		get_viewport().set_input_as_handled()
		return

	if not controls_enabled or event is not InputEventMouseButton or not event.pressed:
		return

	if event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_target := _find_investigable_at(get_global_mouse_position())
		if is_instance_valid(clicked_target):
			request_mouse_interaction(clicked_target)
		else:
			request_mouse_destination(get_global_mouse_position().x)
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_cancel_mouse_movement()
		get_viewport().set_input_as_handled()


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not enabled:
		velocity.x = 0.0
		_cancel_mouse_movement()
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func request_mouse_destination(world_x: float) -> void:
	pending_interaction = null
	mouse_destination = clampf(world_x, 28.0, 1252.0)


func request_mouse_interaction(target: Investigable) -> void:
	if not is_instance_valid(target):
		return
	if current_target == target:
		_cancel_mouse_movement()
		interaction_requested.emit(target)
		return
	pending_interaction = target
	mouse_destination = target.global_position.x


func _update_interaction_target() -> void:
	var nearest: Investigable
	var nearest_distance := INF
	for area: Area2D in interaction_area.get_overlapping_areas():
		if area is not Investigable:
			continue
		var candidate := area as Investigable
		var distance := global_position.distance_squared_to(candidate.global_position)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance

	if nearest == current_target:
		return
	current_target = nearest
	_refresh_prompt()


func _update_hovered_target() -> void:
	var next_hovered: Investigable
	if controls_enabled:
		next_hovered = _find_investigable_at(get_global_mouse_position())
	if next_hovered == hovered_target:
		return
	hovered_target = next_hovered
	Input.set_default_cursor_shape(
		Input.CURSOR_POINTING_HAND if is_instance_valid(hovered_target) else Input.CURSOR_ARROW
	)
	_refresh_prompt()


func _find_investigable_at(world_position: Vector2) -> Investigable:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 2
	var nearest: Investigable
	var nearest_distance := INF
	for result: Dictionary in get_world_2d().direct_space_state.intersect_point(query, 16):
		var collider: Variant = result.get("collider")
		if collider is not Investigable:
			continue
		var candidate := collider as Investigable
		var distance := world_position.distance_squared_to(candidate.global_position)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest


func _try_pending_interaction() -> void:
	if not controls_enabled or not is_instance_valid(pending_interaction):
		return
	if current_target != pending_interaction:
		return
	var target := pending_interaction
	_cancel_mouse_movement()
	interaction_requested.emit(target)


func _cancel_mouse_movement() -> void:
	mouse_destination = NAN
	pending_interaction = null


func _refresh_prompt() -> void:
	if is_instance_valid(hovered_target):
		var action := "单击调查" if hovered_target == current_target else "单击前往"
		target_changed.emit("%s · %s" % [action, hovered_target.display_name])
	elif is_instance_valid(current_target):
		target_changed.emit(current_target.get_prompt_text())
	else:
		target_changed.emit("")


func _update_walk_visual(_delta: float) -> void:
	var is_walking := absf(velocity.x) > 8.0 and is_on_floor()
	if is_walking:
		character_sprite.hide()
		walk_sprite.show()
		if not walk_sprite.is_playing():
			walk_sprite.play("walk")
	else:
		walk_sprite.stop()
		walk_sprite.hide()
		character_sprite.show()


func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
