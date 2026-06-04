# 横版 2D 奇幻村庄经营生存 Demo 系统架构与开发计划

## 1. 依据与结论

本文依据：

- `Docs/Design/横版2D奇幻村庄经营生存游戏_Demo开发准备文档.docx`
- 当前 Godot 项目文件与脚本
- Godot MCP 启动检查结果

当前目标不是扩展策划，而是跑通第一版灰盒闭环：

> 建造 -> 分配 NPC -> 生产资源 -> 夜晚结算 -> 清剿巢穴 -> 进入下一地图 -> 后方据点支援。

第一版必须控制范围：

- 做固定横版地图，不做随机地图。
- 做数值夜袭和数值清剿，不做实时怪物战斗、寻路和守卫 AI。
- NPC 只做总量、空闲数、岗位分配，不做路径、动画、熟练度、情绪、健康差异。
- 资源只做木材、石头、食物、水、布料/皮革五类。
- 地图推进只做 `Map_01 -> Map_02` 和后方据点每日支援。

## 2. 当前项目状态

### 2.1 已有内容

项目可被 Godot MCP 识别：

- Godot 版本：`4.6.3.stable.official.7d41c59c4`
- 主场景：`res://Scenes/Main/main.tscn`
- 当前项目结构已包含：`Scenes/`、`Scripts/`、`Resources/`、`Assets/`、`Docs/`

当前自有游戏逻辑主要包括：

- `Scripts/Core/MainController.gd`
  - 负责读取地形范围并设置 PhantomCamera2D 边界。
- `Scripts/Actors/Player/PlayerController.gd`
  - 已实现左右移动、跑步、跳跃、朝向、基础动画切换。
- `Scripts/Systems/Building/BuildingDefinition.gd`
  - 建筑静态定义资源。
- `Scripts/Systems/Building/BuildingCatalog.gd`
  - 建筑定义目录和当前选择。
- `Scripts/Systems/Building/BuildingOccupancySystem.gd`
  - 建筑占格记录。
- `Scripts/Systems/Building/BuildingPlacementSystem.gd`
  - 建造模式、预览、可放置检查、点击生成建筑。
- `Scripts/Systems/Building/BuildingInstance.gd`
  - 已放置建筑实例视觉。
- `Resources/Buildings/house.tres`
  - 当前唯一建筑定义：`house`。

### 2.2 启动检查

已通过 Godot MCP 启动 `res://Scenes/Main/main.tscn` 并停止。启动输出未发现崩溃。

现有警告：

- `Scripts/Systems/Building/BuildingOccupancySystem.gd:17`
- `Scripts/Systems/Building/BuildingOccupancySystem.gd:27`

原因：函数参数 `owner` 遮蔽了 `Node.owner` 基类属性。建议后续改名为 `building_owner` 或 `occupant`。

### 2.3 Git 工作区状态

当前存在未提交改动：

- `project.godot`
- `Scenes/Main/main.tscn`
- `Scripts/Core/MainController.gd`

当前存在未跟踪目录：

- `.claude/`
- `Docs/skill/`

本次文档新增：

- `Docs/Architecture/game_system_architecture_and_plan.md`

### 2.4 当前缺口

距离文档定义的第一版 Demo，还缺少这些核心系统：

- 全局状态：`WorldState`
- 资源增减与每日消耗：`ResourceManager`
- 昼夜与天数推进：`TimeManager`
- NPC 总量、空闲、岗位分配：`NpcManager`
- 建筑施工进度和建筑状态：`ConstructionSystem`
- 生产结算：`ProductionSystem`
- 夜袭数值结算：`RaidManager`
- 巢穴清剿数值结算：`NestClearManager`
- 地图切换与后方据点支援：`MapManager`
- HUD、建造菜单、建筑信息面板、NPC 分配面板、提示面板、游戏结束面板
- `Farm`、`Workshop`、`Defense`、`Nest` 等建筑定义和最小视觉
- `Map_02`

## 3. 总体架构原则

### 3.1 分层

第一版采用四层结构：

1. 数据层
   - 只保存定义和运行状态。
   - 用 `Resource` 保存可编辑定义，用普通对象或 Dictionary 保存可序列化运行状态。

