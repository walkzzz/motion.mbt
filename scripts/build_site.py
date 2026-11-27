#!/usr/bin/env python3
"""Build the static documentation portal for GitHub Pages.

Converts README.md, rules.md, SECURITY.md and docs/*.md into a styled
HTML site under site/ with a navigation index. Pure stdlib + `markdown`.
"""
import os
import glob
import markdown

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SITE = os.path.join(ROOT, "site")

CSS = """
:root { color-scheme: light dark; }
* { box-sizing: border-box; }
body {
  font-family: -apple-system, "Segoe UI", "Noto Sans SC", sans-serif;
  max-width: 52rem; margin: 2rem auto; padding: 0 1.5rem;
  line-height: 1.7; color: #1f2328;
}
a { color: #0969da; text-decoration: none; }
a:hover { text-decoration: underline; }
header.site {
  border-bottom: 2px solid #6E40C9; padding-bottom: 1rem; margin-bottom: 2rem;
}
header.site h1 { margin: 0; font-size: 1.8rem; }
header.site p { margin: .3rem 0 0; color: #57606a; }
nav.breadcrumb { font-size: .9rem; margin-bottom: 1.5rem; color: #57606a; }
main h1 { border-bottom: 1px solid #d0d7de; padding-bottom: .3rem; }
main table { border-collapse: collapse; width: 100%; margin: 1rem 0; }
main th, main td { border: 1px solid #d0d7de; padding: .4rem .7rem; text-align: left; }
main code { background: #eff1f3; padding: .1rem .35rem; border-radius: 4px; font-size: .92em; }
main pre { background: #eff1f3; padding: 1rem; border-radius: 8px; overflow-x: auto; }
main pre code { background: none; padding: 0; }
footer { margin-top: 3rem; border-top: 1px solid #d0d7de; padding-top: 1rem;
  font-size: .85rem; color: #57606a; }
@media (prefers-color-scheme: dark) {
  body { color: #e6edf3; background: #0d1117; }
  a { color: #58a6ff; }
  main h1 { border-color: #30363d; }
  main th, main td { border-color: #30363d; }
  main code, main pre { background: #161b22; }
  footer { border-color: #30363d; }
}
"""

def render(md_text: str, title: str, breadcrumb: str = "") -> str:
    body = markdown.markdown(md_text, extensions=["tables", "fenced_code"])
    crumb = f'<nav class="breadcrumb"><a href="/motion.mbt/">← 返回文档门户</a>{breadcrumb}</nav>' if breadcrumb else ""
    return f"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title} · motion</title>
<style>{CSS}</style>
</head>
<body>
<header class="site">
  <h1>motion</h1>
  <p>具身智能通用动作语义规范 · GB/Z 185-2026 执行层标准实现 · MoonBit</p>
</header>
{crumb}
<main>
{body}
</main>
<footer>
  <p>motion v0.1.0 · MIT License · <a href="https://atomgit.com/LOOYIABC/motion.mbt">AtomGit 主仓库</a> · <a href="https://github.com/walkzzz/motion.mbt">GitHub 镜像</a></p>
</footer>
</body>
</html>
"""

def main() -> None:
    os.makedirs(os.path.join(SITE, "docs"), exist_ok=True)

    docs = sorted(glob.glob(os.path.join(ROOT, "docs", "*.md")))
    items = []
    for d in docs:
        name = os.path.basename(d)
        rel = "docs/" + name[:-3] + ".html"
        title = name[:-3]
        items.append(f'<li><a href="{rel}">{title}</a></li>')
    listing = "\n".join(items)

    portal_md = f"""# motion 文档门户

**motion** 是 GB/Z 185-2026《人工智能 智能体互联》国家标准在「具身执行」维度的标准实现，
让智能体不仅能"说话"，还能"安全地动起来"。

- 五层纵深防御 × 8 攻击面（AS1-AS8）× 6 条安全不变式（I1-I6）
- 四阶段绑定引擎（引用解析 → 映射扩展 → 占用冲突 → SAC 校验）
- 四目标原生支持（native / wasm-gc / js / wasm），0 warning 门禁

## 快速链接

- [README（项目主页）](index_readme.html)
- [rules.md（开发规则全集）](rules.html)
- [SECURITY.md（安全策略总纲）](SECURITY.html)

## 文档套件（docs/）

<ul>
{listing}
</ul>

## 仓库

| 仓库 | 角色 |
|------|------|
| atomgit.com/LOOYIABC/motion.mbt | 主仓库（权威源） |
| gitcode.com/LOOYIABC/motion.mbt | 第二入口（同源共享存储） |
| github.com/walkzzz/motion.mbt | 同步镜像（CI/CD） |
"""
    with open(os.path.join(SITE, "index.html"), "w", encoding="utf-8") as f:
        f.write(render(portal_md, "文档门户"))

    readme = os.path.join(ROOT, "README.md")
    if os.path.exists(readme):
        with open(readme, encoding="utf-8") as f:
            txt = f.read()
        with open(os.path.join(SITE, "index_readme.html"), "w", encoding="utf-8") as f:
            f.write(render(txt, "README"))

    for src_name, out_name in (("rules.md", "rules.html"), ("SECURITY.md", "SECURITY.html")):
        src = os.path.join(ROOT, src_name)
        if os.path.exists(src):
            with open(src, encoding="utf-8") as f:
                txt = f.read()
            with open(os.path.join(SITE, out_name), "w", encoding="utf-8") as f:
                f.write(render(txt, src_name, f" · {src_name}"))

    for d in docs:
        with open(d, encoding="utf-8") as f:
            txt = f.read()
        out = os.path.join(SITE, "docs", os.path.basename(d)[:-3] + ".html")
        with open(out, "w", encoding="utf-8") as f:
            f.write(render(txt, os.path.basename(d), " · docs/" + os.path.basename(d)))

    total = 3 + len(docs)
    print(f"site built: {total} pages -> {SITE}")

if __name__ == "__main__":
    main()
