extends Control

# 战斗场景UI控制脚本

@onready var battle_manager = $BattleManager
@onready var turn_label = $UI/TurnLabel
@onready var skill_container = $UI/SkillContainer
@onready var end_turn_button = $UI/EndTurnButton
@onready var status_label = $UI/StatusLabel
@onready var background = $Background

# 状态
var is_selecting_target: bool = false
var selected_skill: Skill = null

# 角色预制体场景路径
var character_prefab: PackedScene = load("res://Scenes/character_2d.tscn")


# 初始化场景
func setup_battle(player_team: Array[HeroData], enemy_team: Array[CharacterData], bg_texture: Texture2D):
	# 更换背景 
	if background and bg_texture:
		background.texture = bg_texture
	
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
	
	if battle_manager.is_player(current_character):
		end_turn_button.show()
		for skill in current_character.stats.skills:
			var btn = Button.new()
			btn.text = skill.skill_name
			
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
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_selecting_target and selected_skill:
			var type = selected_skill.target_type
			if type == Skill.TargetType.ENEMY_ALL:
				_execute_selected_skill(battle_manager.get_alive_enemies())
			elif type == Skill.TargetType.ALLY_ALL:
				_execute_selected_skill(battle_manager.get_alive_players())
			elif type == Skill.TargetType.SELF:
				_execute_selected_skill([battle_manager.current_character])

# 统一执行已选技能的逻辑
func _execute_selected_skill(targets: Array[Character]):
	is_selecting_target = false
	var skill = selected_skill
	selected_skill = null
	battle_manager.use_skill(skill, targets)