2. 规则层
   - 负责资源、时间、NPC、施工、生产、夜袭、清剿、地图推进等规则。
   - 不直接操作 UI 细节。

3. 表现层
   - 场景节点、建筑 Sprite、HUD、菜单、提示。
   - 监听规则层信号后刷新显示。

4. 编排层
   - `GameManager` 或主场景控制器。
   - 负责初始化、连接信号、处理失败和地图切换入口。

### 3.2 通信规则

- 父节点可以直接调用子系统方法。
- 子系统状态变化通过 typed signal 通知 UI 或编排层。
- 跨系统共享状态通过 `WorldState` 查询，不让 UI 直接修改数据。
- 第一版可以先不用全局事件总线，优先用主场景作为编排者连接信号；当地图切换和 UI 分离后，再把生命周期类事件提升到 Autoload。

### 3.3 时间规则

模拟逻辑不能绑死在帧率上。

第一版建议：

- `TimeManager` 用 Timer 或 delta 累积推进阶段。
- 白天结束触发 `day_ended` 或 `night_started`。
- 夜晚结算完成后触发 `morning_started`，天数 +1。
- 生产、消耗、后方据点支援统一在清晨结算。

## 4. 目录规划

建议在现有结构上继续扩展，不推翻已完成的规范化目录：

```text
res://
  Scenes/
    Main/
      main.tscn
    Maps/
      Map_01.tscn
      Map_02.tscn
    Buildings/
      BuildingInstance.tscn
    UI/
      HUD.tscn
      BuildMenu.tscn
      BuildingPanel.tscn
      NpcAssignmentPanel.tscn
      ResultToast.tscn
      GameOverPanel.tscn
  Scripts/
    Core/
      MainController.gd
      GameManager.gd
      WorldState.gd
    Actors/
      Player/
        PlayerController.gd
    Systems/
      Time/
        TimeManager.gd
      Resources/
        ResourceManager.gd
      NPC/
        NpcManager.gd
      Building/
        BuildingDefinition.gd
        BuildingCatalog.gd
        BuildingOccupancySystem.gd
        BuildingPlacementSystem.gd
        BuildingInstance.gd
        ConstructionSystem.gd
      Production/
        ProductionSystem.gd
      Raid/
        RaidManager.gd
      Map/
        MapManager.gd
    UI/
      HUDController.gd
      BuildMenuController.gd
      BuildingPanelController.gd
      NpcAssignmentPanelController.gd
  Resources/
    Buildings/
      house.tres
      farm.tres
      workshop.tres
      defense.tres
      nest.tres
    Maps/
      map_01.tres
      map_02.tres
    Balance/
      demo_balance.tres
```

## 5. 核心数据模型

### 5.1 WorldState

职责：保存运行期全局状态。

建议字段：

- `current_map_id: StringName`
- `day: int`
- `phase: StringName`，可用 `&"day"`、`&"night"`、`&"morning"`
- `resources: Dictionary[StringName, int]`
- `population_total: int`
- `npc_assignments: Dictionary`
- `building_states: Array[BuildingRuntimeState]`
- `cleared_maps: Array[StringName]`
- `support_outposts: Array[StringName]`
- `survival_pressure_days: int`
- `is_game_over: bool`

### 5.2 ResourceType

第一版直接用 `StringName`，避免过早建立复杂枚举资源：

- `&"wood"`
- `&"stone"`
- `&"food"`
- `&"water"`
- `&"cloth_leather"`

### 5.3 BuildingDefinition

在现有基础上扩展：

- `building_id: StringName`
- `display_name: String`
- `texture: Texture2D`
- `footprint: Vector2i`
- `build_cost: Dictionary[StringName, int]`
- `build_work_required: int`
- `max_workers: int`
- `jobs_supported: Array[StringName]`
- `production_per_day: Dictionary[StringName, int]`
- `defense_value: int`
- `housing_capacity: int`
- `is_nest: bool`

注意：定义资源只放静态数据，不放运行状态。

### 5.4 BuildingRuntimeState

第一版可以先用 `RefCounted` 或 Dictionary：

