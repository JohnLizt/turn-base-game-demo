extends Control

# 战斗场景UI控制脚本

@onready var battle_manager = $BattleManager
@onready var turn_label = $UI/TurnLabel
@onready var skill_container = $UI/SkillContainer
@onready var end_turn_button = $UI/EndTurnButton
@onready var status_label = $UI/StatusLabel
@onready var background = $Background
@onready var return_map_button = $UI/ReturnMapButton

# 状态
var is_selecting_target: bool = false
var selected_skill: Skill = null
var current_skills: Array[Skill] = [] # 当前显示的技能列表，用于快捷键映射

# 角色预制体场景路径
var character_prefab: PackedScene = load("res://Scenes/character_2d.tscn")


# 初始化场景
func setup_battle(player_team: Array[HeroData], enemy_team: Array[CharacterData], bg_texture: Texture2D):
	# 更换背景 
	if background and bg_texture:
		background.texture = bg_texture
	
	# 隐藏返回按钮
	if return_map_button:
		return_map_button.hide()
		if not return_map_button.pressed.is_connected(_on_return_map_pressed):
			return_map_button.pressed.connect(_on_return_map_pressed)
	
	# 告诉 BattleManager 本次战斗的数据（BattleManager 会负责清理和创建节点）
	await battle_manager.init_battle(player_team, enemy_team, character_prefab)
	
	# 连接所有角色的点击信号
	for c in battle_manager.get_all_characters():
		if not c.clicked.is_connected(_on_character_clicked):
			c.clicked.connect(_on_character_clicked)
	
	# 连接结束回合按钮
	if not end_turn_button.pressed.is_connected(_on_end_turn_button_pressed):
		end_turn_button.pressed.connect(_on_end_turn_button_pressed)


# 回合改变
func _on_turn_changed(current_character: Character):
	if not turn_label:
		return
	turn_label.text = "当前回合：" + current_character.stats.character_name
	
	# 重置选择状态
	is_selecting_target = false
	selected_skill = null
	
	# 清理并创建技能按钮
	for child in skill_container.get_children():
		child.queue_free()
	current_skills.clear()
	
	if battle_manager.is_player(current_character):
		end_turn_button.show()
		var key_names = ["Q", "W", "E", "R"]
		var skills = current_character.stats.skills
		
		for i in range(min(skills.size(), 4)): # UI最多显示4个技能
			var skill = skills[i]
			current_skills.append(skill)
			
			var btn = Button.new()
			btn.text = "[%s] %s" % [key_names[i], skill.skill_name]
			
			# 构建技能详情提示
			var tooltip = "[%s]\n%s\n消耗 AP: %d" % [skill.skill_name, skill.description, skill.action_cost]
			if skill.damage > 0:
				tooltip += "\n伤害倍率: %d" % skill.damage
			if skill.stress_cost > 0:
				tooltip += "\n压力消耗: %d" % skill.stress_cost
			if skill.health_cost > 0:
				tooltip += "\n生命消耗: %d" % skill.health_cost
			
			# AP 检查
			if current_character.action_point < skill.action_cost:
				btn.disabled = true
				btn.tooltip_text = "【AP不足】\n" + tooltip
			else:
				btn.tooltip_text = tooltip
			
			btn.pressed.connect(_on_skill_button_pressed.bind(skill))
			skill_container.add_child(btn)
		status_label.text = "请选择技能"
	else:
		end_turn_button.hide()
		status_label.text = "敌人正在行动..."


# 战斗结束
func _on_battle_ended(winner: Character):
	# 清理所有技能按钮
	for child in skill_container.get_children():
		child.queue_free()
	
	# 更新状态显示
	if status_label:
		status_label.text = "战斗结束！胜利者：" + winner.stats.character_name
	
	if turn_label:
		turn_label.text = "战斗结束"
	
	# 重置选择状态
	is_selecting_target = false
	selected_skill = null
	current_skills.clear() # 清理快捷键映射
	
	# 隐藏结束回合按钮
	if end_turn_button:
		end_turn_button.hide()
	
	# 战斗结束后，更新全局 Player 状态
	var alive_players = battle_manager.get_alive_players()
	if not alive_players.is_empty():
		var player_hero = alive_players[0] as Hero
		PlayerDataManager.update_state(player_hero)
	
	# 显示返回按钮
	if return_map_button:
		return_map_button.show()


