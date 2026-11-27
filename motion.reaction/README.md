# motion.reaction

L2 反应引擎：环境反馈 → 控制决策（spec 3.2），升级链有界（I3）。

## 决策空间

`Continue / Adjust / Avoid / Wait / SafeHold / Abort / Replan / FaultLocked`

- 策略匹配：触发器（反馈类型 + 最低严重度 + 来源过滤）
- 升级链：深度受限（MAX_ESCALATION = 5），链耗尽 → FaultLocked（I3 有界锁死）
- 安全事件不走此引擎——直接抢占状态机（I1）

## 用法

```moonbit
import "looyiabc/motion.reaction/engine"

let decision = @engine.react(policies, feedback)
```

反馈来源必须先经 `motion.security/guard` 的 `authenticate_feedback` 认证（I6）。
