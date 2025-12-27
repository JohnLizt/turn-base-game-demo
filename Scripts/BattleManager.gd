extends Node

# 战斗管理器 - 控制整个回合制战斗流程

# 信号：用于UI更新
signal turn_changed(current_turn)  # 回合改变
signal battle_ended(winner)  # 战斗结束
signal player_attack_animation()  # 玩家攻击动画
signal enemy_attack_animation()  # 敌人攻击动画

# 战斗单位数组
var characters: Array = []
var enemies: Array = []
var current_turn_index: int = 0
var is_player_turn: bool = true

# 引用场景中的节点
@onready var player: Node = null
@onready var enemy: Node = null

func _ready():
	# 延迟初始化战斗，确保所有节点都已准备好
	await get_tree().process_frame
	start_battle()

func start_battle():
	# 查找场景中的角色和敌人（BattleManager、Player、Enemy都是root的子节点）
	var parent = get_parent()
	if parent:
		player = parent.get_node("Player") if parent.has_node("Player") else null
		enemy = parent.get_node("Enemy") if parent.has_node("Enemy") else null
	
	if player:
		characters.append(player)
	if enemy:
		enemies.append(enemy)
	
	# 开始玩家回合
	is_player_turn = true
	current_turn_index = 0
	turn_changed.emit("玩家")

# 玩家攻击
func player_attack():
	if not is_player_turn or not player or not enemy:
		return
	
	# 发送玩家攻击动画信号
	player_attack_animation.emit()
	
	# 玩家攻击敌人
	var damage = player.attack_power
	print("玩家攻击！造成 ", damage, " 点伤害")
	enemy.take_damage(damage)
	
	# 等待一小段时间让UI更新
	await get_tree().create_timer(0.5).timeout
	
	# 检查敌人是否死亡
	if enemy.health <= 0:
		end_battle("玩家")
		return
	
	# 切换到敌人回合
	switch_to_enemy_turn()

# 切换到敌人回合
func switch_to_enemy_turn():
	is_player_turn = false
	turn_changed.emit("敌人")
	
	# 延迟后敌人自动攻击
	await get_tree().create_timer(1.0).timeout
	enemy_attack()

# 敌人攻击
func enemy_attack():
	if is_player_turn or not player or not enemy:
		return
	
	# 发送敌人攻击动画信号
	enemy_attack_animation.emit()
	
	# 敌人攻击玩家
	var damage = enemy.attack_power
	print("敌人攻击！造成 ", damage, " 点伤害")
	player.take_damage(damage)
	
	# 等待一小段时间让UI更新
	await get_tree().create_timer(0.5).timeout
	
	# 检查玩家是否死亡
	if player.health <= 0:
		end_battle("敌人")
		return
	
	# 切换回玩家回合
	switch_to_player_turn()

# 切换到玩家回合
func switch_to_player_turn():
	is_player_turn = true
	turn_changed.emit("玩家")

# 结束战斗
func end_battle(winner: String):
	print("战斗结束！胜利者：", winner)
	battle_ended.emit(winner)
