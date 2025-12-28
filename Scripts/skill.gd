# skill.gd
extends Resource
class_name Skill

enum TargetType { SINGLE, ALL }

@export var skill_name: String = "未命名技能"
@export var description: String = ""
@export var damage: int = 1
@export var stress_cost: int = 0
@export var target_type: TargetType = TargetType.SINGLE
@export var animation_name: String = "attack" # 对应 Character 的动画名

# 核心：定义一个虚函数，让子类去实现具体逻辑
func execute(user: Character, targets: Array[Character]):
	print(user.stats.character_name, " 使用了 ", skill_name)
	
	# 通用逻辑：技能造成压力值增加
	if user is Hero and stress_cost > 0:
		user.add_stress(stress_cost)
	# 通用逻辑：根据 damage 乘数和用户攻击力造成伤害
	for target in targets:
		var final_damage = user.stats.attack_power * damage
		target.take_damage(final_damage)
