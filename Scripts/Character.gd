# character.gd
extends Node2D
class_name Character

signal clicked(character: Character)

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var info_label: Label = $InfoLabel

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
	
	update_ui()
	print("已加载角色数据: ", stats.character_name)

func update_ui():
	if info_label:
		info_label.text = "%s\nHP: %d/%d" % [stats.character_name, health, stats.max_health]

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_mouse_over():
			clicked.emit(self)

# 简单的矩形检测：判断鼠标是否在角色精灵范围内
func is_mouse_over() -> bool:
	if not anim: return false
	# Kenney 资源的精灵大小约为 96x128，我们给一个稍大的点击判定区
	var mouse_pos = anim.get_local_mouse_position()
	return abs(mouse_pos.x) < 50 and abs(mouse_pos.y) < 70

func take_damage(damage: int):
	health = clampi(health - damage, 0, stats.max_health)
	update_ui()
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
