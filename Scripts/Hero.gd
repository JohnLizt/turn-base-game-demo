# Hero.gd
extends Character
class_name Hero

# 运行时压力值
var stress: int = 0

func _ready():
	# 调用父类的初始化逻辑
	super._ready()
	
	# 如果 stats 是 HeroData 类型，可以进行额外初始化
	# 注意：Character._ready() 已经调用了 update_ui()
	# 但由于多态，它会调用下面这个重写后的 update_ui()
	pass

# 重写 UI 更新，增加压力值显示
func update_ui():
	if info_label and stats:
		var text = "%s\nHP: %d/%d" % [stats.character_name, health, stats.max_health]
		
		# 如果是英雄数据，额外显示压力值
		if stats is HeroData:
			text += "\nStress: %d/%d" % [stress, stats.max_stress]
			
		info_label.text = text

# 增加压力的方法
func add_stress(amount: int):
	if stats is HeroData:
		stress = maxi(0, stress + amount)
		update_ui()
		print(stats.character_name, " 压力变化了 ", amount, "，当前压力：", stress)
