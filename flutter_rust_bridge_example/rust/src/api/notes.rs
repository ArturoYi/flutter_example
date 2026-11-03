//! 结构体和枚举会生成对应的 Dart 类。
//! 字段都是公开、可跨语言传递的类型，所以整份数据会被拷贝过去，
//! 而不是在 Rust 里留一个对象。

#[derive(Debug, Clone)]
pub struct Note {
    pub title: String,
    pub priority: Priority,
}

#[derive(Debug, Clone, Copy)]
pub enum Priority {
    Low,
    Normal,
    High,
}

#[derive(Debug, Clone)]
pub struct NoteReport {
    pub total: i32,
    pub high: i32,
    pub headline: String,
}

pub fn report(notes: Vec<Note>) -> NoteReport {
    let total = i32::try_from(notes.len()).unwrap_or(i32::MAX);
    let high = notes
        .iter()
        .filter(|note| matches!(note.priority, Priority::High))
        .count();
    let high = i32::try_from(high).unwrap_or(i32::MAX);
    let titles = notes
        .iter()
        .map(|note| note.title.trim())
        .filter(|title| !title.is_empty())
        .collect::<Vec<_>>()
        .join("、");

    let headline = if total == 0 {
        "还没有笔记".to_string()
    } else if titles.is_empty() {
        format!("共 {total} 条，其中 {high} 条高优先级")
    } else {
        format!("共 {total} 条，其中 {high} 条高优先级：{titles}")
    };

    NoteReport {
        total,
        high,
        headline,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn report_counts_high_priority_titles() {
        let report = report(vec![
            Note {
                title: "  买菜 ".into(),
                priority: Priority::Normal,
            },
            Note {
                title: "报销".into(),
                priority: Priority::High,
            },
        ]);
        assert_eq!(report.total, 2);
        assert_eq!(report.high, 1);
        assert_eq!(report.headline, "共 2 条，其中 1 条高优先级：买菜、报销");
    }
}
