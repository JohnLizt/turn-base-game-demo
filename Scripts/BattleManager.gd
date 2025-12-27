extends Node

# 战斗管理器 - 控制整个回合制战斗流程

# 信号：用于UI更新
signal turn_changed(current_character: Character)  # 回合改变
signal battle_ended(winner: Character)  # 战斗结束

# 角色数组
@export var player_nodes: Array[Character]
@export var enemy_nodes: Array[Character]

# 行动队列
var action_queue: Array[Character] = []
var current_character: Character = null

func _ready():
	# 等待一帧，确保所有 Character 节点的 _ready() 都执行完毕
	await get_tree().process_frame
	
	# 初始化战斗：将所有角色按速度（或预设顺序）加入队列
	# 从场景中获取玩家和敌人节点
	var players_node = get_node("../Players")
	var enemies_node = get_node("../Enemies")
	
	# 添加玩家角色（目前只有一个）
	if players_node:
		var player = players_node.get_node("MainControl")
		if player and player is Character:
			player_nodes.append(player)
	
	# 添加敌人角色（目前只有一个）
	if enemies_node:
		var enemy = enemies_node.get_node("Enemy")
		if enemy and enemy is Character:
			enemy_nodes.append(enemy)
	
	setup_queue()
	next_turn()

# 1. 回合相关逻辑

func setup_queue():
	action_queue.clear()
	# 合并两方并排序（这里简单合并，实际可以按 stats.speed 排序）
	action_queue.append_array(player_nodes)
	action_queue.append_array(enemy_nodes)

func next_turn():
	# 1. 检查战斗是否结束
	if check_battle_over(): return
	
	# 2. 获取下一个行动者
	if action_queue.is_empty():
		setup_queue() # 一轮结束，重置队列
		
	current_character = action_queue.pop_front()
	
	# 3. 如果角色已死亡，跳过
	if not current_character.is_alive():
		next_turn()
		return
		
	# 4. 通知 UI 更新状态 
	turn_changed.emit(current_character)
	print("当前轮到: " + current_character.stats.character_name)
	
	# 5. 如果是敌人，自动执行 AI
	if current_character in enemy_nodes:
		execute_enemy_ai()

func is_player_turn() -> bool:
	return current_character in player_nodes

func is_enemy_turn() -> bool:
	return current_character in enemy_nodes

# 2. 战斗结算相关逻辑

func check_battle_over() -> bool:
	var players_alive = player_nodes.any(func(c): return c.is_alive())
	var enemies_alive = enemy_nodes.any(func(c): return c.is_alive())
	
	if not enemies_alive:
		battle_ended.emit(player_nodes[0]) # 玩家胜
		return true
	if not players_alive:
		battle_ended.emit(enemy_nodes[0]) # 敌人胜
		return true
	return false

# 3. 战斗相关逻辑

# 玩家攻击逻辑
func player_attack(target: Character):
	if current_character not in player_nodes: return
	# 执行逻辑 
	await current_character.play_attack_animation()
	target.take_damage(current_character.stats.attack_power)
	
	next_turn()

func execute_enemy_ai():
	await get_tree().create_timer(1.0).timeout
	# 简单 AI：随机打一个玩家
	var target = player_nodes.pick_random()
	await current_character.play_attack_animation()
	target.take_damage(current_character.stats.attack_power)
	
	next_turn()
	
# 效果：插入额外回合
func grant_extra_turn(character: Character):
	action_queue.push_front(character) # 插到队列最前面
	print(character.stats.character_name + " 获得了额外回合！")
	
