#!/usr/bin/env python3
"""Generate the motion capability matrix (roadmap v0.1.5 S5.3, gate B9).

Reads every package's pkg.generated.mbti (authoritative API contract),
its moon.pkg imports, and its blackbox test files, then renders
docs/CAPABILITIES.md — one row per package: layer, dependencies, exported
types/functions/constants, targets, proof status, test count.

Usage: python3 scripts/gen_capabilities.py
"""
import glob
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "CAPABILITIES.md")

PACKAGES = [
    # (path, layer, description, proof)
    ("", "门面", "根包：version 门面（R12）", "—"),
    ("motion.core/geom", "L0", "几何原语（Vec3/SpatialDisplacement，无 Array）", "—"),
    ("motion.core/types", "L0", "核心类型（BodyMap/Primitive/MappingGraph/SAC/诊断/威胁模型）", "—"),
    ("motion.core/safety", "L0", "六态安全状态机（可证明核心）", "I1-I5 · 5 goals"),
    ("motion.gbz185/bridge", "L1", "GB/Z 185 协议桥（AIP envelope / 工具注册）", "—"),
    ("motion.bind/lib", "L2", "四阶段绑定引擎", "—"),
    ("motion.reaction/engine", "L2", "反应引擎（I3 有界升级）", "—"),
    ("motion.security/guard", "L2", "安全守卫（AS1/AS2/I5/I6）", "I6 运行时覆盖"),
    ("all", "门面", "all 门面包（pub using 全量再导出）", "—"),
    ("cmd/main", "CLI", "mot CLI 入口", "—"),
]

TARGETS = "native / wasm-gc / js / wasm"


def parse_mbti(path: str) -> dict:
    full = os.path.join(ROOT, path, "pkg.generated.mbti")
    types = fns = lets = 0
    if os.path.isfile(full):
        with open(full, encoding="utf-8") as f:
            for line in f:
                s = line.strip()
                if re.match(r"^pub(\(all\))? (struct|enum|type) ", s):
                    types += 1
                elif s.startswith("pub fn "):
                    fns += 1
                elif s.startswith("pub let "):
                    lets += 1
    return {"types": types, "fns": fns, "lets": lets}


def parse_imports(path: str) -> list:
    full = os.path.join(ROOT, path, "moon.pkg")
    if not os.path.isfile(full):
        return []
    deps = []
    with open(full, encoding="utf-8") as f:
        for line in f:
            stripped = line.strip()
            if stripped.startswith("//"):
                continue
            for m in re.finditer(r'"([^"]+)"', line):
                dep = m.group(1)
                if dep.startswith("looyiabc/") or dep.startswith("walkzzz/"):
                    deps.append(dep.replace("looyiabc/", "").replace("walkzzz/", ""))
    return deps


def count_tests(path: str) -> int:
    pattern = os.path.join(ROOT, path, "*_test.mbt") if path else os.path.join(ROOT, "*_test.mbt")
    total = 0
    for tf in glob.glob(pattern):
        with open(tf, encoding="utf-8") as f:
            total += f.read().count("\ntest \"") + (1 if open(tf).read().startswith('test "') else 0)
    return total


def main() -> None:
    rows = []
    total_types = total_fns = total_lets = total_tests = 0
    for path, layer, desc, proof in PACKAGES:
        m = parse_mbti(path)
        deps = parse_imports(path)
        tests = count_tests(path)
        total_types += m["types"]
        total_fns += m["fns"]
        total_lets += m["lets"]
        total_tests += tests
        name = path if path else "(root)"
        dep_str = ", ".join(deps) if deps else "—"
        rows.append(
            f"| `{name}` | {layer} | {m['types']} | {m['fns']} | {m['lets']} | "
            f"{dep_str} | {tests} | {proof} |"
        )

    doc = f"""# motion 能力矩阵（CAPABILITIES）

> 由 `scripts/gen_capabilities.py` 从 `pkg.generated.mbti`（B8 API 契约）自动生成 —— 手工修改会被覆盖。
> 目标支持：**{TARGETS}**（无条件编译，四目标共用全部源码）。

## 包能力一览

| 包 | 层级 | 类型 | 函数 | 常量 | 依赖（moon.pkg） | 测试 | 形式化证明 |
|----|------|-----:|-----:|-----:|------------------|-----:|------------|
{chr(10).join(rows)}

**汇总**：{total_types} 类型 · {total_fns} 函数 · {total_lets} 常量 · {total_tests} 测试 × 4 目标 · 5 goals proved（I1-I5）

## 说明

- **层级**：L0（零依赖基础）→ L1（协议桥）→ L2（引擎/守卫）→ 门面（all/根包）→ CLI
- **依赖方向**：单向（下层不可依赖上层），`motion.core/safety` 仅依赖无 Array 的 `geom`（Why3 lowering 约束）
- **形式化证明**：`moon prove motion.core/safety` → 5 goals（I1 抢占 / I2 锁死 / I3 单调 / I4 门控 / I5 状态半）；I6 由 guard 包运行时测试覆盖（P2 证明义务）
- **API 契约**：各包 `pkg.generated.mbti` 由 `moon info` 生成，CI 漂移门禁（`git diff --exit-code -- '*.mbti'`）守护
- **变异测试**：`scripts/mutation_prove.py` → 5/5 REJECTED（证明非平凡性 100%）
"""
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(doc)
    print(f"capability matrix written: {OUT}")
    print(f"totals: {total_types} types, {total_fns} fns, {total_lets} consts, {total_tests} tests")


if __name__ == "__main__":
    main()
