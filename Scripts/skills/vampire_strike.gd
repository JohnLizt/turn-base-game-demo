extends Skill
# 这种脚本专门处理特殊逻辑

func execute(user: Character, targets: Array[Character]):
	super.prepare(user)
	
	for target in targets:
		# 计算伤害（使用自身的 damage 属性）
		var dmg = int(user.stats.attack_power * damage)
		target.take_damage(dmg)
		
		# 计算吸血量（100%）
		var heal_amount = int(dmg * 1.0)
		user.health = clampi(user.health + heal_amount, 0, user.stats.max_health)
		user.update_ui()
		print(user.stats.character_name, " 吸取了 ", heal_amount, " 点HP")
