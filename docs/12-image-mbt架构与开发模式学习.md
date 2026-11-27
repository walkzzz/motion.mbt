# walkzzz/image.mbt 架构与开发模式学习报告（源码级）

| 字段 | 值 |
|------|-----|
| 文档编号 | MOT-DOC-12 |
| 版本 | v2.0（源码级） |
| 日期 | 2026-11-27 |
| 状态 | 正式 |
| 来源 | https://github.com/walkzzz/image.mbt（main 分支，v0.1.24） |
| 获取方式 | GitHub API + raw.githubusercontent.com（git clone 因 sandbox 无法直连 github.com 443 改用 webfetch 代理） |

---

## 1. 仓库结构（根目录 contents API 确认）

```
walkzzz/image.mbt/
├── moon.mod                    # 根模块清单
├── moon.work                   # 工作区清单（新增！）
├── moon.pkg                    # 根包（空，不 import 子包）
├── image.mbt                   # 根包源文件（仅 version + 文档）
├── pkg.generated.mbti          # moon info 自动生成 API 接口
├── rules.md                    # 开发规则全集（16 条）
├── AGENTS.md                   # Agent 指令（19KB）
├── all/                        # 门面包（pub using 再导出）
├── image.core/                 # 子模块 L0（独立模块，own moon.mod）
│   ├── moon.mod
│   ├── moon.pkg
│   ├── types/                  # 叶子包
│   │   ├── moon.pkg          # import core/debug + image.core/safe_math
│   │   └── types.mbt
│   └── safe_math/            # 形式化验证目标
├── image.codec/                # 子模块 L1
├── image.process/              # 子模块 L2
├── image.photography/          # 子模块 L3a
├── image.vision/               # 子模块 L3b
├── image.domain/               # 子模块 L4
├── image.doc/ image.media/ image.commerce/ image.pro/  # L5 扩展
├── mp4/                        # 额外模块
├── cmd/ imgcli/ mcp/ npm/ bindings/ wasm/ playground/  # 出口
├── scripts/ spec/ benchmarks/ examples/ docs/          # 工程
└── moon.work                   # 工作区成员声明
```

---

## 2. 工作区模式（moon.work）—— 核心发现

**`moon.work`**（199 字节）：
```moonbit
members = [
  ".",
  "image.core",
  "image.codec",
  "image.process",
  "image.photography",
  "image.vision",
  "image.domain",
  "image.doc",
  "image.media",
  "image.commerce",
  "image.pro",
]
```

**关键**：image.mbt 不是单模块，是**工作区**——11 个成员（根 `.` + 10 子模块）。每个子模块是**独立模块**（各自有 moon.mod），**独立发布**到 mooncakes.io。`moon work` 把它们绑在一起本地开发。

这与 MOT/current 单模块单包模式**根本不同**。

---

## 3. 根包门面（R12）—— 核心发现

### 3.1 `image.mbt`（根包源文件，1560 字节）

```moonbit
///|
/// # walkzzz/image.mbt 图像处理库
/// ...（文档注释：快速入门 + 模块结构表）
///
pub let version : String = "0.1.24"
```

**根包唯一源码 = 文档注释 + `pub let version`**。无任何 import、无任何 reexport、无任何代码。

### 3.2 `moon.pkg`（根包清单，328 字节）

```moonbit
// 根模块包：只放门面文档与版本号。
// 高频 API 的再导出在 `all/` 包（`pub using`）；测算基准在 `bench/` 包。
// 这里刻意不 import 任何子包——消费者拿到的根包里没有代码需要它们，
// 留着导入会在 `moon publish` 的 verify 阶段报 `unused_package [0029]`。
```

**根包 moon.pkg = 纯注释，零 import**。注释明确解释：不 import 子包是为了避免 `moon publish` verify 报 `unused_package [0029]`。

### 3.3 用户导入方式

```moonbit
import "walkzzz/image.core/types"      // 直接 import 子模块包
import "walkzzz/image.codec/lib"
import "walkzzz/image.process/filter"
```

