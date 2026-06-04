# Scene Refactoring: Extract Player.tscn & terrain_tileset.tres

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split Map_01.tscn by extracting the Player node tree into a standalone `Scenes/Actors/Player.tscn` and the TileSet into `Resources/Tiles/terrain_tileset.tres`; MapBase instantiates the player at runtime from a `SpawnPoint` Marker2D.

**Architecture:** Godot .tscn/.tres files are plain text — all changes are direct file writes. MapBase.gd gains a `_ready()` that preloads `Player.tscn` and instantiates it at the SpawnPoint position. `MainController` accesses `map.player` after `await map.ready`, so the player is guaranteed to exist when needed.

**Tech Stack:** Godot 4 (.tscn / .tres text format, GDScript), phantom_camera addon

---

## File Map

| Action  | File                                      | Responsibility                          |
|---------|-------------------------------------------|-----------------------------------------|
| Create  | `Resources/Tiles/terrain_tileset.tres`    | TileSet + TileSetAtlasSource (地形碰撞) |
| Create  | `Scenes/Actors/Player.tscn`               | Player 节点树 + 动画帧资源              |
| Rewrite | `Scenes/Main/Map_01.tscn`                 | 地图瓦片数据 + SpawnPoint，移除内嵌资源 |
| Modify  | `Scripts/Core/MapBase.gd`                 | 运行时实例化 Player，维护 player/pcam 引用 |

---

## Task 1: Create terrain_tileset.tres

**Files:**
- Create: `Resources/Tiles/terrain_tileset.tres`

- [ ] **Step 1.1: Read source data from Map_01.tscn**

  Read `Scenes/Main/Map_01.tscn`:
  - Lines 13–551: `[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_bkfd5"]` 及其全部 tile 物理数据
  - Lines 553–556: `[sub_resource type="TileSet" id="TileSet_kc7pc"]` 的属性

- [ ] **Step 1.2: Write Resources/Tiles/terrain_tileset.tres**

  创建文件，按以下模板组装：
  - `[sub_resource type="TileSetAtlasSource" ...]` 的 `texture` 属性引用改为 `ExtResource("1_tileset")`（见下方模板）
  - `[resource]` 块对应原文件 `[sub_resource type="TileSet"]` 的属性，但去掉 `id=` 声明

  ```
  [gd_resource type="TileSet" load_steps=3 format=4]

  [ext_resource type="Texture2D" uid="uid://6kqxeud48ieq" path="res://Assets/Tiles/tileset.png" id="1_tileset"]

  [sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_bkfd5"]
  texture = ExtResource("1_tileset")
  texture_region_size = Vector2i(8, 8)
  <从 Map_01.tscn 第 16–550 行粘贴：所有 X:Y/0 = 0 和 physics_layer_0 碰撞点数据>

  [resource]
  tile_size = Vector2i(8, 8)
  physics_layer_0/collision_layer = 1
  sources/1 = SubResource("TileSetAtlasSource_bkfd5")
  ```

- [ ] **Step 1.3: Commit**

  ```
  git add Resources/Tiles/terrain_tileset.tres
  git commit -m "refactor: extract TileSet to terrain_tileset.tres"
  ```

---

## Task 2: Create Scenes/Actors/Player.tscn

**Files:**
- Create: `Scenes/Actors/Player.tscn`

- [ ] **Step 2.1: Read source data from Map_01.tscn**

  Read `Scenes/Main/Map_01.tscn` lines 558–788：
  - Lines 558–559: `RectangleShape2D` (碰撞形状)
  - Lines 561–562: `Resource` (PhantomCamera2D tween)
  - Lines 564–654: 24 个 `AtlasTexture` sub_resources
  - Lines 656–746: `SpriteFrames` (idle/jump/run/walk 动画)
  - Lines 760–788: Player 节点树（Player / CollisionShape2D / PhantomCamera2D / AnimatedSprite2D）

- [ ] **Step 2.2: Write Scenes/Actors/Player.tscn**

  所有 ExtResource id 重新编号（1_idle, 2_jump, 3_run, 4_walk, 5_ctrl, 6_tween, 7_pcam），
  所有 sub_resource id 保持原名不变（避免 SpriteFrames 内部引用混乱）。
  根节点去掉 `parent=` 属性，改为无 parent（场景根节点），`position` 不设（由地图决定）。

  ```
  [gd_scene format=4]

  [ext_resource type="Texture2D" uid="uid://cqdc6cxru27gw" path="res://Assets/craftpix-net-506778-free-vampire-pixel-art-sprite-sheets/Vampire_Girl/Idle.png" id="1_idle"]
  [ext_resource type="Texture2D" uid="uid://bdjssr2tysfri" path="res://Assets/craftpix-net-506778-free-vampire-pixel-art-sprite-sheets/Vampire_Girl/Jump.png" id="2_jump"]
  [ext_resource type="Texture2D" uid="uid://ckvc7vrn84fyn" path="res://Assets/craftpix-net-506778-free-vampire-pixel-art-sprite-sheets/Vampire_Girl/Run.png" id="3_run"]
  [ext_resource type="Texture2D" uid="uid://c2qkkg4wh0xjd" path="res://Assets/craftpix-net-506778-free-vampire-pixel-art-sprite-sheets/Vampire_Girl/Walk.png" id="4_walk"]
  [ext_resource type="Script" uid="uid://peabpa3c0fbk" path="res://Scripts/Actors/Player/PlayerController.gd" id="5_ctrl"]
  [ext_resource type="Script" uid="uid://8umksf8e80fw" path="res://addons/phantom_camera/scripts/resources/tween_resource.gd" id="6_tween"]
  [ext_resource type="Script" uid="uid://bhexx6mj1xv3q" path="res://addons/phantom_camera/scripts/phantom_camera/phantom_camera_2d.gd" id="7_pcam"]

  [sub_resource type="RectangleShape2D" id="RectangleShape2D_1npiw"]
  size = Vector2(12, 36)

  [sub_resource type="Resource" id="Resource_wliom"]
  script = ExtResource("6_tween")

  <从 Map_01.tscn 第 564–654 行粘贴：24 个 AtlasTexture sub_resources，将 atlas = ExtResource("4_cv3cj") 等改为 ExtResource("1_idle") / ExtResource("2_jump") / ExtResource("3_run") / ExtResource("4_walk") 对应关系：
    原 "4_cv3cj" → "1_idle"
    原 "5_tvtfe" → "2_jump"
    原 "6_i318j" → "3_run"
    原 "7_08atr" → "4_walk">

  <从 Map_01.tscn 第 656–746 行粘贴：SpriteFrames sub_resource，内部 SubResource 引用 id 不变>

  [node name="Player" type="CharacterBody2D"]
  script = ExtResource("5_ctrl")

  [node name="CollisionShape2D" type="CollisionShape2D" parent="."]
  position = Vector2(-1, -3)
  shape = SubResource("RectangleShape2D_1npiw")

  [node name="PhantomCamera2D" type="Node2D" parent="."]
  unique_name_in_owner = true
  process_priority = -1
  top_level = true
  script = ExtResource("7_pcam")
  priority = 10
  follow_mode = 2
  follow_target = NodePath("..")
  zoom = Vector2(4, 4)
  frame_preview = false
  tween_resource = SubResource("Resource_wliom")
  tween_on_load = false

  [node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]
  texture_filter = 1
  position = Vector2(0, -17)
  scale = Vector2(0.471, 0.5)
  sprite_frames = SubResource("SpriteFrames_loiwb")
  animation = &"idle"
  ```

