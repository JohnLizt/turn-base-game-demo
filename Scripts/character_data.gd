# character_data.gd
extends Resource
class_name CharacterData

@export var character_name: String = "未定义角色"
@export var portrait: Texture2D # 角色肖像/立绘
@export var attack_animation: SpriteFrames # 攻击动画
@export var skills: Array[Skill] = [] # 技能列表

# 数值
@export var max_health: int = 10
@export var attack_power: int = 1
@export var max_action_point: int = 1