用户**直接 import 子模块包**，根包不含代码。

---

## 4. 门面包（all/）—— pub using 模式

### 4.1 `all/moon.pkg`
```moonbit
import {
  "walkzzz/image.core/types",
  "walkzzz/image.codec/lib",
  "walkzzz/image.process/transform",
}
```

### 4.2 `all/all.mbt`（核心）

```moonbit
/// 目的：下游只 `moon add walkzzz/image.mbt` 一条，就能
/// `import "walkzzz/image.mbt/all"` 拿到常用的全部东西。
/// MoonBit 规则："依赖会传递、import 不传递"——
/// `moon add` 把子模块全下载好，但下游直接 `import "walkzzz/image.codec/lib"`
/// 报 `exists in global environment, but its containing module is not imported`。
/// 本包用 `pub using` 把这些名字从子模块再导出一次：下游 import 的是
/// 一个直接依赖（根模块）里的包，于是不需要额外 add 任何子模块。
pub using @types {
  type Image, type Image16, type ImageF, type AnyImage,
  type LoadError, type ImageError, type ErrorCode, type ImageFormat,
  type DecodeLimits, type Region, type ImageRegion, type AllocBudget,
}

// pub using 只能再导出类型，方法要包薄函数
pub fn region(img : @types.Image, x : Int32, y : Int32, w : Int32, h : Int32) -> @types.ImageRegion {
  img.region(x, y, w, h)
}

pub using @lib {
  type EncodedImage, has_alpha, best_format, encode_best,
  load_from_bytes_auto, encode_png, encode_webp_lossless, ...
}

pub using @transform {
  resize_to_cover, resize_to_contain, crop, rotate, ...
}
```

**关键模式**：
- `pub using @pkg { type T, fn f, ... }` 再导出子包的名字
- `pub using` 只能再导出**类型和函数**，**方法**要包薄函数
- 解决"依赖传递、import 不传递"问题
- 下游一条 `moon add` + `import ".../all"` 即可用高频 API

---

## 5. leaf 包清单（image.core/types/moon.pkg）

```moonbit
import {
  "moonbitlang/core/debug",
  "walkzzz/image.core/safe_math",
}
```

**同模块内包间引用用全路径**：`walkzzz/image.core/safe_math`（模块名 + 包名）。

---

## 6. 自动生成 API 接口（pkg.generated.mbti）

```moonbit
// Generated using `moon info`, DON'T EDIT IT
package "walkzzz/image.mbt"
pub let version : String
```

**`moon info` 自动生成，DON'T EDIT**。根包只有 `version`，故接口文件极简。

---

## 7. rules.md —— 开发规则全集（权威）

### 7.1 项目规则 R1-R16

