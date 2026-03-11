@tool
extends EditorScript

# 修复角色纹理引用问题的脚本

func _run():
	print("开始修复角色纹理引用...")

	var characters = ["Alice", "Grace", "Jack", "Joe", "Lea", "Monica", "Stephen", "Tom"]

	for character_name in characters:
		fix_character_scene(character_name)

	print("角色纹理引用修复完成！")

func fix_character_scene(character_name: String):
	var scene_path = "res://scene/characters/" + character_name + ".tscn"
	var texture_path = "res://asset/characters/body/" + character_name + "x32.png"

	print("修复角色: ", character_name)

	# 加载场景
	var scene = load(scene_path)
	if not scene:
		print("无法加载场景: ", scene_path)
		return

	# 实例化场景
	var instance = scene.instantiate()
	if not instance:
		print("无法实例化场景: ", scene_path)
		return

	# 获取 AnimatedSprite2D 节点
	var animated_sprite = instance.get_node("AnimatedSprite2D")
	if not animated_sprite:
		print("找不到 AnimatedSprite2D 节点")
		instance.queue_free()
		return

	# 加载纹理
	var texture = load(texture_path)
	if not texture:
		print("无法加载纹理: ", texture_path)
		instance.queue_free()
		return

	# 重新创建 SpriteFrames
	var sprite_frames = SpriteFrames.new()

	# 创建所有需要的动画
	create_animation(sprite_frames, texture, "idle_down", Vector2(576, 64), 6, 5.0)
	create_animation(sprite_frames, texture, "idle_left", Vector2(384, 64), 6, 5.0)
	create_animation(sprite_frames, texture, "idle_right", Vector2(0, 64), 6, 5.0)
	create_animation(sprite_frames, texture, "idle_up", Vector2(192, 64), 6, 5.0)

	create_animation(sprite_frames, texture, "run_down", Vector2(576, 128), 6, 10.0)
	create_animation(sprite_frames, texture, "run_left", Vector2(384, 128), 6, 10.0)
	create_animation(sprite_frames, texture, "run_right", Vector2(0, 128), 6, 10.0)
	create_animation(sprite_frames, texture, "run_up", Vector2(192, 128), 6, 10.0)

	create_animation(sprite_frames, texture, "sit_down", Vector2(1376, 704), 6, 5.0)
	create_animation(sprite_frames, texture, "sit_left", Vector2(192, 256), 6, 5.0)
	create_animation(sprite_frames, texture, "sit_right", Vector2(0, 256), 6, 5.0)
	create_animation(sprite_frames, texture, "sit_up", Vector2(576, 704), 6, 5.0)

	create_animation(sprite_frames, texture, "stand_down", Vector2(576, 64), 6, 5.0)
	create_animation(sprite_frames, texture, "stand_left", Vector2(384, 64), 6, 5.0)
	create_animation(sprite_frames, texture, "stand_right", Vector2(0, 64), 6, 5.0)
	create_animation(sprite_frames, texture, "stand_up", Vector2(192, 64), 6, 5.0)

	# 设置新的 SpriteFrames
	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.animation = "idle_down"

	# 保存场景
	var packed_scene = PackedScene.new()
	packed_scene.pack(instance)

	var result = ResourceSaver.save(packed_scene, scene_path)
	if result == OK:
		print("成功保存场景: ", scene_path)
	else:
		print("保存场景失败: ", scene_path, " 错误代码: ", result)

	instance.queue_free()

func create_animation(sprite_frames: SpriteFrames, texture: Texture2D, anim_name: String, start_pos: Vector2, frame_count: int, speed: float):
	sprite_frames.add_animation(anim_name)
	sprite_frames.set_animation_speed(anim_name, speed)
	sprite_frames.set_animation_loop(anim_name, true)

	for i in range(frame_count):
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(start_pos.x + i * 32, start_pos.y, 32, 64)
		sprite_frames.add_frame(anim_name, atlas_texture)