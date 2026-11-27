# motion.bind

L2 绑定引擎：四阶段验证管线（spec 3.1）。

## 四阶段

1. **引用解析**（Stage 1）：Primitive 存在性 + 参数类型/必填校验（诊断码 1000/1001/1002）
2. **映射扩展**（Stage 2）：MappingGraph 环/自环检测，深度受限路径搜索（1050/1051）
3. **占用冲突**（Stage 3）：独占部件并行冲突检测（1100）
4. **SAC 校验**（Stage 4）：语义达成条件结构完整性（1200）

## 用法

```moonbit
import "looyiabc/motion.bind/lib"

let result = @lib.bind(seq, graph, registry)
// BindResult::Ok(BoundActionSeq) | Error(Array[Diagnostic])
```

任何动作未过四阶段不得执行（L2 语义校验层，同时执行 AS2/AS7 防线）。