| 规则 | 内容 |
|------|------|
| R1 | 源码放 6 根子模块：core/ codec/ process/ photography/ vision/ domain/ |
| R2 | 多手段测试：形式化证明 + AI/FAKE/MOCK/E2E，Sprint 交付前 moon check 0 error + moon test 全通过 |
| R3 | 代码三级文档注释中英文（包级/类型级/方法级） |
| R4 | README 中英文，默认中文；每个一级子包也要 README.md |
| R5 | 先制定 docs/roadmap.md 迭代路线，按 Sprint 推进 |
| R6 | 提交有迹可循：回写 roadmap 状态 + commit hash |
| R7 | 无任务时自动触发新路线迭代 |
| R8 | 每次迭代文档治理：README/roadmap/CHANGELOG/子包 README |
| R9 | 经验沉淀：更新 memory |
| R10 | 一级子包也要 README.md |
| R11 | 防跑偏：记/锁/回（记录规则/冲突停下问谁有权改/回写已交付） |
| R12 | 根包门面：仅 version + 文档，不做 reexport |
| R13 | Warning 治理：逐一处理，禁止注释/ignore 压制，目标 0 warning |
| R14 | 占位 todo 检查 |
| R15 | 规则输出到 rules.md，每次新增回写 |
| R16 | 迭代清理：删 _build/、.tmp/.bak/*.log、git clean |

### 7.2 核心约束（不可违反）

- **禁止 C FFI 依赖**——纯 MoonBit，四目标可用
- **禁止目标条件编译**——不用 `target == "native"`，四目标共用代码
- **用户直接 import 子模块包**——根模块仅 version + 文档，不做 reexport

### 7.3 架构约束

```
core (L0, 零依赖)
  ↑
codec (L1, → core)
  ↑
process (L2, → core + codec)
  ↑          ↑
photography  vision (L3, → core + codec + process)
                ↑
            domain (L4, → core + codec + process + vision)
```

- 下层不可依赖上层
- 同层不可互相依赖
- 跨模块用完整路径：`walkzzz/image.core/types`

### 7.4 MoonBit 关键语法约束（rules.md §四）

| 约束 | 正确写法 |
|------|----------|
| `@math.atan2/cos/sin/pow/exp/log2/log10` | 接受 Double，需 `.to_double()` 转入，`Float::from_double()` 转出 |
| `@math.log` | **不存在**，用 `@math.lnf(Float)` |
| `@math.sqrt` | **不存在**，用 `.sqrt()` 方法 |
| `not(expr)` | 已弃用，用 `!expr` |
| `1e10F` / `1e-10F` | **无效**，用 `10000000000.0F` |
| `(0..<n).rev()` | **不支持**，手动反向循环 |
| `is_empty()` (Option) | 已弃用，用 `x is None` |
| `clamp` | 标签参数：`.clamp(min=0, max=255)` |
| 外部构造 | `pub(all) enum/struct` |
| `Bytes` | 不可变，用 `Array[Byte]` 构建后 `Bytes::from_array()` |
| Int × Float | 需 `Float::from_int(n) * float_val` |

### 7.5 Sprint 迭代流程

1. 查架构（docs/architecture.md）
2. 实现 + 白盒测试（_wbtest.mbt）
3. `moon check` 0 error + `moon test` 全通过
4. Warning 治理（R13）：0 warning
5. 文档治理（R8）
6. 经验沉淀（R9）：memory
7. 占位检查（R14）
8. 迭代清理（R16）
9. 提交（R6）：commit + roadmap hash
10. 回写（R11 回）："已交付 x，下环依赖 Y"

---

## 8. 对 MOT 的应用清单

| image.mbt 模式 | MOT 现状 | 应用动作 |
|----------------|----------|----------|
| moon.work 工作区（11 成员） | 单模块 moon.mod | **建 moon.work + 子模块** |
| 根包门面（仅 version + 文档，空 moon.pkg） | 根包含全部代码 | **根包改门面，代码迁入子模块** |
| all/ 门面包（pub using） | 无 | **建 all/ 门面包** |
| 子模块独立发布 | 单包 | P1+ 子模块独立 moon.mod |
| rules.md（16 规则） | 无 | **建 rules.md** |
| pkg.generated.mbti（moon info） | 无 | P1+ moon info 生成 |
| 四目标无条件编译 | moon.mod 声明 | moon check 四目标全跑 |
| moon prove 形式化验证 | I1-I6 仅运行时断言 | P1+ moon prove |
| 语法约束（§四） | 已部分对齐 | 全部对齐 |
| Sprint 迭代流程 | 无 | P1+ 接入 |
| 记/锁/回防跑偏 | 无 | 接入 rules.md |
| Warning 治理 0 warning | 有 warning | 治理到 0 |

---

## 9. 结论

image.mbt 的权威开发模式 = **工作区（moon.work）+ 根包门面（R12）+ all/ 门面包（pub using）+ 子模块独立发布 + rules.md 16 规则 + 四目标无条件编译 + moon prove 形式化 + Sprint 迭代**。

MOT/current 是单模块单包，与 image.mbt 模式差距大。本学习报告是 MOT 重构到 image.mbt 模式的设计依据。
