---
status: reverse-documented
source: Scripts/, Docs/Architecture/game_system_architecture_and_plan.md
date: 2026-06-04
verified-by: 陈庚
---

# Mini-City 核心游戏设计文档 (GDD)

> **Note**: 本文档从现有实现和架构规划逆向生成，并经设计意图确认修订。
> 与 `Docs/Architecture/game_system_architecture_and_plan.md` 的重要差异见 §3.1 设计修订说明。

---

## 1. Overview（概述）

《Mini-City》是一款横版 2D 奇幻村庄经营生存 Demo。玩家扮演"市长"亲身驻守在地图中，
白天建设防御工事、分配 NPC 到生产岗位；夜晚怪物实时从地图边缘涌入，攻击建筑、
NPC 守卫和玩家本人。玩家通过合理布置防御建筑和守卫 NPC 来保护自身，在积累足够
战力后清剿地图上的怪物巢穴，推进至下一张地图（Map_02），最终跑通完整的闭环。

**类型定位**：横版 2D · 村庄经营 · 实时生存

---

## 2. Player Fantasy（玩家幻想）

- **"以一己之力撑起一座村庄"**：玩家既是唯一的决策者，也是村庄里最脆弱的那个人。
- **"防线越来越厚，却永远不知道今晚来几只"**：每一个白天都是建设与未知威胁的赛跑。
- **"清剿巢穴那一刻的成就感"**：积累了足够的守卫和防御后，奋力一推、完成地图目标。

---

## 3. Detailed Rules（详细规则）

### 3.1 设计修订说明（与架构文档的差异）

> 原架构文档（`game_system_architecture_and_plan.md`）描述的是**每日清晨批量结算制**：
> 在 `phase_changed` 信号触发时统一计算资源增减和夜袭结果。
>
> 经设计确认，**实际设计意图是全实时模拟**：
>
> | 维度 | 旧架构文档 | 本 GDD（正确版本） |
> |------|-----------|-----------------|
> | 资源消耗 | 每日清晨批量扣减 | 按 delta 持续实时消耗 |
> | 资源产出 | 清晨批量结算 | active 建筑实时产出 |
> | 夜袭方式 | 数值公式计算胜负，无实体 | 怪物实体存在，实时战斗 |
> | 游戏结束 | survival_pressure_days 累积 | 玩家 HP 归零 |
>
> `ResourceManager`、`ProductionSystem`、`RaidManager` 的实现需按本 GDD 设计。
> 架构文档中的 `survival_pressure_days` 字段可废弃。

### 3.2 核心循环

```
白天（Day 06:00–18:00）
  ├─ 建造：B键 → 建造菜单 → 选建筑 → 鼠标放置蓝图 → 扣资源
  ├─ 施工：分配工匠到蓝图 → 进度实时推进 → 完成后 active
  ├─ 分配：NPC 分配到 farmer / worker / guard 岗位
  ├─ 产出：active Farm/Workshop 按岗位分配实时产出资源
  └─ 消耗：每个 NPC 实时消耗食物和水

夜晚（Night 18:00–05:00）
  ├─ 怪物从地图边缘刷出，按路径寻向村庄
  ├─ 怪物优先寻路追击玩家；遇到防御建筑先攻击建筑
  ├─ 防御建筑拦截怪物，HP 实时消耗
  ├─ 守卫 NPC 感知范围内自动攻击最近怪物
  └─ 玩家被怪物接触 → HP 减少 → HP = 0 → 游戏结束

清晨（Dawn 05:00–06:00）
  └─ 怪物撤退或消亡；天数 +1；进入下一白天
```

### 3.3 时间系统

| 阶段 | 时间范围 | 游戏时长（默认） |
|------|---------|--------------|
| 白天 (Day) | 06:00–18:00 | ~60 秒 |
| 夜晚 (Night) | 18:00–05:00 | ~55 秒 |
| 清晨 (Dawn) | 05:00–06:00 | ~5 秒 |

- 默认 `seconds_per_day = 120.0`（整个昼夜循环 120 现实秒）
- Dawn 阶段短暂：怪物消亡，玩家喘息，天数递增
- 支持调试加速和暂停（TimeManager 可控）

### 3.4 资源系统（全实时）

**五类资源**：

| 资源 | 初始值 | 实时消耗来源 | 实时产出来源 |
|------|--------|------------|------------|
| 食物 (food) | 20 | NPC 存活消耗 | Farm（分配农夫后） |
| 水 (water) | 20 | NPC 存活消耗 | —（初版无产水建筑） |
| 木材 (wood) | 30 | 建筑建造（一次性扣除） | Workshop（分配工匠后） |
| 石头 (stone) | 20 | 建筑建造（一次性扣除） | Workshop（分配工匠后） |
| 布料/皮革 (cloth_leather) | 5 | 建筑建造（一次性扣除） | —（初版无产出） |

