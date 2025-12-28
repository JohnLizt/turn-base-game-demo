extends Resource
class_name Skill

@export var skill_name: String = "未命名技能"
@export var description: String = ""
@export var hp_cost: int = 10
@export var animation_name: String = "attack" # 对应 Character 的动画名

# 核心：定义一个虚函数，让子类去实现具体逻辑
func execute(user: Character, targets: Array[Character]):
	print(user.stats.character_name, " 使用了 ", skill_name)
	# 通用逻辑：扣除血量等