- `instance_id: int`
- `definition_id: StringName`
- `origin_cell: Vector2i`
- `status: StringName`，如 `&"blueprint"`、`&"active"`、`&"damaged"`、`&"destroyed"`
- `construction_progress: int`
- `assigned_workers: int`
- `assigned_farmers: int`
- `assigned_guards: int`
- `hp: int`

### 5.5 MapDefinition

- `map_id: StringName`
- `scene_path: String`
- `map_difficulty: int`
- `nest_power_base: int`
- `raid_day_growth: int`
- `nest_day_growth: int`
- `support_resources_per_day: Dictionary[StringName, int]`

### 5.6 BalanceDefinition

- `initial_resources`
- `initial_population`
- `guard_power`
- `day_duration_seconds`
- `night_duration_seconds`
- `food_cost_per_npc_per_day`
- `water_cost_per_npc_per_day`

## 6. 系统职责

### 6.1 GameManager

职责：

- 初始化 `WorldState`。
- 连接 Time、Resource、NPC、Building、Raid、Map、UI。
- 处理开始、暂停、失败、重开。
- 接收地图切换请求。

不负责：

- 不直接计算资源。
- 不直接处理建筑占格。
- 不直接刷新每个 UI 文本。

### 6.2 ResourceManager

职责：

- 初始化五类资源。
- 提供 `can_afford(cost)`、`spend(cost)`、`add(resources)`。
- 每日执行食物和水消耗。
- 资源变化时发出 `resources_changed(resources)`。
- 判断生存压力是否增加。

第一版规则：

- 每 NPC 每日消耗 1 食物、1 水。
- 不足时不立即扩展复杂惩罚，先累计 `survival_pressure_days`。
- 压力超过阈值触发失败。

### 6.3 TimeManager

职责：

- 推进白天、夜晚、清晨阶段。
- 维护 day 和 phase。
- 发出 `phase_changed(phase, day)`。
- 发出 `morning_started(day)`。

第一版可以支持：

- 暂停。
- 调试加速。
- 立即进入夜晚。

### 6.4 BuildingPlacementSystem

沿用当前实现，补充：

- 从 `BuildingCatalog` 选择不同建筑。
- 放置前检查资源是否足够。
- 放置后生成蓝图状态，而不是直接 active。
- 通知 `ConstructionSystem` 注册新建筑状态。

### 6.5 BuildingOccupancySystem

沿用当前实现，建议修正：

- 将参数 `owner` 改为 `occupant`，消除 Godot 警告。
- 增加 `clear()`，用于地图切换。
- 后续可增加地形可建造区域判断，但第一版先保持地形支撑检查。

### 6.6 ConstructionSystem

职责：

- 管理蓝图施工进度。
- 每个模拟 tick 或每日根据工匠分配增加进度。
- 进度满后将建筑状态改为 `active`。
- 发出 `building_completed(instance_id)`。

第一版建议：

- 施工只按固定值推进。
- 不做 NPC 路径和施工动画。

### 6.7 NpcManager

职责：

- 保存 NPC 总数、空闲数、岗位分配。
- 提供 `assign_to_building(instance_id, job, count)`。
- 校验岗位是否支持、数量是否足够。
- 统计守卫数、农夫数、工匠数。

第一版岗位：

- `farmer`
- `worker`
- `guard`

### 6.8 ProductionSystem

职责：

- 清晨结算 active 建筑生产。
- 农田根据农夫产出食物。
- 工坊根据工匠产出木材/石头或基础材料。
- 后方据点支援可以由 `MapManager` 计算后交给 `ResourceManager.add()`。

第一版不要做复杂倍率。

### 6.9 RaidManager

职责：

- 夜晚结算怪物袭击。
- 计算：
  - `raid_power = map_difficulty + day * day_growth`
  - `defense_power = guard_count * guard_power + defense_building_value`
- 成功：给出提示。
- 失败：造成资源损失、建筑损坏或生存压力。
- 严重失败：触发游戏结束。

第一版不生成怪物实体。

### 6.10 NestClearManager

职责：

- 玩家点击或按钮触发清剿。
- 计算：
  - `nest_power = map_difficulty * nest_factor + day * nest_growth`
  - `clear_power = guard_count * guard_power`
