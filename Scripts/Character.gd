# character.gd
extends Node
class_name Character

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# 在编辑器中拖入你的 .tres 文件
@export var stats: CharacterData

# 运行时实际使用的动态数值
var health: int

func _ready():
	if not stats: push_error("Character 节点未绑定 stats 数据！")
	
	# 从 Resource 中克隆/读取初始值
	health = stats.max_health
	
	# 动态加载角色肖像（如果需要显示的话，可以在这里处理）
	# portrait 暂未使用
	
	# 动态加载攻击动画
	if stats.attack_animation and anim:
		anim.sprite_frames = stats.attack_animation
	else:
		push_warning("角色 " + stats.character_name + " 未设置攻击动画！")
	
	print("已加载角色数据: ", stats.character_name)
		

func take_damage(damage: int):
	health = clampi(health - damage, 0, stats.max_health)
	print(stats.character_name, " 受到 ", damage, " 点伤害，剩余血量：", health)

func is_alive() -> bool:
	return health > 0

func play_attack_animation():
	# 确保动画资源已加载
	if not anim: push_warning("AnimatedSprite2D 或 SpriteFrames 未设置") 
	if (not anim.sprite_frames) or (not anim.sprite_frames.has_animation("attack")):
		push_warning("攻击动画 'attack' 不存在于 SpriteFrames 中")
		
	anim.play("attack")
	await anim.animation_finished
