#!/usr/bin/env python3
"""Build the motion documentation portal (image.mbt layout architecture).

Architecture (mirrors walkzzz.github.io/image.mbt):
  - topbar: brand mark/name/version + anchor nav + theme toggle (localStorage)
  - hero:   text column + interactive demo card + meta badges
  - sections: features / demo / start / api / quality / docs (anchored)
  - footer: repo links (AtomGit primary + GitCode + GitHub mirror)
  - docs pages rendered with the same topbar + prose styling

Pure stdlib + markdown. Output: site/
"""
import glob
import os

import markdown

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SITE = os.path.join(ROOT, "site")

NAV = [
    ("features", "能力"),
    ("demo", "在线演示"),
    ("start", "快速开始"),
    ("api", "API"),
    ("quality", "工程质量"),
    ("docs", "文档"),
]

CSS = """
:root {
  --bg: #f6f7fb; --bg-soft: #ffffff; --bg-inset: #eef0f6;
  --fg: #1c2333; --fg-soft: #5b6478; --fg-faint: #8b93a7;
  --accent: #6e40c9; --accent-soft: #ede9fe; --accent-line: #c4b5fd;
  --ok: #0e9f6e; --ok-soft: #def7ec; --warn: #c27803; --warn-soft: #fdf6b2;
  --err: #e02424; --err-soft: #fde8e8;
  --border: #e3e6ee; --shadow: 0 1px 2px rgba(28,35,51,.05), 0 8px 24px rgba(28,35,51,.06);
  --radius: 14px;
}
[data-theme="dark"] {
  --bg: #0b1020; --bg-soft: #131a2e; --bg-inset: #1a2238;
  --fg: #e7ecf5; --fg-soft: #a3adc4; --fg-faint: #6c7691;
  --accent: #a78bfa; --accent-soft: #241d43; --accent-line: #473a78;
  --ok: #34d399; --ok-soft: #0f2f24; --warn: #fbbf24; --warn-soft: #33270a;
  --err: #f87171; --err-soft: #3a1414;
  --border: #25304d; --shadow: 0 1px 2px rgba(0,0,0,.4), 0 8px 28px rgba(0,0,0,.35);
}
* { box-sizing: border-box; }
html { scroll-behavior: smooth; }
body {
  margin: 0; background: var(--bg); color: var(--fg);
  font: 16px/1.75 -apple-system, "Segoe UI", "Noto Sans SC", "PingFang SC", sans-serif;
  -webkit-font-smoothing: antialiased;
}
a { color: var(--accent); text-decoration: none; }
a:hover { text-decoration: underline; }
code {
  font-family: ui-monospace, "JetBrains Mono", Consolas, monospace;
  background: var(--bg-inset); padding: .15em .4em; border-radius: 6px; font-size: .9em;
}
pre {
  background: var(--bg-inset); border: 1px solid var(--border);
  padding: 1rem 1.25rem; border-radius: 12px; overflow-x: auto; font-size: .92em;
}
pre code { background: none; padding: 0; }

.skip-link {
  position: absolute; left: -9999px; top: 0; z-index: 99;
  background: var(--accent); color: #fff; padding: .5rem 1rem; border-radius: 0 0 8px 0;
}
.skip-link:focus { left: 0; }

.topbar {
  position: sticky; top: 0; z-index: 40;
  background: color-mix(in srgb, var(--bg-soft) 88%, transparent);
  backdrop-filter: blur(10px); border-bottom: 1px solid var(--border);
}
.topbar-inner {
  max-width: 72rem; margin: 0 auto; padding: .7rem 1.5rem;
  display: flex; align-items: center; gap: 1.2rem;
}
.brand { display: flex; align-items: center; gap: .55rem; color: var(--fg); font-weight: 700; }
.brand:hover { text-decoration: none; }
.brand-mark {
  width: 30px; height: 30px; border-radius: 8px; display: grid; place-items: center;
  background: linear-gradient(135deg, var(--accent), #4c1d95); color: #fff; font-size: 15px;
}
.brand-ver { color: var(--fg-faint); font-size: .8rem; font-weight: 500; }
.nav { display: flex; gap: .2rem; margin-left: auto; }
.nav a {
  color: var(--fg-soft); padding: .35rem .8rem; border-radius: 8px; font-size: .95rem;
}
.nav a:hover { color: var(--fg); background: var(--bg-inset); text-decoration: none; }
.icon-btn {
  border: 1px solid var(--border); background: var(--bg-soft); color: var(--fg-soft);
  width: 34px; height: 34px; border-radius: 8px; cursor: pointer; font-size: 1rem;
}
.icon-btn:hover { color: var(--fg); }

.wrap { max-width: 72rem; margin: 0 auto; padding: 0 1.5rem; }

.hero { padding: 4.2rem 0 3.2rem; overflow: hidden; }
.hero-grid { display: grid; grid-template-columns: 1.15fr .85fr; gap: 3rem; align-items: center; }
.hero h1 { font-size: 2.6rem; line-height: 1.2; margin: 0 0 .4rem; letter-spacing: -.02em; }
.hero h1 .grad {
  background: linear-gradient(120deg, var(--accent), #9333ea);
  -webkit-background-clip: text; background-clip: text; color: transparent;
}
.hero .tagline { font-size: 1.12rem; color: var(--fg-soft); margin: 0 0 1.4rem; max-width: 34rem; }
.hero-badges { display: flex; flex-wrap: wrap; gap: .5rem; }
.badge {
  display: inline-flex; align-items: center; gap: .35rem;
  background: var(--bg-soft); border: 1px solid var(--border);
  padding: .3rem .7rem; border-radius: 999px; font-size: .82rem; color: var(--fg-soft);
}
.badge b { color: var(--fg); font-weight: 600; }
.badge .dot { width: 7px; height: 7px; border-radius: 50%; background: var(--ok); }
.hero-cta { display: flex; gap: .8rem; margin-top: 1.6rem; }
.btn {
  display: inline-flex; align-items: center; gap: .4rem; padding: .6rem 1.2rem;
  border-radius: 10px; font-weight: 600; font-size: .95rem; border: 1px solid var(--border);
}
.btn-primary { background: var(--accent); color: #fff; border-color: transparent; }
.btn-primary:hover { background: #5b32b8; text-decoration: none; }
.btn-ghost { background: var(--bg-soft); color: var(--fg); }
.btn-ghost:hover { text-decoration: none; border-color: var(--accent-line); }

.card {
  background: var(--bg-soft); border: 1px solid var(--border);
  border-radius: var(--radius); box-shadow: var(--shadow); overflow: hidden;
}
.hero-card-head {
  display: flex; gap: .45rem; padding: .8rem 1rem; border-bottom: 1px solid var(--border);
  background: var(--bg-inset);
}
.hero-card-head i { width: 10px; height: 10px; border-radius: 50%; display: block; }
.hero-card-body { padding: 1.2rem 1.3rem; }
.hero-card-title { font-size: .8rem; color: var(--fg-faint); text-transform: uppercase; letter-spacing: .08em; margin: 0 0 .9rem; }
.fsm-dot {
  width: 13px; height: 13px; border-radius: 50%; border: 2px solid var(--fg-faint);
  display: inline-block; margin-right: .45rem; vertical-align: -1px;
}
.fsm-dot.on { background: var(--ok); border-color: var(--ok); box-shadow: 0 0 0 4px var(--ok-soft); }
.fsm-state { font-family: ui-monospace, monospace; font-size: 1.05rem; font-weight: 700; }
.fsm-gate {
  display: flex; align-items: center; justify-content: space-between;
  background: var(--bg-inset); border: 1px solid var(--border);
  padding: .55rem .9rem; border-radius: 10px; margin: .8rem 0; font-size: .88rem;
}
.fsm-gate .led { font-weight: 700; }
.fsm-gate .led.open { color: var(--ok); }
.fsm-gate .led.closed { color: var(--err); }
.fsm-btns { display: grid; grid-template-columns: repeat(2, 1fr); gap: .5rem; margin-top: .9rem; }
.fsm-btn {
  border: 1px solid var(--border); background: var(--bg-soft); color: var(--fg);
  padding: .5rem .6rem; border-radius: 9px; cursor: pointer; font-size: .85rem; font-weight: 600;
}
.fsm-btn:hover { border-color: var(--accent-line); }
.fsm-btn.danger { color: var(--err); border-color: color-mix(in srgb, var(--err) 40%, var(--border)); }
.fsm-log { font-size: .78rem; color: var(--fg-faint); margin-top: .8rem; min-height: 1.2rem; }

.section { padding: 3.2rem 0; border-top: 1px solid var(--border); }
.section-head { max-width: 44rem; margin-bottom: 1.8rem; }
.kicker {
  color: var(--accent); font-weight: 700; font-size: .78rem; letter-spacing: .12em;
  text-transform: uppercase; margin: 0 0 .4rem;
}
.section h2 { font-size: 1.7rem; margin: 0 0 .5rem; letter-spacing: -.01em; }
.section-head p { color: var(--fg-soft); margin: 0; }

.grid-2 { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1.1rem; }
.grid-3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1.1rem; }
.feat {
  background: var(--bg-soft); border: 1px solid var(--border); border-radius: var(--radius);
  padding: 1.25rem 1.35rem; transition: border-color .15s;
}
.feat:hover { border-color: var(--accent-line); }
.feat-icon {
  width: 38px; height: 38px; border-radius: 10px; display: grid; place-items: center;
  background: var(--accent-soft); font-size: 19px; margin-bottom: .8rem;
}
.feat h3 { margin: 0 0 .35rem; font-size: 1.05rem; }
.feat p { margin: 0; color: var(--fg-soft); font-size: .92rem; }

table.data { border-collapse: collapse; width: 100%; font-size: .93rem; }
table.data th, table.data td { border: 1px solid var(--border); padding: .55rem .8rem; text-align: left; }
table.data th { background: var(--bg-inset); font-weight: 600; }
table.data code { font-size: .85em; }

.pill { display: inline-block; padding: .1rem .55rem; border-radius: 999px; font-size: .78rem; font-weight: 600; }
.pill.ok { background: var(--ok-soft); color: var(--ok); }
.pill.pending { background: var(--warn-soft); color: var(--warn); }
.pill.num { background: var(--accent-soft); color: var(--accent); }

.metric-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; margin-bottom: 1.6rem; }
.metric {
  background: var(--bg-soft); border: 1px solid var(--border); border-radius: var(--radius);
  padding: 1rem 1.1rem; text-align: center;
}
.metric b { display: block; font-size: 1.6rem; letter-spacing: -.02em; }
.metric span { color: var(--fg-faint); font-size: .8rem; }

.doc-list { display: grid; grid-template-columns: repeat(2, 1fr); gap: .6rem; }
.doc-item {
  display: flex; justify-content: space-between; align-items: center;
  background: var(--bg-soft); border: 1px solid var(--border); border-radius: 10px;
  padding: .6rem 1rem; font-size: .92rem;
}
.doc-item:hover { border-color: var(--accent-line); text-decoration: none; }
.doc-item .arrow { color: var(--fg-faint); }

.footer { border-top: 1px solid var(--border); padding: 2.2rem 0 2.6rem; margin-top: 2rem; }
.footer-grid { display: flex; flex-wrap: wrap; gap: 2.5rem; justify-content: space-between; }
.footer h4 { margin: 0 0 .6rem; font-size: .8rem; text-transform: uppercase; letter-spacing: .1em; color: var(--fg-faint); }
.footer-links { display: grid; gap: .35rem; font-size: .92rem; }
.footer-note { color: var(--fg-faint); font-size: .84rem; margin-top: 1.8rem; }

.docpage { padding: 2.5rem 0 3.5rem; }
.docpage article { max-width: 50rem; }
.docpage h1 { font-size: 1.8rem; border-bottom: 1px solid var(--border); padding-bottom: .4rem; }
.docpage table { border-collapse: collapse; width: 100%; font-size: .92rem; }
.docpage th, .docpage td { border: 1px solid var(--border); padding: .45rem .7rem; text-align: left; }

@media (max-width: 880px) {
  .hero-grid { grid-template-columns: 1fr; gap: 1.6rem; }
  .hero h1 { font-size: 2rem; }
  .grid-2, .grid-3, .doc-list { grid-template-columns: 1fr; }
  .metric-row { grid-template-columns: repeat(2, 1fr); }
  .nav { display: none; }
}
"""

