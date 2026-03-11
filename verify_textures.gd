extends Node

# 角色纹理验证脚本

func _ready():
	print("开始验证角色纹理...")
	verify_character_textures()

func verify_character_textures():
	var characters = ["Alice", "Grace", "Jack", "Joe", "Lea", "Monica", "Stephen", "Tom"]

	for character_name in characters:
		var texture_path = "res://asset/characters/body/" + character_name + "x32.png"
		var scene_path = "res://scene/characters/" + character_name + ".tscn"

		print("\n检查角色: ", character_name)

		# 检查纹理文件
		var texture = load(texture_path)
		if texture:
			print("  ✅ 纹理文件存在: ", texture_path)
			print("  📏 纹理尺寸: ", texture.get_width(), "x", texture.get_height())
		else:
			print("  ❌ 纹理文件不存在: ", texture_path)
			continue

		# 检查场景文件
		var scene = load(scene_path)
		if scene:
			print("  ✅ 场景文件存在: ", scene_path)

			# 实例化并检查动画
			var instance = scene.instantiate()
			if instance:
				var animated_sprite = instance.get_node_or_null("AnimatedSprite2D")
				if animated_sprite:
					print("  ✅ AnimatedSprite2D 节点存在")

					if animated_sprite.sprite_frames:
						var animations = animated_sprite.sprite_frames.get_animation_names()
						print("  📽️ 动画数量: ", animations.size())
						print("  🎬 动画列表: ", animations)

						# 检查关键动画是否存在
						var required_anims = ["idle_down", "run_down", "run_left", "run_right", "run_up"]
						for anim in required_anims:
							if anim in animations:
								print("    ✅ ", anim)
							else:
								print("    ❌ ", anim, " 缺失")
					else:
						print("  ❌ SpriteFrames 资源不存在")
				else:
					print("  ❌ AnimatedSprite2D 节点不存在")

				instance.queue_free()
			else:
				print("  ❌ 无法实例化场景")
		else:
			print("  ❌ 场景文件不存在: ", scene_path)

	print("\n角色纹理验证完成！")