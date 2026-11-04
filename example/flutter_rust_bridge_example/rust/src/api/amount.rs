//! `Result<T, E>` 到了 Dart 变成：成功时返回 T，失败时抛出 E。
//!
//! 带数据的枚举默认会生成 freezed 类。这里把错误做成结构体，
//! 生成的 Dart 可以直接读，不必再跑一层 build_runner。

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AmountErrorKind {
    Empty,
    NotANumber,
    Negative,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AmountError {
    pub kind: AmountErrorKind,
    pub detail: String,
}

/// 把「元」解析成「分」。用整数保存金额，避免浮点误差留在业务里。
pub fn parse_cents(raw: String) -> Result<i64, AmountError> {
    let raw = raw.trim();
    if raw.is_empty() {
        return Err(AmountError {
            kind: AmountErrorKind::Empty,
            detail: "金额是空的".to_string(),
        });
    }

    let yuan: f64 = match raw.parse() {
        Ok(value) => value,
        Err(_) => {
            return Err(AmountError {
                kind: AmountErrorKind::NotANumber,
                detail: raw.to_string(),
            });
        }
    };
    if !yuan.is_finite() {
        return Err(AmountError {
            kind: AmountErrorKind::NotANumber,
            detail: raw.to_string(),
        });
    }
    if yuan < 0.0 {
        return Err(AmountError {
            kind: AmountErrorKind::Negative,
            detail: raw.to_string(),
        });
    }

    Ok((yuan * 100.0).round() as i64)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_yuan_into_cents() {
        assert_eq!(parse_cents(" 12.5 ".into()).unwrap(), 1250);
        assert_eq!(
            parse_cents("  ".into()).unwrap_err().kind,
            AmountErrorKind::Empty
        );
        assert_eq!(
            parse_cents("abc".into()).unwrap_err().kind,
            AmountErrorKind::NotANumber
        );
        assert_eq!(
            parse_cents("-1".into()).unwrap_err().kind,
            AmountErrorKind::Negative
        );
    }
}
