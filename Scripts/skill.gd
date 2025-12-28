# skill.gd
extends Resource
class_name Skill

enum TargetType { SELF, ALLY_SINGLE, ALLY_ALL, ENEMY_SINGLE, ENEMY_ALL }

@export var skill_name: String = "未命名技能"
@export var description: String = ""
@export var damage: int = 0
@export var action_cost: int = 0
@export var health_cost: int = 0
@export var stress_cost: int = 0
@export var target_type: TargetType = TargetType.SELF
@export var animation_name: String = "attack" # 对应 Character 的动画名


func execute(user: Character, targets: Array[Character]):
	prepare(user)
	
	if (damage > 0):
		var final_damage = user.stats.attack_power * damage
		for target in targets:
			target.take_damage(final_damage)


func prepare(user: Character):
	print(user.stats.character_name, " 使用了 ", skill_name)
	
	# 通用逻辑：技能消耗
	if action_cost > 0:
		user.action_point -= action_cost
	
	if health_cost > 0:
		user.take_damage(health_cost)
	
	if user is Hero and stress_cost > 0:
		user.add_stress(stress_cost)
	
	user.update_ui()
