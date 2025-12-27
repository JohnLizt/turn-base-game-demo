extends Control

# 战斗场景UI控制脚本

@onready var battle_manager = $BattleManager
@onready var player = $Player
@onready var enemy = $Enemy
@onready var player_character = $Player/CharacterBody2D  # 玩家角色视觉节点
@onready var enemy_character = $Enemy/EnemyBody2D  # 敌人角色视觉节点
@onready var turn_label = $UI/TurnLabel
@onready var player_info = $UI/PlayerInfo
@onready var enemy_info = $UI/EnemyInfo
@onready var attack_button = $UI/AttackButton
@onready var status_label = $UI/StatusLabel

func _ready():
	# 初始化UI
	update_ui()

# 攻击按钮被按下
func _on_attack_button_pressed():
	if battle_manager:
		battle_manager.player_attack()
		# 延迟更新UI，等待伤害计算完成
		await get_tree().create_timer(0.1).timeout
		update_ui()

# 回合改变
func _on_turn_changed(current_turn: String):
	if not turn_label:
		return
	turn_label.text = "当前回合：" + current_turn
	
	# 如果是敌人回合，禁用攻击按钮
	if current_turn == "敌人":
		if attack_button:
			attack_button.disabled = true
		if status_label:
			status_label.text = "敌人正在思考..."
	else:
		if attack_button:
			attack_button.disabled = false
		if status_label:
			status_label.text = ""
	
	# 延迟更新UI，确保血量变化已应用
	await get_tree().create_timer(0.1).timeout
	update_ui()

# 战斗结束
func _on_battle_ended(winner: String):
	if attack_button:
		attack_button.disabled = true
	if status_label:
		status_label.text = "战斗结束！胜利者：" + winner
	if turn_label:
		turn_label.text = "战斗结束"

# 播放玩家攻击动画
func _on_player_attack_animation():
	if player_character:
		player_character.play_attack_animation()

# 播放敌人攻击动画
func _on_enemy_attack_animation():
	if enemy_character:
		enemy_character.play_attack_animation()

# 更新UI显示
func update_ui():
	if player and player_info:
		player_info.text = "玩家：血量 %d/%d" % [player.health, player.max_health]
	if enemy and enemy_info:
		enemy_info.text = "敌人：血量 %d/%d" % [enemy.health, enemy.max_health]
