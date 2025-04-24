class_name TestChar
extends BaseCharacter

#var is_attack_animation_playing := false

#func _physics_process(delta):
	#super._physics_process(delta)
	#if is_attack_animation_playing:
		#match previous_state:
			#CharacterState.WALK:
				#handle_walk_state(delta)
			#CharacterState.IDLE:
				#handle_idle_state(delta)

func handle_attack_state():
	if not can_attack or is_attacking:
		return
	can_attack = false
	previous_state = current_state
	current_state = CharacterState.ATTACK
	#is_attack_animation_playing = true
	
	if anim_player.has_animation('1H_Ranged_Shoot'):
		anim_player.play('1H_Ranged_Shoot')


	if ray_cast.is_colliding():
		var target = ray_cast.get_collider()
		if target.has_method('take_damage') and target != self:
			var damage = character_resource.stats['attack_damage']
			target.take_damage(damage, self)
			show_hit_effect(ray_cast.get_collision_point())
	await get_tree().process_frame
	await anim_player.animation_finished
	
	current_state = previous_state

	await get_tree().create_timer(character_resource.stats['attack_cooldown']).timeout
	can_attack = true


func show_hit_effect(position: Vector3):
	# Создаем временный маркер попадания
	var hit_effect = MeshInstance3D.new()
	hit_effect.mesh = SphereMesh.new()
	hit_effect.mesh.radius = 0.1
	hit_effect.mesh.height = 0.2
	hit_effect.position = position
	get_tree().root.add_child(hit_effect)

	# Удаляем через 0.5 секунды
	await get_tree().create_timer(0.5).timeout
	hit_effect.queue_free()
