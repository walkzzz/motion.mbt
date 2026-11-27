# motion.security

L2 安全守卫：五层纵深防御的运行时执行层。

## 四守卫

| 守卫 | 攻击面/不变式 | 职责 |
|------|--------------|------|
| `supply` | AS1 | 供应链签名验证 + 依赖锁哈希（P1+ 接 moon_guard Ed25519） |
| `nli_guard` | AS2 | NLI 注入防护——危险基元/歧义/不可解释一律拒绝 |
| `feedback_auth` | I6 | 反馈来源认证——未注册传感器拒绝（1730），过期反馈拒绝（1731） |
| `output_gate` | I5 | 输出门控——非 Executing 恒拒绝，权威门控无后门 |

## 用法

```moonbit
import "looyiabc/motion.security/guard"

match @guard.authenticate_feedback(sensor_reg, feedback) {
  Ok(authed) => @engine.react(policies, authed)
  Err(e) => // 拒绝处理未认证反馈
}
```

I6 的形式化证明为 P2 义务（Map/Array lowering 限制），当前由 3 个运行时测试覆盖。