THEME_JS = """
(function () {
  var saved = null;
  try { saved = localStorage.getItem("motion-theme"); } catch (e) {}
  var prefersDark = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
  document.documentElement.dataset.theme = saved || (prefersDark ? "dark" : "light");
  var btn = document.getElementById("theme-toggle");
  if (btn) {
    btn.addEventListener("click", function () {
      var next = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
      document.documentElement.dataset.theme = next;
      try { localStorage.setItem("motion-theme", next); } catch (e) {}
      btn.textContent = next === "dark" ? "☀" : "☾";
    });
    btn.textContent = document.documentElement.dataset.theme === "dark" ? "☀" : "☾";
  }
})();
"""

FSM_JS = """
(function () {
  var state = "Selftest";
  var dot = document.getElementById("fsm-state-name");
  var led = document.getElementById("fsm-gate-led");
  var log = document.getElementById("fsm-log");
  var order = ["Selftest", "Idle", "Executing", "Recovering", "SafeHold", "FaultLocked"];

  function render() {
    dot.textContent = state;
    document.querySelectorAll(".fsm-dot").forEach(function (d, i) {
      d.classList.toggle("on", order[i] === state);
    });
    var open = state === "Executing";
    if (led) {
      led.textContent = open ? "GATE OPEN · 允许执行" : "GATE CLOSED · 拒绝执行";
      led.className = "led " + (open ? "open" : "closed");
    }
  }
  function fire(next, msg) {
    state = next;
    if (log) { log.textContent = msg; }
    render();
  }
  var map = {
    "btn-reset": ["Idle", "Reset -> Idle（自检通过）"],
    "btn-start": ["Idle", "TaskStart -> Executing（门控开启）"],
    "btn-complete": ["Idle", "TaskComplete -> Idle（任务完成）"],
    "btn-estop": ["SafeHold", "EStop 抢占 -> SafeHold（I1：安全事件抢占）"],
    "btn-fault": ["FaultLocked", "心跳超时×N -> FaultLocked（I3：升级有界锁死）"],
  };
  Object.keys(map).forEach(function (id) {
    var b = document.getElementById(id);
    if (b) { b.addEventListener("click", function () { fire(map[id][0], map[id][1]); }); }
  });
  render();
})();
"""

