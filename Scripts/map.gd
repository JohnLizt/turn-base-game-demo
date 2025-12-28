extends Node2D

var menu_ui: CanvasLayer
var map_player: Character

func _ready():
	# 1. 初始化全局数据（如果尚未初始化）
	if PlayerDataManager.hero_stats == null:
		var data = load("res://Resources/Heros/mika.tres")
		PlayerDataManager.init_player(data)
	
	# 2. 创建地图上的角色展示实例
	_create_map_player()
	
	# 3. 创建选择关卡的 UI
	menu_ui = CanvasLayer.new()
	add_child(menu_ui)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(200, 0)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu_ui.add_child(vbox)
	
	var label = Label.new()
	label.text = "请选择关卡"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	# 第一关
	var btn1 = Button.new()
	btn1.text = "第一关：僵尸出没"
	btn1.pressed.connect(func(): start_stage(1))
	vbox.add_child(btn1)
	
	# 第二关
	var btn2 = Button.new()
	btn2.text = "第二关：街头恶霸"
	btn2.pressed.connect(func(): start_stage(2))
	vbox.add_child(btn2)
	
	# 第三关
	var btn3 = Button.new()
	btn3.text = "第三关：钢铁哨兵"
	btn3.pressed.connect(func(): start_stage(3))
	vbox.add_child(btn3)

func _create_map_player():
	var character_prefab = load("res://Scenes/character_2d.tscn")
	map_player = character_prefab.instantiate()
	# 绑定 Hero 脚本
	map_player.set_script(load("res://Scripts/Hero.gd"))
	map_player.stats = PlayerDataManager.hero_stats
	add_child(map_player)
	
	# 设置地图位置和层级
	map_player.position = Vector2(-250, 250)
	map_player.z_index = 5
	
	# 同步实时状态
	map_player.health = PlayerDataManager.health
	map_player.stress = PlayerDataManager.stress
	
	# 确保 UI 更新
	map_player.ready.connect(func(): map_player.update_ui())

func start_stage(stage_index: int):
	# 英雄数据始终使用全局存储的数据
	var player_data: HeroData = PlayerDataManager.hero_stats
	var players: Array[HeroData] = [player_data]
	
	var enemies: Array[CharacterData] = []
	var bg_path: String = "res://AssetBundle/kenney_background-elements/PNG/castle_beige.png"
	
	match stage_index:
		1:
			var zombie = load("res://Resources/Enemies/zombie.tres")
			enemies = [zombie, zombie, zombie]
			bg_path = "res://AssetBundle/kenney_background-elements/PNG/colored_forest.png"
		2:
			enemies = [load("res://Resources/Enemies/bad_guy.tres")]
			bg_path = "res://AssetBundle/kenney_background-elements/PNG/colored_desert.png"
		3:
			enemies = [load("res://Resources/Enemies/robot.tres")]
			bg_path = "res://AssetBundle/kenney_background-elements/PNG/colored_talltrees.png"
	
	var bg: Texture2D = load(bg_path)
	start_combat(players, enemies, bg)

func start_combat(players: Array[HeroData], enemies: Array[CharacterData], bg: Texture2D):
	# 加载战斗场景实例
	var battle_inst = load("res://Scenes/BattleScene.tscn").instantiate()
	get_tree().root.add_child(battle_inst)
	
	# 注入并启动
	battle_inst.setup_battle(players, enemies, bg)
	
	# 禁用并隐藏地图 UI 和 角色
	if menu_ui:
		menu_ui.visible = false
	if map_player:
		map_player.visible = false
	self.visible = false
