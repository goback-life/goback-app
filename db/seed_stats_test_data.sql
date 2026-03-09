-- Test data for lockout stats dashboard
-- User: 30e211e6-eb93-417b-a825-cf4761afea07
-- Run in Supabase SQL Editor, then delete this file

INSERT INTO lockout_completed_log (user_id, session_date, duration_minutes, goback_score) VALUES
-- This week (Mon Mar 9 – Sun Mar 15, 2026)
('30e211e6-eb93-417b-a825-cf4761afea07', '2026-03-09', 45, 72),
('30e211e6-eb93-417b-a825-cf4761afea07', '2026-03-09', 30, 65),

-- Last week (Mon Mar 2 – Sun Mar 8)
('30e211e6-eb93-417b-a825-cf4761afea07', '2026-03-02', 60, 88),
('30e211e6-eb93-417b-a825-cf4761afea07', '2026-03-03', 25, 55),
('30e211e6-eb93-417b-a825-cf4761afea07', '2026-03-04', 90, 91),
('30e211e6-eb93-417b-a825-cf4761afea07', '2026-03-05', 15, 40),
('30e211e6-eb93-417b-a825-cf4761afea07', '2026-03-06', 120, 95),
('30e211e6-eb93-417b-a825-cf4761afea07', '2026-03-07', 45, 70),
('30e211e6-eb93-417b-a825-cf4761afea07', '2026-03-08', 75, 82),

-- Two weeks ago (Mon Feb 23 – Sun Mar 1)
('30e211e6-eb93-417b-a825-cf4761afea07', '2026-02-23', 55, 78),
('30e211e6-eb93-417b-a825-cf4761afea07', '2026-02-25', 110, 93),
('30e211e6-eb93-417b-a825-cf4761afea07', '2026-02-27', 35, 60),
('30e211e6-eb93-417b-a825-cf4761afea07', '2026-02-28', 80, 85);
