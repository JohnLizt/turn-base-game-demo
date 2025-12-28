extends Node2D

# 战斗管理器 - 控制整个回合制战斗流程

# 信号：用于UI更新
signal turn_changed(current_character: Character)  # 回合改变
signal battle_ended(winner: Character)  # 战斗结束

# 角色数组
var players: Array[Character] = []
var enemies: Array[Character] = []

# 行动队列
var action_queue: Array[Character] = []
var current_character: Character = null

# 角色预制体场景
var character_prefab: PackedScene


# 初始化战斗：从外部传入数据动态创建角色
func init_battle(player_team: Array[CharacterData], enemy_team: Array[CharacterData], prefab: PackedScene):
	character_prefab = prefab
	
	# 等待一帧，确保场景树完全加载
	await get_tree().process_frame
	
	# 清理旧节点（如果有）
	for child in get_children():
		child.queue_free()
	
	players.clear()
	enemies.clear()
	
	# 动态创建玩家角色
	for i in range(player_team.size()):
		var character_data = player_team[i]
		var character_instance = create_character(character_data, i, true)
		if character_instance:
			add_child(character_instance)
			players.append(character_instance)
	
	# 动态创建敌人角色
	for i in range(enemy_team.size()):
		var character_data = enemy_team[i]
		var character_instance = create_character(character_data, i, false)
		if character_instance:
			add_child(character_instance)
			enemies.append(character_instance)
	
	# 等待所有角色初始化完成
	await get_tree().process_frame
	
	# 开始战斗
	setup_queue()
	next_turn()

# 创建角色实例
func create_character(character_data: CharacterData, index: int, is_player: bool) -> Character:
	if not character_prefab:
		push_error("角色预制体未设置！")
		return null
	
	var instance = character_prefab.instantiate()
	if not instance is Character:
		push_error("预制体不是 Character 类型！")
		return null
	
	# 设置角色数据
	instance.stats = character_data
	
	# 设置位置（玩家在左侧，敌人在右侧）
	if is_player:
		instance.position = Vector2(-250 - index * 100, 250)
	else:
		instance.position = Vector2(250 + index * 100, 250)
		# 敌人翻转
		instance.scale.x = -1
	
	return instance

# 1. 回合相关逻辑

func setup_queue():
	action_queue.clear()
	# 合并两方并排序（这里简单合并，实际可以按 stats.speed 排序）
	action_queue.append_array(players)
	action_queue.append_array(enemies)

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
	if current_character in enemies:
		execute_enemy_ai()

func is_player_turn() -> bool:
	return current_character in players

func is_enemy_turn() -> bool:
	return current_character in enemies

# 2. 战斗结算相关逻辑

func check_battle_over() -> bool:
	if players.is_empty() or enemies.is_empty():
		return false
	
	var players_alive = players.any(func(c): return c.is_alive())
	var enemies_alive = enemies.any(func(c): return c.is_alive())
	
	if not enemies_alive and players.size() > 0:
		battle_ended.emit(players[0]) # 玩家胜
		return true
	if not players_alive and enemies.size() > 0:
		battle_ended.emit(enemies[0]) # 敌人胜
		return true
	return false

# 3. 战斗相关逻辑

# 玩家攻击逻辑
func player_attack(target: Character):
	if current_character not in players: return
	# 执行逻辑 
	await current_character.play_attack_animation()
	target.take_damage(current_character.stats.attack_power)
	
	next_turn()

func execute_enemy_ai():
	# 简单 AI：随机打一个玩家
	if players.is_empty():
		push_warning("没有可攻击的玩家！")
		next_turn()
		return
		
	var target = players.pick_random()
	await current_character.play_attack_animation()
	target.take_damage(current_character.stats.attack_power)
	
	next_turn()
	
# 效果：插入额外回合
func grant_extra_turn(character: Character):
	action_queue.push_front(character) # 插到队列最前面
	print(character.stats.character_name + " 获得了额外回合！")
	