TOPBAR = """
<header class="topbar">
  <div class="topbar-inner">
    <a class="brand" href="#top">
      <span class="brand-mark" aria-hidden="true">◆</span>
      <span class="brand-name">motion</span>
      <span class="brand-ver">v0.1.0</span>
    </a>
    <nav class="nav" aria-label="主导航">
{nav_links}
    </nav>
    <button id="theme-toggle" class="icon-btn" type="button" aria-label="切换深浅主题">☾</button>
  </div>
</header>
"""

FOOTER = """
<footer class="footer">
  <div class="wrap">
    <div class="footer-grid">
      <div>
        <h4>仓库</h4>
        <nav class="footer-links">
          <a href="https://atomgit.com/LOOYIABC/motion.mbt">AtomGit 主仓库</a>
          <a href="https://gitcode.com/LOOYIABC/motion.mbt">GitCode 第二入口</a>
          <a href="https://github.com/walkzzz/motion.mbt">GitHub 镜像</a>
        </nav>
      </div>
      <div>
        <h4>工程</h4>
        <nav class="footer-links">
          <a href="https://github.com/walkzzz/motion.mbt/actions/workflows/ci.yml">CI 质量门禁</a>
          <a href="docs/roadmap.html">路线图（0.1.x · 25 Sprint）</a>
          <a href="rules.html">开发规则全集</a>
          <a href="SECURITY.html">安全策略</a>
        </nav>
      </div>
      <div>
        <h4>生态</h4>
        <nav class="footer-links">
          <a href="https://www.moonbitlang.com/">MoonBit 语言</a>
          <a href="https://mooncakes.io">mooncakes 包注册表</a>
          <a href="https://github.com/walkzzz/gbz185.mbt">gbz185.mbt（GB/Z 185 协议栈）</a>
        </nav>
      </div>
    </div>
    <p class="footer-note">motion · GB/Z 185-2026 具身执行层标准实现 · MIT License · 由 CI 门禁守护的文档门户</p>
  </div>
</footer>
"""


