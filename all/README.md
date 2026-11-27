# all

门面包：一条 import 拿全部高频 API（image.mbt `all/` 模式）。

```moonbit
import "looyiabc/motion/all"

let sm = @all.new_statemachine()
let _ = @all.transition(sm, @all.StateEvent::Reset)
let gate = @all.new_gate(sm)
assert_false(@all.do_exec(gate, "walk"))   // I5
```

## 再导出范围

- `@geom`：Vec3 / SpatialDisplacement
- `@types`：全部核心类型 + 诊断/威胁函数
- `@safety`：SafetyStateMachine 全套（形式化验证 I1-I5）
- `@lib`：bind 四阶段引擎
- `@engine`：react 反应引擎
- `@guard`：四守卫（AS1/AS2/I5/I6）
- `@bridge`：GB/Z 185 协议桥
- `@motion`：version

**注意**：import 权限不随依赖传递——深层包仍需各自 `moon add`；方法不能再导出（`pub using` 限制），方法调用请用对应子包。