**资源枯竭后果**：
- 食物/水归零 → NPC 扣血（不立即导致玩家死亡）
- 食物/水同时为零且持续超过阈值 → NPC 开始死亡（总量减少）
- 木材/石头不足 → 建造按钮灰掉，无法放置蓝图

**资源 ID**（GDScript StringName）：
- `&"food"`, `&"water"`, `&"wood"`, `&"stone"`, `&"cloth_leather"`

### 3.5 建筑系统

**建筑状态机**：

```
[blueprint] ──(工匠施工完成)──▶ [active] ──(怪物攻击)──▶ [damaged] ──(HP=0)──▶ [destroyed]
```

| 状态 | 说明 |
|------|------|
| `blueprint` | 已扣除建造资源；占据格子；接受工匠分配 |
| `active` | 提供完整功能（生产 / 防御 / 住房） |
| `damaged` | HP < 50%；功能正常，效率降低（预留，初版可跳过） |
| `destroyed` | 从占格中移除；NPC 分配归零变空闲 |

**第一版建筑列表**：

| 建筑 | 占地 | 建造消耗 | 耐久（HP） | 功能 |
|------|------|---------|----------|------|
| House | 3×3 | wood:20, stone:10 | 中（100） | 提供人口容量上限 |
| Farm | 3×2 | wood:15 | 低（60） | 农夫产出食物（实时） |
| Workshop | 4×3 | wood:20, stone:15 | 低（60） | 工匠产出木材/石头（实时） |
| Defense | 1×2 | wood:10, stone:20 | 高（200） | 拦截怪物；提供守卫驻守点 |
| Nest（巢穴） | 固定 | — | 特殊 | 怪物刷出点；清剿目标 |

**建筑放置规则**：
- 放置前检查资源是否足够（`ResourceManager.can_afford()`）
- 放置前检查目标格子是否空闲（`BuildingOccupancySystem`）
- 放置后立即创建 `blueprint` 状态实例，不直接变为 `active`
- Nest 不可建造，作为地图预置对象存在

### 3.6 NPC 系统

**NPC 总量**：
- 初始：3
- 上限：所有 active House 的 `housing_capacity` 之和
- 任何时刻：`npc_idle = npc_total - sum(all_assigned)`

**三种岗位**：

| 岗位 | 分配目标 | 效果 |
|------|---------|------|
| worker（工匠） | 施工中的蓝图建筑 | 实时推进施工进度 |
| farmer（农夫） | active Farm | 实时产出食物 |
| guard（守卫） | Defense 建筑或巡逻区域 | 自动攻击射程内怪物 |

**NPC 战斗行为（守卫）**：
- 守卫在感知范围内自动锁定最近怪物并发起攻击
- 守卫拥有 HP；被怪物攻击可能死亡（NPC 总量 -1）
- 守卫死亡后对应岗位分配清零

### 3.7 战斗系统（实时）

**玩家（市长）**：
- 有 HP（初始值：`player_max_hp`，默认 100）
- 无主动攻击能力；通过防御建筑和守卫保护自身
- 在地图上可自由横移/跳跃
- 玩家 HP = 0 → 触发游戏结束

**怪物行为（夜晚）**：
1. 从地图左/右边缘按 `spawn_count(day)` 数量刷出
2. 按路径向村庄中心移动，**优先追击玩家**
3. 遇到防御建筑（Defense）时攻击建筑消耗其 HP
4. 穿越/绕过防御后继续追击玩家
5. 遇到守卫 NPC 时双方实时交战

**夜袭强度递增**（每天更难）：
- 怪物数量和 HP 随天数线性增长（见 §4 公式）

### 3.8 巢穴清剿

- 地图上预置固定 Nest 对象（第一版：每张地图一个）
- 清剿触发条件：玩家靠近巢穴 + 足够数量守卫在场
- 清剿结算：`clear_power ≥ nest_hp` → 清剿成功
- 清剿成功：
  - 巢穴停止刷怪
  - 解锁下一地图入口
  - 当前地图转为"后方据点"
- 清剿失败：不触发地图推进；可再次尝试

### 3.9 地图推进

- 第一版：Map_01 → Map_02（一次推进）
- 玩家 HP 和资源在地图切换时**保留**
- 建筑占格、NPC 分配在地图切换时**重置**（新地图重新建设）
- Map_01 清剿后转为后方据点，持续向 Map_02 实时输送少量资源
- Map_02 难度更高（`map_difficulty` 更大，巢穴 HP 更高）

