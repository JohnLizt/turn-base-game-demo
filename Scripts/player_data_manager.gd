extends Node

# 全局玩家数据模型
var hero_stats: HeroData

# 全局实时状态
var health: int
var stress: int
var death_resist: float

# 初始化玩家（通常在游戏开始或加载存档时）
func init_player(data: HeroData):
	hero_stats = data
	health = data.max_health
	stress = 0
	death_resist = data.death_resist
	print("全局玩家状态已初始化: ", data.character_name)

# 从战斗后的 Hero 实例更新全局状态
func update_state(hero: Hero):
	health = hero.health
	stress = hero.stress
	print("全局玩家状态已更新: HP=", health, " Stress=", stress)
