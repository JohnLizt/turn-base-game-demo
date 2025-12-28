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


# 0.初始化相关逻辑

# 初始化战斗：从外部传入数据动态创建角色
func init_battle(player_team: Array[HeroData], enemy_team: Array[CharacterData], prefab: PackedScene):
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
		var hero_data = player_team[i]
		var hero_instance = create_character(hero_data, i, true)
		if hero_instance:
			add_child(hero_instance)
			players.append(hero_instance)
	
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
func create_character(character_data: CharacterData, index: int, _is_player: bool) -> Character:
	if not character_prefab:
		push_error("角色预制体未设置！")
		return null
	
	var instance = character_prefab.instantiate()
	
	# 根据数据类型动态绑定脚本
	if character_data is HeroData:
		instance.set_script(load("res://Scripts/Hero.gd"))
	
	if not instance is Character:
		push_error("预制体不是 Character 类型！")
		return null
	
	# 设置角色数据
	instance.stats = character_data
	
	# 设置位置（斜方向由近到远排列）
	# 近处点：(250, 280)，远处点会向屏幕上方和两边偏移
	var x_start: float
	var x_offset: float
	var y_offset: float = -60 # 越远越往上靠（Y轴减小）

	if _is_player:
		x_start = -250
		x_offset = -80  # 越远越往左靠
	else:
		x_start = 250
		x_offset = 80   # 越远越往右靠
		# 延迟到进入场景树后翻转精灵，避免 UI 镜像
		instance.ready.connect(func(): if instance.anim: instance.anim.flip_h = true)
	
	instance.position = Vector2(
		x_start + (index * x_offset), 
		250 + (index * y_offset)
	)
	
	# 设置显示层级：近处的角色显示在远处角色前面
	instance.z_index = 10 - index
	
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
	
	# 3. 重置行动力
	current_character.action_point = current_character.stats.max_action_point
	current_character.update_ui()
	
	# 4. 如果角色已死亡，跳过
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
		push_error("没有玩家/敌人！")
		return true
	
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

# 执行技能
func use_skill(skill: Skill, targets: Array[Character]):
	if not current_character or targets.is_empty(): return
	
	# 1. 播放动画
	await current_character.play_attack_animation()
	
	# 2. 执行技能逻辑
	skill.execute(current_character, targets)
	
	# 3. 检查战斗是否结束
	if check_battle_over(): return

	# 4. 检查行动力
	if current_character.action_point <= 0:
		next_turn()
	else:
		# 还有行动力，如果是敌人，继续执行 AI
		if is_enemy(current_character):
			await execute_enemy_ai()
		else:
			# 如果是玩家，通过信号通知 UI 更新（可以继续选技能）
			turn_changed.emit(current_character)

func execute_enemy_ai():
	# 延迟一点时间，避免动作太快
	#await get_tree().create_timer(0.5).timeout
	
	# 简单 AI：如果有技能就用第一个，否则随机打
	if current_character.stats.skills.size() > 0:
		var skill = current_character.stats.skills[0]
		var targets: Array[Character] = []
		
		match skill.target_type:
			Skill.TargetType.SELF:
				targets = [current_character]
			Skill.TargetType.ALLY_ALL:
				targets = enemies.filter(func(c): return c.is_alive())
			Skill.TargetType.ENEMY_ALL:
				targets = players.filter(func(c): return c.is_alive())
			Skill.TargetType.ALLY_SINGLE:
				targets = [enemies.pick_random()] # 敌人的队友就是 enemies 数组
			Skill.TargetType.ENEMY_SINGLE:
				var alive_players = players.filter(func(c): return c.is_alive())
				if not alive_players.is_empty():
					targets = [alive_players.pick_random()]
			
		if not targets.is_empty():
			use_skill(skill, targets)
		else:
			next_turn()
	else:
		push_error("敌人没有技能！")
	
# 效果：插入额外回合
func grant_extra_turn(character: Character):
	action_queue.push_front(character) # 插到队列最前面
	print(character.stats.character_name + " 获得了额外回合！")
	
# 接口方法：获取所有参与战斗的角色
func get_all_characters() -> Array[Character]:
	var all: Array[Character] = []
	all.append_array(players)
	all.append_array(enemies)
	return all

# 接口方法：判断角色是否属于敌人阵营
func is_enemy(character: Character) -> bool:
	return character in enemies

# 接口方法：判断角色是否属于玩家阵营
func is_player(character: Character) -> bool:
	return character in players

# 接口方法：获取所有存活的敌人
func get_alive_enemies() -> Array[Character]:
	var list: Array[Character] = []
	list.assign(enemies.filter(func(c): return c.is_alive()))
	return list

# 接口方法：获取所有存活的玩家
func get_alive_players() -> Array[Character]:
	var list: Array[Character] = []
	list.assign(players.filter(func(c): return c.is_alive()))
	return list
