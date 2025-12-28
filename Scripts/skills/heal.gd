extends Skill

@export var heal_amount: int = 5

func execute(user: Character, targets: Array[Character]):
	# 调用父类的 prepare 处理消耗（如 action_cost, stress_cost 等）
	super.prepare(user)
	
	# 治疗逻辑
	for target in targets:
		target.health = clampi(target.health + heal_amount, 0, target.stats.max_health)
		target.update_ui()
		print(target.stats.character_name, " 治疗了 ", heal_amount, " 点生命值，当前：", target.health)