- [ ] **Step 2.3: Commit**

  ```
  git add Scenes/Actors/Player.tscn
  git commit -m "refactor: extract Player to standalone Player.tscn"
  ```

---

## Task 3: Rewrite Map_01.tscn

**Files:**
- Rewrite: `Scenes/Main/Map_01.tscn`

- [ ] **Step 3.1: Read TerrainLayer tile_map_data**

  Read `Scenes/Main/Map_01.tscn` 第 752–754 行，复制 TerrainLayer 节点的完整属性（包括 `tile_map_data` 那行长字符串）。

- [ ] **Step 3.2: 写入新的 Map_01.tscn**

  保留原 uid（`uid://bs5ctgr4foj0a`），保留所有节点的 `unique_id`：

  ```
  [gd_scene format=4 uid="uid://bs5ctgr4foj0a"]

  [ext_resource type="Script" uid="uid://6igu1flxhoah" path="res://Scripts/Core/MapBase.gd" id="1_mapbase"]
  [ext_resource type="TileSet" path="res://Resources/Tiles/terrain_tileset.tres" id="2_tileset"]

  [node name="Map_01" type="Node2D" unique_id=1332401598]
  script = ExtResource("1_mapbase")
  texture_filter = 1

  [node name="TerrainLayer" type="TileMapLayer" parent="." unique_id=1143183599]
  <粘贴第 753 行 tile_map_data 属性>
  tile_set = ExtResource("2_tileset")

  [node name="BuildingRoot" type="Node2D" parent="." unique_id=913674137]

  [node name="Actors" type="Node2D" parent="." unique_id=123456789]

  [node name="SpawnPoint" type="Marker2D" parent="Actors" unique_id=222222222]
  position = Vector2(263, 545)
  ```

- [ ] **Step 3.3: Commit**

  ```
  git add Scenes/Main/Map_01.tscn
  git commit -m "refactor: slim down Map_01.tscn, add SpawnPoint Marker2D"
  ```

---

## Task 4: Update MapBase.gd

**Files:**
- Modify: `Scripts/Core/MapBase.gd`

- [ ] **Step 4.1: 替换 MapBase.gd 全部内容**

  ```gdscript
  class_name MapBase
  extends Node2D

  const PlayerScene := preload("res://Scenes/Actors/Player.tscn")

  @onready var terrain_layer: TileMapLayer = $TerrainLayer
  @onready var building_root: Node2D = $BuildingRoot
  @onready var spawn_point: Marker2D = $Actors/SpawnPoint

  var player: CharacterBody2D
  var pcam: PhantomCamera2D

  func _ready() -> void:
      player = PlayerScene.instantiate()
      player.position = spawn_point.position
      $Actors.add_child(player)
      pcam = player.get_node("PhantomCamera2D")
  ```

- [ ] **Step 4.2: Commit**

  ```
  git add Scripts/Core/MapBase.gd
  git commit -m "refactor: MapBase instantiates Player at SpawnPoint"
  ```

---

## Task 5: Verify

**Files:** 无新增文件，验证现有逻辑

- [ ] **Step 5.1: 用 Godot MCP 运行项目**

  使用 `mcp__godot__run_project` 启动游戏。

  预期：无报错，玩家在 (263, 545) 出生，能移动，PhantomCamera2D 跟随摄像机正常工作。

- [ ] **Step 5.2: 确认 MainController 能拿到 player**

  在 `Scripts/Core/MainController.gd` 搜索 `map.player`，确认它在 `map_changed` 信号回调中被赋值——此时 `map.ready` 已触发，player 已在 `_ready()` 中实例化，引用有效。

- [ ] **Step 5.3: 停止项目**

  使用 `mcp__godot__stop_project`。

- [ ] **Step 5.4: 最终提交（可选整合）**

  如果希望把 Task 1–4 合并为一个语义提交：
  ```
  git rebase -i HEAD~4
  # 合并为：refactor: split Map_01 — extract Player.tscn and terrain_tileset.tres
  ```