- 成功：通知 `MapManager` 解锁下一地图。
- 失败：可扣除资源或增加夜袭压力。

第一版只做一次按钮触发和结果提示。

### 6.11 MapManager

职责：

- 管理当前地图 ID。
- 加载 `Map_01`、`Map_02`。
- 记录已清除地图。
- 已清除地图转为后方据点。
- 清晨提供后方据点资源支援。

第一版最小实现：

- `Map_01 -> Map_02`
- `Map_01` 清除后每天给 `Map_02` 增加少量木材、食物、水。

### 6.12 UI 系统

第一版 UI 应服务于灰盒验证，不追求完整美术。

必须有：

- HUD：五类资源、天数、昼夜。
- BuildMenu：选择 House/Farm/Workshop/Defense/Nest 或至少 Farm 起步。
- BuildingPanel：建筑状态、施工进度、岗位分配入口。
- NpcAssignmentPanel：分配农夫、工匠、守卫。
- ResultToast：夜袭/生产/清剿结果。
- GameOverPanel：显示“你生存了 X 天”、重新开始、退出。

## 7. 第一版建筑规划

优先级从高到低：

1. Farm
   - 占地：3x2
   - 工匠施工后 active
   - 农夫分配后每日产食物

2. Workshop
   - 占地：4x3
   - 工匠分配后每日产木材/石头

3. Defense
   - 占地：1x1 或 1x2
   - active 后提供防御值

4. House
   - 占地：3x3
   - 提供人口容量和庇护
   - 第一版可以先只作为失败条件关联建筑

5. Nest
   - 占地可固定
   - 不参与建造，作为地图目标或场景对象
   - 清剿成功后触发地图推进

## 8. 开发进度计划

### 阶段 0：整理与风险修正

目标：保证现有工程稳定。

任务：

- 修复 `BuildingOccupancySystem.gd` 的 `owner` 参数警告。
- 确认当前未提交改动是否保留。
- 将 `house.tres` 的 `footprint` 从当前 8x8 校准到设计占地，或明确它只是测试资源。
- 补齐 `Resources/Buildings/farm.tres`。

验收：

- 主场景可启动。
- 无新增脚本警告。
- B 键建造模式仍可用。

### 阶段 1：全局状态与 HUD

目标：能看到资源、天数、昼夜。

任务：

- 新建 `WorldState.gd`。
- 新建 `ResourceManager.gd`。
- 新建 `TimeManager.gd`。
- 新建 HUD 场景和控制脚本。
- 初始化资源：木材 30、石头 20、食物 20、水 20、布料/皮革 5。

验收：

- 启动后 HUD 显示五类资源。
- 时间自动从白天推进到夜晚，再到清晨。
- 清晨天数 +1。

### 阶段 2：建造菜单与 Farm 蓝图

目标：从单一 House 测试放置转为可选择 Farm 蓝图。

任务：

- 扩展 `BuildingDefinition` 的 cost、work、production 字段。
- 新建 `farm.tres`。
- 建造菜单选择 Farm。
- 放置时扣除资源。
- 放置后创建 `blueprint` 状态。

验收：

- 玩家能打开建造菜单。
- 能选择 Farm。
- 资源不足时不能放置。
- 放置后 HUD 资源减少。

### 阶段 3：施工系统

目标：建筑从蓝图变为可用建筑。

任务：

- 新建 `ConstructionSystem.gd`。
- 新增建筑状态和施工进度。
- 蓝图可分配工匠。
- 工匠推进施工进度。
- 施工完成后状态变为 active。

验收：

- Farm 放置后显示施工进度。
- 分配工匠后进度增长。
- 进度满后 Farm active。

### 阶段 4：NPC 分配

目标：NPC 能被分配到建筑岗位。

任务：

- 新建 `NpcManager.gd`。
- 初始 NPC 总数 3。
- 建筑信息面板支持岗位分配。
- 支持农夫、工匠、守卫三个岗位。

验收：

- UI 显示总 NPC 和空闲 NPC。
- NPC 不能超额分配。
- Farm 可分配农夫，蓝图可分配工匠。

### 阶段 5：生产与消耗

目标：每日资源变化成立。

任务：

