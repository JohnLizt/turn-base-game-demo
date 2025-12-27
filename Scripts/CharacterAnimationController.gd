extends CharacterBody2D

# 角色动画控制器 - 控制角色动画播放

@export var attack_animation_name: String = "default"  # 攻击动画名称，可在编辑器中设置

@onready var animated_sprite = $AnimatedSprite2D

# 播放攻击动画
func play_attack_animation():
	if animated_sprite and animated_sprite.sprite_frames:
		# 检查动画是否存在
		var animation_to_play = attack_animation_name
		if not animated_sprite.sprite_frames.has_animation(attack_animation_name):
			# 如果没有指定的攻击动画，使用默认动画
			animation_to_play = "default"
		
		# 确保攻击动画只播放一次（设置为不循环）
		var animation_loop = animated_sprite.sprite_frames.get_animation_loop(animation_to_play)
		animated_sprite.sprite_frames.set_animation_loop(animation_to_play, false)
		
		# 播放攻击动画
		animated_sprite.play(animation_to_play)
		
		# 等待动画播放完成
		await animated_sprite.animation_finished
		
		# 恢复动画的循环设置（如果之前是循环的）
		animated_sprite.sprite_frames.set_animation_loop(animation_to_play, animation_loop)