---

## 4. Formulas（公式）

```gdscript
# 夜袭怪物数量（随天数线性增加）
spawn_count(day) = base_spawn_count + day * spawn_growth_per_day

# 怪物HP（随天数线性增加）
monster_hp(day) = monster_base_hp * (1.0 + day * hp_growth_rate)

# 资源实时消耗（每秒）
food_drain_rate  = npc_count * food_per_npc_per_sec
water_drain_rate = npc_count * water_per_npc_per_sec

# 资源实时产出（每秒）
food_gain_rate = assigned_farmers  * farm_food_per_farmer_per_sec
wood_gain_rate = assigned_workers  * workshop_wood_per_worker_per_sec
stone_gain_rate = assigned_workers * workshop_stone_per_worker_per_sec

# 建筑施工进度（每秒）
construction_rate = assigned_workers * work_per_worker_per_sec
# 完成条件：accumulated_work >= build_work_required

# 清剿判定
clear_power = guard_count * guard_attack_power
nest_hp_effective = base_nest_hp * map_difficulty
is_clear_success = clear_power >= nest_hp_effective

# 后方据点支援（每秒）
support_rate = {food: support_food_per_sec, wood: support_wood_per_sec, ...}
# （小常量；Map_01 cleared 后激活）
```

---

## 5. Edge Cases（边界情况）

| 情境 | 处理规则 |
|------|---------|
| 所有 NPC 死亡 | 生产/守卫为零；玩家孤身应对怪物 |
| 食物/水同时归零 | NPC 扣血速率激活；不立即导致玩家死亡 |
| NPC 死亡时已分配岗位 | 该岗位分配自动清零；NPC 总量 -1 |
| 建筑被摧毁时 NPC 已分配 | NPC 变空闲（不消失） |
| 玩家在夜晚建造 | 允许，但玩家暴露在攻击风险中 |
| 资源不足尝试放置建筑 | 放置失败并返回提示；不扣除资源 |
| 守卫数量不足尝试清剿 | 清剿失败，显示提示，不触发地图推进 |
| 进入 Map_02 时 | 玩家 HP + 资源保留；建筑/NPC 分配重置 |
| Dawn 阶段仍有怪物 | 怪物标记为撤退/消亡，不追玩家 |
| 怪物穿越 Defense 建筑 | Defense HP 耗尽后怪物可继续移动（绕过机制初版待定） |

---

## 6. Dependencies（系统依赖关系）

```
WorldState (Autoload)
  ├─ 被 ResourceManager 读写（资源量）
  ├─ 被 TimeManager 写入（day、hour、phase + 信号）
  └─ 被 HUDController 监听（显示刷新）

ResourceManager (Autoload)
  ├─ 依赖 NpcManager（读 npc_count 计算消耗速率）
  └─ 被 BuildingPlacementSystem 调用（放置时 spend()）

TimeManager (Autoload)
  └─ 发出 night_started → RaidManager 开始刷怪

NpcManager
  ├─ 依赖 BuildingCatalog（读建筑最大工人数）
  └─ 被 ConstructionSystem / ProductionSystem 读取（岗位分配数）

BuildingPlacementSystem
  ├─ 依赖 ResourceManager（can_afford + spend）
  └─ 依赖 BuildingOccupancySystem（格子占用检查）

ConstructionSystem
  └─ 依赖 NpcManager（读工匠数 → 计算施工速率）

ProductionSystem
  └─ 依赖 NpcManager + active 建筑列表（实时产出）

RaidManager
  └─ 依赖 TimeManager（监听 night_started 信号）

CombatSystem（待实现）
  ├─ 管理玩家 HP、怪物实体 HP、建筑耐久
  └─ 玩家 HP = 0 → 发出 player_died 信号 → GameManager

MapManager
  └─ 依赖 NestClearManager（清剿成功 → 地图切换）

GameManager（编排层）
  └─ 监听 player_died、map_cleared 等关键信号
```

---

## 7. Tuning Knobs（可调参数）

所有以下参数应集中放在 `Resources/Balance/demo_balance.tres`（`BalanceDefinition` Resource），
不得硬编码在脚本中。

