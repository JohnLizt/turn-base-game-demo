extends Skill

func _init():
	skill_name = "旋风斩"
	description = "横扫所有敌人，造成基础伤害。"
	target_type = TargetType.ALL
	damage = 1
	animation_name = "attack"

func execute(user: Character, targets: Array[Character]):
	# 调用基类 execute 执行通用的全体伤害和压力消耗逻辑
	super.execute(user, targets)
