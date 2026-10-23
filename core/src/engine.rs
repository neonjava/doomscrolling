use serde::{Deserialize, Serialize};

#[derive(Clone, Copy, Debug, Default, Deserialize, Serialize, PartialEq, Eq)]
pub struct Bounds {
    pub left: i32,
    pub top: i32,
    pub right: i32,
    pub bottom: i32,
}
impl Bounds {
    fn valid(self) -> bool {
        self.left >= 0 && self.top >= 0 && self.right > self.left && self.bottom > self.top
    }
}
#[derive(Debug, Deserialize)]
pub struct Node {
    pub id: String,
    pub bounds: Bounds,
}
#[derive(Debug, Deserialize)]
pub struct Snapshot {
    pub package: String,
    pub enabled: bool,
    pub youtube: bool,
    pub instagram: bool,
    pub width: i32,
    pub height: i32,
    pub nodes: Vec<Node>,
}
#[derive(Debug, Default, Serialize, PartialEq, Eq)]
pub struct Decision {
    pub active: bool,
    pub bounds: Bounds,
}

fn node<'a>(s: &'a Snapshot, suffix: &str) -> Option<&'a Node> {
    s.nodes.iter().find(|n| {
        n.id.strip_prefix(&format!("{}:id/", s.package)) == Some(suffix) && n.bounds.valid()
    })
}

pub fn detect(s: &Snapshot) -> Decision {
    if !s.enabled || s.nodes.len() > 600 || s.width <= 0 || s.height <= 0 {
        return Decision::default();
    }
    let candidate = match s.package.as_str() {
        "com.google.android.youtube" if s.youtube => {
            if node(s, "reel_watch_fragment_root").is_none() {
                return Decision::default();
            }
            node(s, "reel_player_page_content")
                .or_else(|| node(s, "reel_watch_player"))
                .map(|n| n.bounds)
        }
        "com.instagram.android" if s.instagram => {
            // Feed videos also expose clips media nodes; only the dedicated viewer pager qualifies.
            if node(s, "clips_item_overlay_component").is_none() {
                return Decision::default();
            }
            node(s, "clips_viewer_view_pager").map(|n| n.bounds)
        }
        _ => None,
    };
    let Some(mut bounds) = candidate else {
        return Decision::default();
    };
    bounds.right = bounds.right.min(s.width);
    bounds.bottom = bounds.bottom.min(s.height);
    // Modal panels get their own touch stream. Keep guarding only the exposed video.
    for id in ["app_engagement_panel", "bottom_sheet_container"] {
        if let Some(panel) = node(s, id) {
            bounds.bottom = bounds.bottom.min(panel.bounds.top);
        }
    }
    if !bounds.valid() {
        return Decision::default();
    }
    Decision {
        active: true,
        bounds,
    }
}

