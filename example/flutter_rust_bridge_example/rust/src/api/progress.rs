//! `StreamSink<T>` 不会出现在 Dart 参数里。
//! 生成结果是 `Stream<T>`：Rust 每 `add` 一次，Dart 就收到一个事件。

use crate::frb_generated::StreamSink;

pub fn count_down(start: u32, sink: StreamSink<i32>) {
    let start = start.clamp(1, 10);
    for value in (0..=start).rev() {
        let _ = sink.add(i32::try_from(value).unwrap_or(i32::MAX));
        if value == 0 {
            break;
        }
        std::thread::sleep(std::time::Duration::from_millis(400));
    }
}