| 参数 | 建议初始值 | 说明 |
|------|-----------|------|
| `seconds_per_day` | 120.0 | 整个昼夜循环现实秒数 |
| `initial_npc_count` | 3 | 游戏开始时 NPC 总量 |
| `food_per_npc_per_sec` | 0.01 | 每 NPC 每秒消耗食物 |
| `water_per_npc_per_sec` | 0.01 | 每 NPC 每秒消耗水 |
| `base_spawn_count` | 3 | 第 1 夜怪物数量基数 |
| `spawn_growth_per_day` | 1 | 每天增加的怪物数 |
| `monster_base_hp` | 30 | 第 1 夜怪物基础 HP |
| `hp_growth_rate` | 0.1 | 怪物 HP 每日增长系数 |
| `guard_attack_power` | 10 | 守卫每次攻击伤害 |
| `player_max_hp` | 100 | 玩家最大 HP |
| `base_nest_hp` | 50 | 巢穴基础耐久（清剿用） |
| `farm_food_per_farmer_per_sec` | 0.05 | 农夫每秒产食物 |
| `workshop_wood_per_worker_per_sec` | 0.03 | 工匠每秒产木材 |
| `workshop_stone_per_worker_per_sec` | 0.02 | 工匠每秒产石头 |
| `work_per_worker_per_sec` | 1.0 | 工匠每秒施工进度 |
| `support_food_per_sec` | 0.005 | 后方据点每秒食物支援 |
| `support_wood_per_sec` | 0.003 | 后方据点每秒木材支援 |

---

## 8. Acceptance Criteria（验收标准）

**Demo 可视为完成，当且仅当以下流程能连续跑通：**

| # | 场景 | 预期结果 |
|---|------|---------|
| 1 | 进入 Map_01 | HUD 显示初始资源、第 1 天、白天阶段 |
| 2 | 按 B 键 | 建造菜单出现；可选择 Farm |
| 3 | 资源不足时尝试放置 | 无法放置，HUD 有提示 |
| 4 | 资源足够放置 Farm | Farm 蓝图出现，HUD 资源减少 |
| 5 | 分配工匠到蓝图 | 施工进度实时增加 |
| 6 | 施工完成 | Farm 变为 active 状态 |
| 7 | 分配农夫到 Farm | 食物数量实时增加 |
| 8 | 等待一段时间 | 食物、水随 NPC 数量实时减少 |
| 9 | 进入夜晚 | 怪物从边缘刷出并向玩家移动 |
| 10 | 放置 Defense 建筑 | 怪物攻击 Defense，Defense HP 减少 |
| 11 | 分配守卫 | 守卫自动攻击附近怪物 |
| 12 | 玩家被怪物命中 | 玩家 HP 减少；HP = 0 时游戏结束面板出现 |
| 13 | 游戏结束面板 | 显示"存活 X 天"；可重新开始 |
| 14 | 守卫足够并靠近 Nest | 清剿成功，进入 Map_02 |
| 15 | 进入 Map_02 | 资源和 HP 保留；建筑归零；难度更高 |
| 16 | Map_02 清晨 | HUD 显示来自 Map_01 的资源支援数字 |

---

## 附录：已实现系统状态（截至 2026-06-04）

| 系统 | 文件 | 实现状态 |
|------|------|---------|
| WorldState | `Scripts/Systems/WorldState.gd` | ✅ 实现（信号架构正确） |
| ResourceManager | `Scripts/Systems/Resources/ResourceManager.gd` | ⚠️ 部分（批量模式，需改为实时） |
| TimeManager | `Scripts/Systems/Time/TimeManager.gd` | ✅ 实现 |
| BuildingDefinition | `Scripts/Systems/Building/BuildingDefinition.gd` | ✅ 实现 |
| BuildingCatalog | `Scripts/Systems/Building/BuildingCatalog.gd` | ✅ 实现 |
| BuildingOccupancySystem | `Scripts/Systems/Building/BuildingOccupancySystem.gd` | ✅ 实现 |
| BuildingPlacementSystem | `Scripts/Systems/Building/BuildingPlacementSystem.gd` | ✅ 实现 |
| BuildingInstance | `Scripts/Systems/Building/BuildingInstance.gd` | ✅ 实现 |
| HUDController | `Scripts/UI/HUDController.gd` | ✅ 实现（资源+时间显示+建造菜单） |
| PlayerController | `Scripts/Actors/Player/PlayerController.gd` | ✅ 实现（移动/跳跃，缺 HP） |
| MapContainer | `Scripts/Core/MapContainer.gd` | ✅ 实现 |
| NpcManager | — | ❌ 未实现 |
| ConstructionSystem | — | ❌ 未实现 |
| ProductionSystem | — | ❌ 未实现（实时版本） |
| RaidManager | — | ❌ 未实现（实时怪物实体版本） |
| CombatSystem | — | ❌ 未实现 |
| NestClearManager | — | ❌ 未实现 |
| MapManager | — | ❌ 未实现 |
| BalanceDefinition | — | ❌ 未创建 |