func _on_return_map_pressed():
	# 找到 map 场景并恢复显示
	var map = get_tree().root.find_child("Map", true, false)
	if map:
		map.visible = true
		# 强制地图角色更新一下 UI（同步刚才战斗后的状态）
		if "map_player" in map and map.map_player:
			map.map_player.visible = true
			map.map_player.health = PlayerDataManager.health
			map.map_player.stress = PlayerDataManager.stress
			map.map_player.current_death_resist = PlayerDataManager.death_resist
			map.map_player.update_ui()
		# 恢复地图 UI
		if "menu_ui" in map and map.menu_ui:
			map.menu_ui.visible = true
	
	# 销毁当前战斗场景
	queue_free()


func _on_skill_button_pressed(skill: Skill):
	if not battle_manager.is_player_turn(): return
	
	# 如果点击已选中的技能，取消选择
	if selected_skill == skill:
		is_selecting_target = false
		selected_skill = null
		status_label.text = "请选择技能"
		return
		
	selected_skill = skill
	
	match skill.target_type:
		Skill.TargetType.SELF:
			status_label.text = "对自身使用: " + skill.skill_name
		Skill.TargetType.ALLY_ALL:
			status_label.text = "对我方全体: " + skill.skill_name
		Skill.TargetType.ENEMY_ALL:
			status_label.text = "对敌方全体: " + skill.skill_name
		Skill.TargetType.ALLY_SINGLE:
			status_label.text = "请选择我方目标: " + skill.skill_name
		Skill.TargetType.ENEMY_SINGLE:
			status_label.text = "请选择敌方目标: " + skill.skill_name
	is_selecting_target = true


# 处理结束回合按钮
func _on_end_turn_button_pressed():
	if battle_manager.is_player_turn():
		is_selecting_target = false
		selected_skill = null
		battle_manager.next_turn()

# 处理角色点击
func _on_character_clicked(target: Character):
	if is_selecting_target and selected_skill:
		var type = selected_skill.target_type
		
		if type == Skill.TargetType.ENEMY_ALL:
			_execute_selected_skill(battle_manager.get_alive_enemies())
		elif type == Skill.TargetType.ALLY_ALL:
			_execute_selected_skill(battle_manager.get_alive_players())
		elif type == Skill.TargetType.ENEMY_SINGLE:
			if battle_manager.is_enemy(target) and target.is_alive():
				_execute_selected_skill([target])
		elif type == Skill.TargetType.ALLY_SINGLE:
			if battle_manager.is_player(target) and target.is_alive():
				_execute_selected_skill([target])
		elif type == Skill.TargetType.SELF:
			if battle_manager.is_player(target) and target.is_alive():
				_execute_selected_skill([target])

# 处理背景点击（未被角色或 UI 拦截的点击）
func _unhandled_input(event):
	# 键盘快捷键 QWER
	if battle_manager.is_player_turn() and event is InputEventKey and event.pressed and not event.is_echo():
		match event.keycode:
			KEY_Q: _try_use_skill_by_index(0)
			KEY_W: _try_use_skill_by_index(1)
			KEY_E: _try_use_skill_by_index(2)
			KEY_R: _try_use_skill_by_index(3)

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_selecting_target and selected_skill:
			var type = selected_skill.target_type
			if type == Skill.TargetType.ENEMY_ALL:
				_execute_selected_skill(battle_manager.get_alive_enemies())
			elif type == Skill.TargetType.ALLY_ALL:
				_execute_selected_skill(battle_manager.get_alive_players())
			elif type == Skill.TargetType.SELF:
				_execute_selected_skill([battle_manager.current_character])

# 尝试通过索引释放技能（用于快捷键）
func _try_use_skill_by_index(index: int):
	if index < current_skills.size():
		var skill = current_skills[index]
		# 只有 AP 足够时才触发
		if battle_manager.current_character.action_point >= skill.action_cost:
			_on_skill_button_pressed(skill)
		else:
			print("AP不足，无法使用快捷键技能")

# 统一执行已选技能的逻辑
func _execute_selected_skill(targets: Array[Character]):
	is_selecting_target = false
	var skill = selected_skill
	selected_skill = null
	battle_manager.use_skill(skill, targets)
