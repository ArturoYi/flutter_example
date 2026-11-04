//! 字段不公开时，对象留在 Rust 内存里。
//! Dart 拿到的是句柄，方法调用仍然回到这个实例。
//! 页面不用它时调用生成的 `dispose()`，Rust 侧才会释放。

#[flutter_rust_bridge::frb(opaque)]
pub struct Ledger {
    cents: i64,
    entries: u32,
}

impl Ledger {
    #[flutter_rust_bridge::frb(sync)]
    pub fn new() -> Self {
        Self {
            cents: 0,
            entries: 0,
        }
    }

    /// `yuan` 是元。返回记账之后的余额，单位也是元。
    #[flutter_rust_bridge::frb(sync)]
    pub fn deposit(&mut self, yuan: f64) -> f64 {
        if yuan.is_finite() {
            self.cents += (yuan * 100.0).round() as i64;
            self.entries = self.entries.saturating_add(1);
        }
        self.balance()
    }

    #[flutter_rust_bridge::frb(sync, getter)]
    pub fn balance(&self) -> f64 {
        self.cents as f64 / 100.0
    }

    #[flutter_rust_bridge::frb(sync, getter)]
    pub fn entries(&self) -> u32 {
        self.entries
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn reset(&mut self) {
        self.cents = 0;
        self.entries = 0;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn deposit_keeps_integer_cents() {
        let mut ledger = Ledger::new();
        ledger.deposit(12.5);
        ledger.deposit(0.2);
        assert_eq!(ledger.cents, 1270);
        assert_eq!(ledger.entries(), 2);
        ledger.reset();
        assert_eq!(ledger.cents, 0);
    }
}
