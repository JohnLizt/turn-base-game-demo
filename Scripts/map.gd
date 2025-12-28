extends Node2D

# 在你的主地图或者关卡脚本中
func start_combat():
	# 1. 加载战斗场景实例
	var battle_inst = load("res://Scenes/BattleScene.tscn").instantiate()
	get_tree().root.add_child(battle_inst)
	
	# 2. 准备数据 (这里加载你的 .tres 文件)
	var players: Array[HeroData] = [
			load("res://Resources/Heros/madoka.tres")
		]
	var enemies: Array[CharacterData] = [
			load("res://Resources/Enemies/zombie.tres"),
			load("res://Resources/Enemies/zombie.tres"),
			load("res://Resources/Enemies/zombie.tres")
		]
	var bg: Texture2D = load("res://AssetBundle/kenney_background-elements/PNG/castle_beige.png")
	
	# 3. 注入并启动
	battle_inst.setup_battle(players, enemies, bg)