- 新建 `ProductionSystem.gd`。
- Farm 每日产食物。
- Workshop 每日产基础材料。
- 每 NPC 每日消耗食物和水。
- 食物/水不足累计生存压力。

验收：

- 清晨资源会变化。
- 食物、水按 NPC 数扣除。
- 不足时出现提示。

### 阶段 6：夜袭结算

目标：夜晚形成生存压力。

任务：

- 新建 `RaidManager.gd`。
- 计算夜袭强度和村庄防御。
- Defense 建筑提供防御值。
- 守卫提供防御值。
- 失败时扣资源或损伤建筑。

验收：

- 夜晚自动结算。
- 防御成功/失败都有提示。
- 失败会产生实际后果。

### 阶段 7：巢穴清剿

目标：可以完成当前地图目标。

任务：

- 新建 `NestClearManager.gd` 或放入 `MapManager` 的清剿子逻辑。
- 场景中放置 Nest 目标。
- UI 提供清剿按钮。
- 按公式判断成功或失败。

验收：

- 守卫不足时清剿失败。
- 守卫足够时清剿成功。
- 成功后触发解锁下一地图。

### 阶段 8：Map_02 与后方据点

目标：跑通地图推进闭环。

任务：

- 新建 `Scenes/Maps/Map_01.tscn`、`Map_02.tscn`，或先从主场景抽离地图节点。
- 新建 `MapManager.gd`。
- Map_01 清剿后记录为已通关。
- 切换到 Map_02。
- Map_01 每日向当前地图提供资源支援。

验收：

- 清剿 Map_01 后进入 Map_02。
- Map_02 难度更高。
- 清晨能收到 Map_01 支援提示和资源。

### 阶段 9：失败、重开、设置与反馈

目标：Demo 具备完整开始和结束边界。

任务：

- 游戏结束面板。
- 重新开始。
- 退出。
- 基础设置菜单占位。
- 夜袭、生产、清剿的最小音效或视觉反馈。

验收：

- 住所被摧毁或长期缺食物/水时游戏结束。
- 面板显示存活天数。
- 可重新开始。

## 9. 推荐实施顺序

最合理的下一步是：

1. 修警告和确认当前变更。
2. 做 `WorldState + ResourceManager + HUD`。
3. 把现有建筑放置改为“扣资源 -> 蓝图 -> 施工 -> active”。
4. 再做 NPC、生产、夜袭、清剿、地图切换。

原因：

- 资源和时间是后续所有系统的共同输入。
- 当前已有建筑放置骨架，继续扩展成本最低。
- 如果先做夜袭或地图切换，没有资源、NPC 和建筑状态，会变成硬编码假逻辑。

## 10. 当前风险清单

1. 建筑占地与文档不一致
   - 当前 `house.tres` 是 8x8，占地明显大于文档建议的 House 3x3。

2. 建筑系统还没有运行状态
   - 当前放置的是视觉实例，不区分蓝图、施工中、可用、损坏。

3. 主场景承载过多
   - 当前地图、玩家、建筑系统、摄像机都在 `main.tscn`。后续做 Map_02 前应抽离地图场景。

4. 插件和示例资源很多
   - MCP 统计的 96 个场景、432 个脚本主要来自插件，不代表游戏系统已完成。开发计划应只按自有系统计算。

5. UI 尚未建立
   - 没有 HUD 时无法验证资源、时间、NPC、夜袭结果。

6. 当前工作区有未提交改动
   - 后续改代码前需要明确哪些是保留状态，避免误覆盖。

## 11. Demo 完成判定

第一版 Demo 可以视为完成，当且仅当以下流程能连续跑通：

1. 玩家进入 Map_01。
2. HUD 显示资源、天数、昼夜。
3. 玩家打开建造菜单并放置 Farm 蓝图。
4. 玩家分配工匠，Farm 施工完成。
5. 玩家分配农夫，Farm 每日产食物。
6. 每日食物、水被消耗。
7. 夜晚自动结算怪物袭击。
8. 玩家分配守卫并清剿巢穴。
9. 清剿成功后进入 Map_02。
10. Map_01 每日为 Map_02 提供资源。
11. 防御严重失败或生存条件崩溃时游戏结束。
