extends Node
class_name Character

# 角色类 - 玩家和敌人都使用这个脚本

@export var character_name: String = "角色"
@export var max_health: int = 100
@export var attack_power: int = 20

var health: int = 100

func _ready():
	# 初始化血量
	health = max_health

# 受到伤害
func take_damage(damage: int):
	health -= damage
	if health < 0:
		health = 0
	print(character_name, " 受到 ", damage, " 点伤害，剩余血量：", health)

# 是否存活
func is_alive() -> bool:
	return health > 0
