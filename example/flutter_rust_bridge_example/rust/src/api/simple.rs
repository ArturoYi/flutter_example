//! 两种最常用的调用方式。
//!
//! 没有特别标注的 `pub fn` 会生成 Dart 里的 `Future`：Rust 在工作线程执行，
//! UI 线程不会被堵住。加上 `#[frb(sync)]` 之后，Dart 侧变成普通的同步函数，
//! 可以在 `build` 里直接调用，但函数会占用调用它的那条线程。

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WorkResult {
    pub primes: i64,
    pub elapsed_millis: i64,
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

/// 很快能算完的纯函数，用同步调用即可。
#[flutter_rust_bridge::frb(sync)]
pub fn greet(name: String) -> String {
    let name = name.trim();
    if name.is_empty() {
        "Hello, Rust!".to_string()
    } else {
        format!("Hello, {name}!")
    }
}

/// 和下面的异步版本是同一段计算。差别只在 Dart 会不会等在调用线程上。
#[flutter_rust_bridge::frb(sync)]
pub fn count_primes_blocking(limit: u32) -> WorkResult {
    measure_primes(limit)
}

pub fn count_primes(limit: u32) -> WorkResult {
    measure_primes(limit)
}

fn measure_primes(limit: u32) -> WorkResult {
    let limit = limit.clamp(1_000, 2_000_000);
    let started = std::time::Instant::now();
    let primes = count_primes_until(limit);
    WorkResult {
        primes,
        elapsed_millis: i64::try_from(started.elapsed().as_millis()).unwrap_or(i64::MAX),
    }
}

fn count_primes_until(limit: u32) -> i64 {
    let mut found = 0i64;
    for value in 2..=limit {
        if is_prime(value) {
            found += 1;
        }
    }
    found
}

fn is_prime(value: u32) -> bool {
    if value < 2 {
        return false;
    }
    let mut factor = 2u32;
    while factor.saturating_mul(factor) <= value {
        if value % factor == 0 {
            return false;
        }
        factor += 1;
    }
    true
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn greet_trims_and_rejects_blank_names() {
        assert_eq!(greet("  Tom  ".into()), "Hello, Tom!");
        assert_eq!(greet("   ".into()), "Hello, Rust!");
    }

    #[test]
    fn counts_primes_below_ten() {
        assert_eq!(count_primes_until(10), 4);
    }
}
