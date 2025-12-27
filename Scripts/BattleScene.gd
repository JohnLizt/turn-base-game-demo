extends Control

# 战斗场景UI控制脚本

@onready var battle_manager = $BattleManager
@onready var turn_label = $UI/TurnLabel
@onready var player_info = $UI/PlayerInfo
@onready var enemy_info = $UI/EnemyInfo
@onready var attack_button = $UI/AttackButton
@onready var status_label = $UI/StatusLabel

# 目前只有一个角色
@onready var player = $Players/MainControl
@onready var enemy = $Enemies/Enemy


func _ready():
	# 初始化UI
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
