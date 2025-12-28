# Hero.gd
extends Character
class_name Hero

# 运行时压力值
var stress: int = 0
var current_death_resist: float = 1.0
var is_dead: bool = false

func _ready():
	# 调用父类的初始化逻辑
	super._ready()
	
	# 如果 stats 是 HeroData 类型，可以进行额外初始化
	if stats is HeroData:
		stress = 0
		current_death_resist = stats.death_resist

# 重写 UI 更新，增加压力值显示
func update_ui():
	if info_label and stats:
		if is_dead:
			info_label.text = "%s\n[已阵亡]" % stats.character_name
			return

		var hp_display = str(health) + "/" + str(stats.max_health)
		if health <= 0:
			hp_display = "破防 (0/" + str(stats.max_health) + ")"
		var text = "%s\nHP: %s AP: %d" % [stats.character_name, hp_display, action_point]
		
		text += "\nStress: %d/%d (DR: %d%%)" % [stress, stats.max_stress, int(current_death_resist * 100)]
			
		info_label.text = text

# 重写伤害逻辑
func take_damage(damage: int):
	if is_dead: return
	
	if health > 0:
		health = clampi(health - damage, 0, stats.max_health)
		print(stats.character_name, " 受到 ", damage, " 点伤害，剩余HP：", health)
		if health == 0:
			print(stats.character_name, " 进入破防状态！")
	else:
		# 破防状态下受到攻击，直接增加压力
		add_stress(damage)
	
	update_ui()

# 重写存活判断
func is_alive() -> bool:
	return not is_dead

# 压力增加
func add_stress(amount: int):
	if is_dead: return
	
	if stats is HeroData:
		stress = clampi(stress + amount, 0, stats.max_stress)
		print(stats.character_name, " 压力增加了 ", amount, "，当前压力：", stress)
		
		if stress >= stats.max_stress:
			trigger_death_blow_check()
		
		update_ui()

# 死亡判定
func trigger_death_blow_check():
	print(stats.character_name, " 压力已满，触发死亡判定！当前抗性：", int(current_death_resist * 100), "%")
	
	var roll = randf() # 0.0 ~ 1.0
	if roll < current_death_resist:
		# 通过判定，幸存
		current_death_resist = maxf(0.0, current_death_resist - 0.2)
		# 将压力降回最大值的 80% 或保持满值，这里按照通常设计，
		# 既然是通过了“死门”判定，我们保持满压力，但减少抗性
		print(stats.character_name, " 挺过来了！死亡抗性下降到：", int(current_death_resist * 100), "%")
	else:
		# 判定失败，死亡
		is_dead = true
		print(stats.character_name, " 压力过大，心脏骤停！")