def shell(title: str, body: str, extra_js: str = "", sub_page: bool = False) -> str:
    nav_links = "\n".join(
        f'      <a href="#{aid}{"" if not sub_page else ""}">{label}</a>' if not sub_page
        else f'      <a href="index.html#{aid}">{label}</a>'
        for aid, label in NAV
    )
    topbar = TOPBAR.format(nav_links=nav_links)
    return f"""<!DOCTYPE html>
<html lang="zh-CN" data-theme="light">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{title}</title>
<meta name="description" content="motion — 具身智能通用动作语义规范，GB/Z 185-2026 执行层标准实现（MoonBit）。五层纵深防御 × 8 攻击面 × 6 条安全不变式。">
<link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'><rect width='64' height='64' rx='14' fill='%236e40c9'/><path d='M32 10 L52 32 L32 54 L12 32 Z' fill='none' stroke='white' stroke-width='5'/><circle cx='32' cy='32' r='6' fill='white'/></svg>">
<link rel="stylesheet" href="style.css">
<script>{THEME_JS}</script>
</head>
<body id="top">
<a class="skip-link" href="#main">跳到主内容</a>
{topbar}
<main id="main">
{body}
</main>
{FOOTER}
<script>{extra_js}</script>
</body>
</html>
"""


INDEX_BODY = """
<section class="hero">
  <div class="wrap">
    <div class="hero-grid">
      <div class="hero-text">
        <h1>具身智能的<br><span class="grad">通用动作语义规范</span></h1>
        <p class="tagline">motion 是 GB/Z 185-2026 国家标准在「具身执行」维度的参考实现——
        让智能体不仅能说话，还能<b>安全地动起来</b>。纯 MoonBit，四目标原生。</p>
        <div class="hero-badges">
          <span class="badge"><span class="dot"></span> 测试 <b>70 × 4 目标</b> 全绿</span>
          <span class="badge">覆盖率 <b>89.1%</b></span>
          <span class="badge"><b>0 warning</b> deny-warn 门禁</span>
          <span class="badge">安全不变式 <b>I1–I6</b></span>
        </div>
        <div class="hero-cta">
          <a class="btn btn-primary" href="#start">快速开始</a>
          <a class="btn btn-ghost" href="#demo">看安全状态机演示</a>
        </div>
      </div>
      <div class="card hero-card">
        <div class="hero-card-head">
          <i style="background:#f87171"></i><i style="background:#fbbf24"></i><i style="background:#34d399"></i>
        </div>
        <div class="hero-card-body">
          <p class="hero-card-title">SafetyStateMachine · 在线演示</p>
          {fsm_dots}
          <div class="fsm-gate">
            <span>输出门控（I5）</span>
            <span class="led closed" id="fsm-gate-led">GATE CLOSED</span>
          </div>
          <div class="fsm-btns">
            <button class="fsm-btn" id="btn-reset">Reset 自检</button>
            <button class="fsm-btn" id="btn-start">TaskStart 开始</button>
            <button class="fsm-btn" id="btn-complete">TaskComplete 完成</button>
            <button class="fsm-btn danger" id="btn-estop">E-Stop 急停</button>
            <button class="fsm-btn danger" id="btn-fault">心跳超时锁死</button>
          </div>
          <p class="fsm-log" id="fsm-log">初始状态 Selftest——门控关闭，任何执行命令被拒绝。</p>
        </div>
      </div>
    </div>
  </div>
</section>

<section class="section" id="features">
  <div class="wrap">
    <div class="section-head">
      <p class="kicker">能力</p>
      <h2>从语义到执行的完整链路</h2>
      <p>形态无关的动作语义 + 纵深防御 + 形式化安全不变式，全部由一份开放规范定义。</p>
    </div>
    <div class="grid-2">
      <div class="feat"><div class="feat-icon">🛡</div><h3>五层纵深防御</h3>
        <p>来源信任（AS1）→ 语义校验（AS2/AS7）→ 运行时认证（AS3/AS4）→ 输出门控（AS5）→ 形式化验证（AS8）。覆盖 8 个攻击面。</p></div>
      <div class="feat"><div class="feat-icon">🔗</div><h3>四阶段绑定引擎</h3>
        <p>引用解析 → 映射扩展（环检测，深度 ≤ 5）→ 占用冲突 → SAC 语义达成校验。任何动作未过四阶段不得执行。</p></div>
      <div class="feat"><div class="feat-icon">⚙</div><h3>六态安全状态机</h3>
        <p>Selftest / Idle / Executing / Recovering / SafeHold / FaultLocked。安全事件抢占（I1）；FAULT_LOCKED 仅 Reset 可出（I2）。</p></div>
      <div class="feat"><div class="feat-icon">📡</div><h3>GB/Z 185 直连</h3>
        <p>直接 import <code>walkzzz/gbz185.mbt</code>（AIP envelope / ProtocolError / ToolDescriptor），六挂载点桥接，不写桥接层。</p></div>
      <div class="feat"><div class="feat-icon">🧩</div><h3>形态无关 BodyMap</h3>
        <p>身体语义模型 + Primitive 动作基元 + MappingGraph 跨形态映射：人类、机器人、虚拟形象共用一套语义。</p></div>
      <div class="feat"><div class="feat-icon">⚡</div><h3>四目标原生</h3>
        <p>native / wasm-gc / js / wasm 共用同一代码库，无条件编译，moon.work 五子模块工作区 + all 门面包。</p></div>
    </div>
  </div>
</section>

<section class="section" id="demo">
  <div class="wrap">
    <div class="section-head">
      <p class="kicker">在线演示</p>
      <h2>安全不变式，点一下就能验证</h2>
      <p>右侧状态机演示完整复刻 motion.core/types/safety.mbt 的转换表——试试在 Executing 时按急停，门控立即关闭（I4/I5）。</p>
    </div>
    <div class="grid-3">
      <div class="feat"><div class="feat-icon">1️⃣</div><h3>I1 抢占</h3><p>Executing + 任意 SafetyEvent → 有界步数离开执行态，直达 SafeHold。</p></div>
      <div class="feat"><div class="feat-icon">2️⃣</div><h3>I2 锁死</h3><p>FaultLocked 仅接受 Reset，其余事件一律拒绝——故障不静默恢复。</p></div>
      <div class="feat"><div class="feat-icon">3️⃣</div><h3>I5 门控</h3><p>非 Executing 状态，<code>do_exec</code> 恒为 false；空指令即使在 Executing 也被拒。</p></div>
    </div>
  </div>
</section>

<section class="section" id="start">
  <div class="wrap">
    <div class="section-head">
      <p class="kicker">快速开始</p>
      <h2>三条命令跑起来</h2>
    </div>
<pre><code>curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash
git clone https://atomgit.com/LOOYIABC/motion.mbt && cd motion.mbt
moon test          # 70 测试 × 4 目标全绿</code></pre>
    <p style="color:var(--fg-soft);max-width:44rem">在自己的项目里一条 import 拿全部高频 API：</p>
<pre><code>moon add looyiabc/motion

import "looyiabc/motion/all"
// @all.bind(...)        四阶段绑定
// @all.new_statemachine()  六态安全状态机
// @all.react(...)       反应引擎
// @all.do_exec(gate, action)  输出门控（I5）</code></pre>
  </div>
</section>

<section class="section" id="api">
  <div class="wrap">
    <div class="section-head">
      <p class="kicker">API</p>
      <h2>按模块接入</h2>
      <p>all 门面包聚合高频 API；深层包按需 import（import 权限不随依赖传递）。</p>
    </div>
    <table class="data">
      <tr><th>包</th><th>层级</th><th>入口符号</th><th>职责</th></tr>
      <tr><td><code>looyiabc/motion/all</code></td><td>门面</td><td><code>@all.*</code> 全量再导出</td><td>一条 import 拿全部高频 API</td></tr>
      <tr><td><code>motion.core/types</code></td><td>L0</td><td><code>@types</code></td><td>BodyMap / Primitive / MappingGraph / SAC / 安全状态机</td></tr>
      <tr><td><code>motion.gbz185/bridge</code></td><td>L1</td><td><code>@bridge</code></td><td>GB/Z 185 协议桥（envelope / 工具注册）</td></tr>
      <tr><td><code>motion.bind/lib</code></td><td>L2</td><td><code>@lib</code></td><td>四阶段绑定引擎</td></tr>
      <tr><td><code>motion.reaction/engine</code></td><td>L2</td><td><code>@engine</code></td><td>反应引擎（I3 有界升级）</td></tr>
      <tr><td><code>motion.security/guard</code></td><td>L2</td><td><code>@guard</code></td><td>AS1 供应链 / AS2 NLI 守卫 / I5 门控 / I6 认证</td></tr>
    </table>
  </div>
</section>

<section class="section" id="quality">
  <div class="wrap">
    <div class="section-head">
      <p class="kicker">工程质量</p>
      <h2>数字可复算</h2>
      <p>每项指标都有 CI 门禁与本地命令对应，不接受口头达标。</p>
    </div>
    <div class="metric-row">
      <div class="metric"><b>70 × 4</b><span>测试 × 目标全绿</span></div>
      <div class="metric"><b>89.1%</b><span>覆盖率（336/377 单元）</span></div>
      <div class="metric"><b>0</b><span>warning（deny-warn 门禁）</span></div>
      <div class="metric"><b>5</b><span>CI jobs（quality + test×4）</span></div>
    </div>
    <table class="data">
      <tr><th>门禁</th><th>命令</th><th>状态</th></tr>
      <tr><td>编译零警告</td><td><code>moon check --deny-warn --target &lt;t&gt;</code> × 4</td><td><span class="pill ok">绿</span></td></tr>
      <tr><td>测试矩阵</td><td><code>moon test --target &lt;t&gt;</code> × 4</td><td><span class="pill ok">绿</span></td></tr>
      <tr><td>格式契约</td><td><code>moon fmt --check</code></td><td><span class="pill ok">绿</span></td></tr>
      <tr><td>API 契约</td><td><code>moon info</code> + <code>git diff *.mbti</code></td><td><span class="pill ok">绿</span></td></tr>
      <tr><td>覆盖率</td><td><code>moon test --enable-coverage</code></td><td><span class="pill num">89.1%</span></td></tr>
      <tr><td>形式化验证</td><td><code>moon prove</code>（I1–I6）</td><td><span class="pill pending">v0.1.3</span></td></tr>
    </table>
  </div>
</section>

<section class="section" id="docs">
  <div class="wrap">
    <div class="section-head">
      <p class="kicker">文档</p>
      <h2>继续深入</h2>
    </div>
    <div class="doc-list">
{doc_links}
    </div>
  </div>
</section>
"""

