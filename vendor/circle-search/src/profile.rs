use gtk::prelude::*;
use std::{cell::RefCell, rc::Rc, time::Instant};

pub fn attach(widget: &impl IsA<gtk::Widget>, state: Rc<RefCell<crate::Selection>>) {
    if std::env::var_os("CIRCLE_SEARCH_PROFILE").is_none() {
        return;
    }
    let Some(clock) = widget.frame_clock() else {
        return;
    };
    let samples = Rc::new(RefCell::new(Vec::<i64>::new()));
    let frames = samples.clone();
    clock.connect_after_paint(move |clock| {
        if state.borrow().origin.is_some() {
            frames.borrow_mut().push(clock.frame_time());
        }
    });
    let started = Instant::now();
    widget.connect_unrealize(move |_| {
        let frames = samples.borrow();
        let mut intervals: Vec<_> = frames.windows(2).map(|w| (w[1]-w[0]) as f64 / 1000.).collect();
        intervals.sort_by(f64::total_cmp);
        if !intervals.is_empty() {
            eprintln!("PROFILE: frames={} active_interval_median_ms={:.2} p95_ms={:.2} mapped_seconds={:.2}", frames.len(), intervals[intervals.len()/2], intervals[(intervals.len()-1)*95/100], started.elapsed().as_secs_f64());
        }
    });
}
