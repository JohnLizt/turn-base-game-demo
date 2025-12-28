extends Control

# 战斗场景UI控制脚本

@onready var battle_manager = $BattleManager
@onready var turn_label = $UI/TurnLabel
@onready var attack_button = $UI/AttackButton
@onready var status_label = $UI/StatusLabel
@onready var background = $Background

# 状态
var is_selecting_target: bool = false

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
	

# 战斗结束
func _on_battle_ended(winner: Character):
	if attack_button:
		attack_button.disabled = true
	if status_label:
		status_label.text = "战斗结束！胜利者：" + winner.stats.character_name


# 攻击按钮被按下
func _on_attack_button_pressed():
	if not battle_manager.is_player_turn(): return
	
	# 切换选择状态
	is_selecting_target = !is_selecting_target
	update_attack_button_ui()

func update_attack_button_ui():
	if is_selecting_target:
		attack_button.text = "取消选择"
		status_label.text = "请点击敌人进行攻击..."
	else:
		attack_button.text = "攻击"
		status_label.text = ""

# 处理角色点击
func _on_character_clicked(target: Character):
	if is_selecting_target:
		# 检查是否点击了敌人且敌人还活着
		if battle_manager.is_enemy(target) and target.is_alive():
			is_selecting_target = false
			update_attack_button_ui()
			battle_manager.player_attack(target)