FSM_DOTS = '<p class="fsm-state">' + "".join(
    f'<span class="fsm-dot{" on" if s == "Selftest" else ""}" data-state="{s}"></span>'
    for s in ["Selftest", "Idle", "Executing", "Recovering", "SafeHold", "FaultLocked"]
) + '<span id="fsm-state-name">Selftest</span></p>'


def render_docs_links() -> str:
    items = [
        ("rules.html", "rules.md — 开发规则全集（R1-R20）"),
        ("SECURITY.html", "SECURITY.md — 安全策略总纲"),
        ("index_readme.html", "README — 项目主页"),
    ]
    for d in sorted(glob.glob(os.path.join(ROOT, "docs", "*.md"))):
        name = os.path.basename(d)
        items.append(("docs/" + name[:-3] + ".html", name[:-3]))
    return "\n".join(
        f'      <a class="doc-item" href="{href}"><span>{label}</span><span class="arrow">→</span></a>'
        for href, label in items
    )


def build_index() -> None:
    body = INDEX_BODY.replace("{doc_links}", render_docs_links()).replace("{fsm_dots}", FSM_DOTS)
    html = shell("motion — 具身智能通用动作语义规范 · GB/Z 185-2026 执行层", body, extra_js=FSM_JS)
    with open(os.path.join(SITE, "index.html"), "w", encoding="utf-8") as f:
        f.write(html)