#[derive(Debug, Default)]
pub struct Engine {
    pub active: bool,
    gesture: Option<Gesture>,
    last_warning: Option<i64>,
}
#[derive(Debug)]
struct Gesture {
    x: f32,
    y: f32,
    time: i64,
    max_x: f32,
    max_y: f32,
    blocked: bool,
    multi: bool,
}
impl Engine {
    pub fn set_active(&mut self, active: bool) {
        self.active = active;
        if !active {
            self.gesture = None;
            self.last_warning = None;
        }
    }
    /// 0: consume; 1: forward a tap; 2: show warning. Every drag is consumed.
    pub fn touch(&mut self, action: i32, x: f32, y: f32, time: i64, slop: f32) -> i32 {
        if !self.active || !x.is_finite() || !y.is_finite() || !slop.is_finite() || slop <= 0.0 {
            self.gesture = None;
            return 0;
        }
        if action == 0 {
            self.gesture = Some(Gesture {
                x,
                y,
                time,
                max_x: 0.0,
                max_y: 0.0,
                blocked: false,
                multi: false,
            });
            return 0;
        }
        if action == 3 {
            self.gesture = None;
            return 0;
        }
        let Some(g) = self.gesture.as_mut() else {
            return 0;
        };
        if action == 5 {
            g.multi = true;
        }
        g.max_x = g.max_x.max((x - g.x).abs());
        g.max_y = g.max_y.max((y - g.y).abs());
        let mut result = 0;
        if g.max_y > slop && !g.blocked {
            g.blocked = true;
            if self
                .last_warning
                .is_none_or(|t| time.saturating_sub(t) >= 1800)
            {
                self.last_warning = Some(time);
                result = 2;
            }
        }
        if action == 1 {
            if !g.blocked
                && !g.multi
                && g.max_x <= slop
                && g.max_y <= slop
                && (0..=500).contains(&time.saturating_sub(g.time))
            {
                result = 1;
            }
            self.gesture = None;
        }
        result
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    fn snapshot() -> Snapshot {
        Snapshot {
            package: "com.google.android.youtube".into(),
            enabled: true,
            youtube: true,
            instagram: true,
            width: 1080,
            height: 2400,
            nodes: vec![
                Node {
                    id: "com.google.android.youtube:id/reel_watch_fragment_root".into(),
                    bounds: Bounds {
                        left: 0,
                        top: 100,
                        right: 1080,
                        bottom: 2200,
                    },
                },
                Node {
                    id: "com.google.android.youtube:id/reel_player_page_content".into(),
                    bounds: Bounds {
                        left: 0,
                        top: 100,
                        right: 1080,
                        bottom: 2200,
                    },
                },
            ],
        }
    }
    #[test]
    fn recognizes_player_but_not_tab_or_other_package() {
        let mut s = snapshot();
        assert!(detect(&s).active);
        s.package = "other.app".into();
        assert!(!detect(&s).active);
        s.package = "com.google.android.youtube".into();
        s.nodes.truncate(1);
        assert!(!detect(&s).active);
    }
    #[test]
    fn settings_and_invalid_bounds_disable_protection() {
        let mut s = snapshot();
        s.youtube = false;
        assert!(!detect(&s).active);
        s.youtube = true;
        s.enabled = false;
        assert!(!detect(&s).active);
        s.enabled = true;
        s.nodes[1].bounds.bottom = 0;
        assert!(!detect(&s).active);
    }
    #[test]
    fn comments_remain_outside_guard() {
        let mut s = snapshot();
        s.nodes.push(Node {
            id: "com.google.android.youtube:id/app_engagement_panel".into(),
            bounds: Bounds {
                left: 0,
                top: 700,
                right: 1080,
                bottom: 2400,
            },
        });
        assert_eq!(detect(&s).bounds.bottom, 700);
    }
    #[test]
    fn rejects_oversized_tree() {
        let mut s = snapshot();
        for _ in 0..601 {
            s.nodes.push(Node {
                id: String::new(),
                bounds: Bounds::default(),
            });
        }
        assert!(!detect(&s).active);
    }
    fn engine() -> Engine {
        let mut e = Engine::default();
        e.set_active(true);
        e
    }
    #[test]
    fn taps_forward_but_both_swipe_directions_stop() {
        let mut e = engine();
        e.touch(0, 100.0, 100.0, 0, 12.0);
        assert_eq!(e.touch(1, 102.0, 103.0, 90, 12.0), 1);
        for (time, y) in [(2000, 500.0), (4000, 0.0)] {
            e.touch(0, 100.0, 100.0, time, 12.0);
            assert_eq!(e.touch(2, 100.0, y, time + 30, 12.0), 2);
            assert_eq!(e.touch(1, 100.0, y, time + 60, 12.0), 0);
        }
    }
    #[test]
    fn fast_swipe_warns_even_without_move() {
        let mut e = engine();
        e.touch(0, 0.0, 400.0, 0, 12.0);
        assert_eq!(e.touch(1, 0.0, 10.0, 10, 12.0), 2);
    }
    #[test]
    fn warnings_are_throttled_but_swipes_stay_blocked() {
        let mut e = engine();
        for (t, expected) in [(0, 2), (100, 0), (2000, 2)] {
            e.touch(0, 0.0, 0.0, t, 12.0);
            assert_eq!(e.touch(1, 0.0, 400.0, t + 50, 12.0), expected);
        }
    }
    #[test]
    fn returning_to_start_does_not_turn_swipe_into_tap() {
        let mut e = engine();
        e.touch(0, 0.0, 0.0, 0, 12.0);
        e.touch(2, 0.0, 100.0, 10, 12.0);
        assert_eq!(e.touch(1, 0.0, 0.0, 20, 12.0), 0);
    }
    #[test]
    fn cancel_multitouch_and_deactivation_never_click() {
        let mut e = engine();
        e.touch(0, 0.0, 0.0, 0, 12.0);
        e.touch(3, 0.0, 0.0, 10, 12.0);
        assert_eq!(e.touch(1, 0.0, 0.0, 20, 12.0), 0);
        e.touch(0, 0.0, 0.0, 0, 12.0);
        e.touch(5, 0.0, 0.0, 10, 12.0);
        assert_eq!(e.touch(1, 0.0, 0.0, 20, 12.0), 0);
        e.touch(0, 0.0, 0.0, 0, 12.0);
        e.set_active(false);
        assert_eq!(e.touch(1, 0.0, 0.0, 20, 12.0), 0);
    }
}

#[cfg(test)]
mod instagram_tests {
    use super::*;
    fn snapshot() -> Snapshot {
        Snapshot {
            package: "com.instagram.android".into(),
            enabled: true,
            youtube: true,
            instagram: true,
            width: 1080,
            height: 2400,
            nodes: vec![
                Node {
                    id: "com.instagram.android:id/clips_viewer_view_pager".into(),
                    bounds: Bounds {
                        left: 0,
                        top: 126,
                        right: 1080,
                        bottom: 2196,
                    },
                },
                Node {
                    id: "com.instagram.android:id/clips_item_overlay_component".into(),
                    bounds: Bounds {
                        left: 0,
                        top: 126,
                        right: 1080,
                        bottom: 2196,
                    },
                },
            ],
        }
    }
    #[test]
    fn reels_viewer_is_guarded_but_feed_is_not() {
        let mut s = snapshot();
        assert!(detect(&s).active);
        s.nodes[0].id = "com.instagram.android:id/swipeable_tab_view_pager".into();
        assert!(!detect(&s).active);
    }
    #[test]
    fn instagram_switch_does_not_depend_on_youtube() {
        let mut s = snapshot();
        s.youtube = false;
        assert!(detect(&s).active);
        s.instagram = false;
        assert!(!detect(&s).active);
    }
    #[test]
    fn full_height_comments_remove_guard() {
        let mut s = snapshot();
        s.nodes.push(Node {
            id: "com.instagram.android:id/bottom_sheet_container".into(),
            bounds: Bounds {
                left: 0,
                top: 126,
                right: 1080,
                bottom: 2340,
            },
        });
        assert!(!detect(&s).active);
    }
    #[test]
    fn partial_sheet_leaves_exposed_video_guarded() {
        let mut s = snapshot();
        s.nodes.push(Node {
            id: "com.instagram.android:id/bottom_sheet_container".into(),
            bounds: Bounds {
                left: 0,
                top: 900,
                right: 1080,
                bottom: 2340,
            },
        });
        assert_eq!(detect(&s).bounds.bottom, 900);
    }
}
