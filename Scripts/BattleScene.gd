extends Control

# 战斗场景UI控制脚本

@onready var battle_manager = $BattleManager
@onready var turn_label = $UI/TurnLabel
@onready var player_info = $UI/PlayerInfo
@onready var enemy_info = $UI/EnemyInfo
@onready var attack_button = $UI/AttackButton
@onready var status_label = $UI/StatusLabel
@onready var background = $Background

# 角色引用（动态获取）
var player: Character = null
var enemy: Character = null

# 角色预制体场景路径
var character_prefab: PackedScene = load("res://Scenes/character_2d.tscn")

func setup_battle(player_team: Array[CharacterData], enemy_team: Array[CharacterData], bg_texture: Texture2D):
	# 1. 更换背景 
	if background and bg_texture:
		background.texture = bg_texture
	
	# 2. 告诉 BattleManager 本次战斗的数据（BattleManager 会负责清理和创建节点）
	battle_manager.init_battle(player_team, enemy_team, character_prefab)
	
	# 3. 等待角色创建完成后，获取角色引用（暂时一个角色）
	await get_tree().process_frame
	if battle_manager.players.size() > 0:
		player = battle_manager.players[0]
	if battle_manager.enemies.size() > 0:
		enemy = battle_manager.enemies[0]
	
	# 4. 更新UI
	update_ui()


# 回合改变
func _on_turn_changed(current_character: Character):
	if not turn_label:
		return
	turn_label.text = "当前回合：" + current_character.stats.character_name
	
	# 如果是敌人回合，禁用攻击按钮
	if battle_manager.is_enemy_turn():
		if attack_button:
			attack_button.disabled = true
		if status_label:
			status_label.text = "敌人正在思考..."
	else:
		if attack_button:
			attack_button.disabled = false
		if status_label:
			status_label.text = ""
	
	update_ui()

# 战斗结束
func _on_battle_ended(winner: Character):
	if attack_button:
		attack_button.disabled = true
	if status_label:
		status_label.text = "战斗结束！胜利者：" + winner.stats.character_name
	if turn_label:
		turn_label.text = "战斗结束"

# 更新UI显示
func update_ui():
	if player and player_info:
		player_info.text = "玩家：血量 %d/%d" % [player.health, player.stats.max_health]
	if enemy and enemy_info:
		enemy_info.text = "敌人：血量 %d/%d" % [enemy.health, enemy.stats.max_health]

# 攻击按钮被按下
func _on_attack_button_pressed():
	if battle_manager:
		battle_manager.player_attack(enemy)
		update_ui()