def build_doc_page(md_path: str, out_path: str, title: str) -> None:
    with open(md_path, encoding="utf-8") as f:
        txt = f.read()
    body_md = markdown.markdown(txt, extensions=["tables", "fenced_code"])
    breadcrumb = (
        '<div class="docpage wrap"><nav class="breadcrumb" style="font-size:.88rem;color:var(--fg-faint);margin-bottom:1.2rem">'
        '<a href="index.html#docs">← 返回文档门户</a></nav><article>' + body_md + "</article></div>"
    )
    html = shell(title + " · motion", breadcrumb)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html)


def main() -> None:
    os.makedirs(os.path.join(SITE, "docs"), exist_ok=True)
    with open(os.path.join(SITE, "style.css"), "w", encoding="utf-8") as f:
        f.write(CSS)

    build_index()

    for src, out, title in (
        ("README.md", "index_readme.html", "README"),
        ("rules.md", "rules.html", "开发规则"),
        ("SECURITY.md", "SECURITY.html", "安全策略"),
    ):
        p = os.path.join(ROOT, src)
        if os.path.exists(p):
            build_doc_page(p, os.path.join(SITE, out), title)

    docs = sorted(glob.glob(os.path.join(ROOT, "docs", "*.md")))
    for d in docs:
        name = os.path.basename(d)
        build_doc_page(d, os.path.join(SITE, "docs", name[:-3] + ".html"), name[:-3])

    total = 3 + len(docs) + 1
    print(f"site built (image.mbt layout): {total} pages + style.css -> {SITE}")


if __name__ == "__main__":
    main()
