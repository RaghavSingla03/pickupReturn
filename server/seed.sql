-- Smart Return Load Platform: development seed data
-- PostgreSQL / bcryptjs-compatible password hashes
--
-- Run from PowerShell:
--   psql -U postgres -h localhost -d returnload -f seed.sql
--
-- This script ADDS sample records. It does not DROP or TRUNCATE tables.
-- Run once on your development database. It stops if any seed email already exists,
-- to avoid creating duplicate sample data on a second run.

BEGIN;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM users
    WHERE email IN (
      'admin@returnload.com',
      'shipper@returnload.com',
      'shipper2@returnload.com',
      'shipper3@returnload.com',
      'driver@returnload.com',
      'driver2@returnload.com',
      'driver3@returnload.com',
      'driver4@returnload.com',
      'driver5@returnload.com',
      'driver6@returnload.com'
    )
  ) THEN
    RAISE EXCEPTION 'Seed accounts already exist. This seed.sql is intended to run once; no data was added.';
  END IF;
END $$;

-- 1) USERS
-- Known test passwords:
-- admin@returnload.com  -> Admin@123
-- shipper@returnload.com -> Shipper@123
-- driver@returnload.com  -> Driver@123
INSERT INTO users
  (name, email, phone, password_hash, role, avatar_url, avg_rating,
   total_ratings, is_active, created_at, password_changed_at)
VALUES
  ('ReturnLoad Admin', 'admin@returnload.com', '9000000001',
   '$2a$10$EFvI2edyxSKNqp4eGXuKeusbNlDlh7o4ZGGrJ/ZKN9YXfW9NrgL/i',
   'admin', NULL, 0, 0, 1, NOW() - INTERVAL '60 days', NOW() - INTERVAL '60 days'),

  ('Amit Sharma', 'shipper@returnload.com', '9876501001',
   '$2a$10$E8x/m6Z6e7bTEJcy9Gc3Juwg2Kwp/g.ChAAsEmAhZF0e3AxwfpUj.',
   'shipper', NULL, 4.7, 12, 1, NOW() - INTERVAL '45 days', NOW() - INTERVAL '45 days'),
  ('Neha Gupta', 'shipper2@returnload.com', '9876501002',
   '$2a$10$E8x/m6Z6e7bTEJcy9Gc3Juwg2Kwp/g.ChAAsEmAhZF0e3AxwfpUj.',
   'shipper', NULL, 4.5, 8, 1, NOW() - INTERVAL '35 days', NOW() - INTERVAL '35 days'),
  ('Vikram Singh', 'shipper3@returnload.com', '9876501003',
   '$2a$10$E8x/m6Z6e7bTEJcy9Gc3Juwg2Kwp/g.ChAAsEmAhZF0e3AxwfpUj.',
   'shipper', NULL, 4.8, 6, 1, NOW() - INTERVAL '25 days', NOW() - INTERVAL '25 days'),

  ('Rahul Verma', 'driver@returnload.com', '9876502001',
   '$2a$10$e3KA.o2hfcWvwU35QGnxi.gAVHVbJITvS.xqVI8VaCTRyCm5SL71a',
   'driver', NULL, 4.8, 18, 1, NOW() - INTERVAL '50 days', NOW() - INTERVAL '50 days'),
  ('Sandeep Kumar', 'driver2@returnload.com', '9876502002',
   '$2a$10$e3KA.o2hfcWvwU35QGnxi.gAVHVbJITvS.xqVI8VaCTRyCm5SL71a',
   'driver', NULL, 4.6, 14, 1, NOW() - INTERVAL '42 days', NOW() - INTERVAL '42 days'),
  ('Imran Khan', 'driver3@returnload.com', '9876502003',
   '$2a$10$e3KA.o2hfcWvwU35QGnxi.gAVHVbJITvS.xqVI8VaCTRyCm5SL71a',
   'driver', NULL, 4.9, 21, 1, NOW() - INTERVAL '38 days', NOW() - INTERVAL '38 days'),
  ('Manoj Yadav', 'driver4@returnload.com', '9876502004',
   '$2a$10$e3KA.o2hfcWvwU35QGnxi.gAVHVbJITvS.xqVI8VaCTRyCm5SL71a',
   'driver', NULL, 4.4, 9, 1, NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days'),
  ('Deepak Patel', 'driver5@returnload.com', '9876502005',
   '$2a$10$e3KA.o2hfcWvwU35QGnxi.gAVHVbJITvS.xqVI8VaCTRyCm5SL71a',
   'driver', NULL, 4.7, 11, 1, NOW() - INTERVAL '22 days', NOW() - INTERVAL '22 days'),
  ('Arjun Mehta', 'driver6@returnload.com', '9876502006',
   '$2a$10$e3KA.o2hfcWvwU35QGnxi.gAVHVbJITvS.xqVI8VaCTRyCm5SL71a',
   'driver', NULL, 4.5, 7, 1, NOW() - INTERVAL '15 days', NOW() - INTERVAL '15 days');

-- 2) TRUCKS
INSERT INTO trucks
  (user_id, truck_type, capacity_tons, permit_number, home_state,
   registration_number, insurance_expiry, created_at)
SELECT u.id, v.truck_type, v.capacity_tons, v.permit_number, v.home_state,
       v.registration_number, v.insurance_expiry, NOW() - INTERVAL '20 days'
FROM (VALUES
  ('driver@returnload.com',  'Container',          16.0, 'HR-PER-1001', 'Haryana',       'HR55AB1234', CURRENT_DATE + 240),
  ('driver2@returnload.com', 'Open Truck',         12.0, 'PB-PER-1002', 'Punjab',        'PB10CD2345', CURRENT_DATE + 190),
  ('driver3@returnload.com', 'Trailer',            25.0, 'UP-PER-1003', 'Uttar Pradesh', 'UP32EF3456', CURRENT_DATE + 300),
  ('driver4@returnload.com', 'Flatbed',            18.0, 'RJ-PER-1004', 'Rajasthan',    'RJ14GH4567', CURRENT_DATE + 150),
  ('driver5@returnload.com', 'Refrigerated',       10.0, 'DL-PER-1005', 'Delhi',         'DL1LJK5678', CURRENT_DATE + 270),
  ('driver6@returnload.com', 'Multi-axle',         30.0, 'MH-PER-1006', 'Maharashtra',  'MH12MN6789', CURRENT_DATE + 210)
) AS v(email, truck_type, capacity_tons, permit_number, home_state,
       registration_number, insurance_expiry)
JOIN users u ON u.email = v.email;

-- 3) DOCUMENTS
INSERT INTO documents (user_id, doc_type, file_url, verified, uploaded_at)
SELECT u.id, v.doc_type, v.file_url, v.verified, NOW() - INTERVAL '5 days'
FROM (VALUES
  ('driver@returnload.com',  'RC',        'https://example.com/demo/rahul-rc.pdf', 1),
  ('driver@returnload.com',  'licence',   'https://example.com/demo/rahul-licence.pdf', 1),
  ('driver@returnload.com',  'insurance', 'https://example.com/demo/rahul-insurance.pdf', 1),
  ('driver2@returnload.com', 'RC',        'https://example.com/demo/sandeep-rc.pdf', 1),
  ('driver2@returnload.com', 'permit',    'https://example.com/demo/sandeep-permit.pdf', 1),
  ('driver3@returnload.com', 'RC',        'https://example.com/demo/imran-rc.pdf', 0),
  ('driver3@returnload.com', 'licence',   'https://example.com/demo/imran-licence.pdf', 1),
  ('driver4@returnload.com', 'RC',        'https://example.com/demo/manoj-rc.pdf', 0),
  ('driver5@returnload.com', 'RC',        'https://example.com/demo/deepak-rc.pdf', 1),
  ('driver6@returnload.com', 'RC',        'https://example.com/demo/arjun-rc.pdf', 1)
) AS v(email, doc_type, file_url, verified)
JOIN users u ON u.email = v.email;

-- 4) DRIVER AVAILABILITY (coordinates are approximate city locations)
INSERT INTO driver_availability
  (user_id, current_lat, current_lng, dest_lat, dest_lng,
   current_city, destination_city, available_from, available_until, status)
SELECT u.id, v.current_lat, v.current_lng, v.dest_lat, v.dest_lng,
       v.current_city, v.destination_city, NOW() - INTERVAL '2 hours',
       NOW() + INTERVAL '3 days', v.status
FROM (VALUES
  ('driver@returnload.com',  28.6139, 77.2090, 19.0760, 72.8777, 'Delhi',       'Mumbai',      'active'),
  ('driver2@returnload.com', 30.9010, 75.8573, 28.6139, 77.2090, 'Ludhiana',    'Delhi',       'active'),
  ('driver3@returnload.com', 26.9124, 75.7873, 23.0225, 72.5714, 'Jaipur',      'Ahmedabad',   'active'),
  ('driver4@returnload.com', 26.8467, 80.9462, 25.3176, 82.9739, 'Lucknow',     'Varanasi',    'active'),
  ('driver5@returnload.com', 19.0760, 72.8777, 18.5204, 73.8567, 'Mumbai',      'Pune',        'matched'),
  ('driver6@returnload.com', 12.9716, 77.5946, 17.3850, 78.4867, 'Bengaluru',   'Hyderabad',   'active')
) AS v(email, current_lat, current_lng, dest_lat, dest_lng,
       current_city, destination_city, status)
JOIN users u ON u.email = v.email;

-- 5) LOADS
INSERT INTO loads
  (user_id, pickup_lat, pickup_lng, delivery_lat, delivery_lng,
   pickup_city, delivery_city, cargo_type, weight_tons, description,
   handling_instructions, offered_price, timeline, status, created_at)
SELECT u.id, v.pickup_lat, v.pickup_lng, v.delivery_lat, v.delivery_lng,
       v.pickup_city, v.delivery_city, v.cargo_type, v.weight_tons,
       v.description, v.handling_instructions, v.offered_price,
       v.timeline, v.status, NOW() - v.age
FROM (VALUES
  ('shipper@returnload.com',  28.6139, 77.2090, 19.0760, 72.8777, 'Delhi',       'Mumbai',      'Electronics',       8.0,  'Packaged electronic goods',       'Keep cargo dry; sealed cartons.',       42000.0, 'Pickup within 2 days',       'booked',      INTERVAL '8 days'),
  ('shipper@returnload.com',  30.7333, 76.7794, 28.6139, 77.2090, 'Chandigarh',  'Delhi',       'FMCG',              6.0,  'Packaged household products',     'Avoid exposure to moisture.',           18000.0, 'Pickup tomorrow',             'booked',      INTERVAL '6 days'),
  ('shipper2@returnload.com', 19.0760, 72.8777, 18.5204, 73.8567, 'Mumbai',      'Pune',        'Pharmaceuticals',   4.0,  'Sealed non-hazardous cartons',    'Maintain clean, dry conditions.',       12000.0, 'Pickup within 24 hours',      'in_transit',  INTERVAL '5 days'),
  ('shipper2@returnload.com', 26.9124, 75.7873, 23.0225, 72.5714, 'Jaipur',      'Ahmedabad',   'Textiles',          9.0,  'Cotton fabric bales',             'Protect from rain and dust.',           22000.0, 'Pickup in 3 days',            'open',        INTERVAL '1 day'),
  ('shipper3@returnload.com',  12.9716, 77.5946, 17.3850, 78.4867, 'Bengaluru',   'Hyderabad',   'Industrial parts',  14.0, 'Machine components on pallets',  'Use straps; avoid rough handling.',     26000.0, 'Pickup within 48 hours',      'open',        INTERVAL '12 hours'),
  ('shipper3@returnload.com',  26.8467, 80.9462, 25.3176, 82.9739, 'Lucknow',     'Varanasi',    'Agricultural goods',7.0,  'Bagged packaged grain',           'Keep bags covered and ventilated.',    14000.0, 'Pickup this week',            'open',        INTERVAL '8 hours'),
  ('shipper@returnload.com',  28.4595, 77.0266, 26.9124, 75.7873, 'Gurugram',    'Jaipur',      'Auto components',   5.0,  'Automotive spare parts',          'Handle boxed components carefully.',   16000.0, 'Pickup within 2 days',       'delivered',   INTERVAL '12 days'),
  ('shipper2@returnload.com', 22.5726, 88.3639, 20.2961, 85.8245, 'Kolkata',     'Bhubaneswar', 'Consumer goods',    6.5,  'Retail-ready cartons',            'Keep shipment secured.',                15000.0, 'Pickup within 3 days',        'cancelled',   INTERVAL '15 days')
) AS v(email, pickup_lat, pickup_lng, delivery_lat, delivery_lng,
       pickup_city, delivery_city, cargo_type, weight_tons, description,
       handling_instructions, offered_price, timeline, status, age)
JOIN users u ON u.email = v.email;

-- 6) BOOKINGS
-- Load rows are matched by shipper, route and cargo description.
INSERT INTO bookings
  (load_id, driver_id, shipper_id, agreed_price, status,
   booked_at, picked_up_at, delivered_at)
SELECT l.id, d.id, s.id, v.agreed_price, v.status,
       NOW() - v.booked_age, v.picked_age, v.delivered_age
FROM (VALUES
  ('shipper@returnload.com',  'Delhi',      'Mumbai',      'Electronics',      'driver@returnload.com',  40000.0, 'delivered',  INTERVAL '7 days', NOW() - INTERVAL '6 days', NOW() - INTERVAL '4 days'),
  ('shipper@returnload.com',  'Chandigarh', 'Delhi',       'FMCG',             'driver2@returnload.com', 17500.0, 'in_transit', INTERVAL '5 days', NOW() - INTERVAL '3 days', NULL::timestamptz),
  ('shipper2@returnload.com', 'Mumbai',     'Pune',        'Pharmaceuticals',  'driver5@returnload.com', 11500.0, 'picked_up',  INTERVAL '4 days', NOW() - INTERVAL '2 days', NULL::timestamptz),
  ('shipper@returnload.com',  'Gurugram',   'Jaipur',      'Auto components',  'driver3@returnload.com', 15500.0, 'delivered',  INTERVAL '11 days',NOW() - INTERVAL '10 days',NOW() - INTERVAL '8 days')
) AS v(shipper_email, pickup_city, delivery_city, cargo_type, driver_email,
       agreed_price, status, booked_age, picked_age, delivered_age)
JOIN users s ON s.email = v.shipper_email
JOIN users d ON d.email = v.driver_email
JOIN loads l ON l.user_id = s.id
  AND l.pickup_city = v.pickup_city
  AND l.delivery_city = v.delivery_city
  AND l.cargo_type = v.cargo_type;

-- 7) RATINGS (only completed bookings)
INSERT INTO ratings (booking_id, from_user_id, to_user_id, score, comment, rated_at)
SELECT b.id, x.from_id, x.to_id, x.score, x.comment, NOW() - INTERVAL '3 days'
FROM (
  SELECT id, driver_id, shipper_id
  FROM bookings
  WHERE status = 'delivered'
  ORDER BY id
  LIMIT 2
) b
CROSS JOIN LATERAL (
  VALUES
    (b.shipper_id, b.driver_id, 5, 'Professional communication and on-time delivery.'),
    (b.driver_id, b.shipper_id, 4, 'Cargo details and pickup coordination were clear.')
) AS x(from_id, to_id, score, comment);

-- 8) TRACKING UPDATES
INSERT INTO tracking_updates (booking_id, lat, lng, status_message, created_at)
SELECT b.id, x.lat, x.lng, x.status_message, NOW() - x.age
FROM bookings b
JOIN loads l ON l.id = b.load_id
CROSS JOIN LATERAL (
  VALUES
    (l.pickup_lat, l.pickup_lng, 'Driver assigned and journey prepared', INTERVAL '2 days'),
    ((l.pickup_lat + l.delivery_lat) / 2.0,
     (l.pickup_lng + l.delivery_lng) / 2.0,
     'Shipment is moving towards destination', INTERVAL '1 day')
) AS x(lat, lng, status_message, age);

-- 9) SETTINGS
INSERT INTO settings (key, value) VALUES
  ('platform_name', 'Smart Return Load Platform'),
  ('support_email', 'support@returnload.com'),
  ('default_currency', 'INR'),
  ('demo_mode', 'true')
ON CONFLICT (key) DO NOTHING;

-- 10) OTP TOKENS (DEMO ONLY; do not use real customer OTPs)
INSERT INTO otp_tokens (email, otp, expires_at) VALUES
  ('demo-otp@returnload.com', '123456', NOW() + INTERVAL '10 minutes')
ON CONFLICT (email) DO NOTHING;

-- 11) REFRESH TOKENS (placeholder hashes; these are not usable login tokens)
INSERT INTO refresh_tokens (user_id, token_hash, expires_at, created_at)
SELECT u.id, 'demo-refresh-hash-' || u.email, NOW() + INTERVAL '30 days', NOW()
FROM users u
WHERE u.email IN ('driver@returnload.com', 'shipper@returnload.com')
ON CONFLICT (token_hash) DO NOTHING;

-- 12) RATE LIMITS (demo placeholder entry)
INSERT INTO rate_limits (key, hits, expires_at)
VALUES ('demo-seed-ip:127.0.0.1', 1, NOW() + INTERVAL '1 minute')
ON CONFLICT (key) DO NOTHING;

-- 13) NOTIFICATIONS
INSERT INTO notifications (user_id, type, title, message, load_id, is_read, created_at)
SELECT u.id, v.type, v.title, v.message, l.id, v.is_read, NOW() - INTERVAL '2 hours'
FROM (VALUES
  ('driver@returnload.com',  'booking_update', 'Booking completed', 'Your Delhi to Mumbai delivery has been marked delivered.', 'Delhi', 'Mumbai', 'Electronics', FALSE),
  ('driver2@returnload.com', 'load_match',     'New load opportunity', 'A Chandigarh to Delhi load matches your route.', 'Chandigarh', 'Delhi', 'FMCG', FALSE),
  ('shipper@returnload.com', 'booking_update', 'Driver assigned', 'A driver has accepted your Chandigarh to Delhi load.', 'Chandigarh', 'Delhi', 'FMCG', TRUE),
  ('shipper2@returnload.com','tracking_update','Shipment update', 'Your Mumbai to Pune shipment has a new tracking update.', 'Mumbai', 'Pune', 'Pharmaceuticals', FALSE)
) AS v(email, type, title, message, pickup_city, delivery_city, cargo_type, is_read)
JOIN users u ON u.email = v.email
JOIN loads l ON l.user_id = CASE
  WHEN v.email LIKE 'shipper%' THEN u.id
  ELSE (SELECT id FROM users WHERE email =
    CASE WHEN v.email = 'driver@returnload.com' THEN 'shipper@returnload.com'
         WHEN v.email = 'driver2@returnload.com' THEN 'shipper@returnload.com'
         ELSE 'shipper2@returnload.com' END)
  END
  AND l.pickup_city = v.pickup_city
  AND l.delivery_city = v.delivery_city
  AND l.cargo_type = v.cargo_type;

-- 14) VERIFICATION HISTORY
INSERT INTO verification_history (driver_id, action, note, created_at)
SELECT u.id, v.action, v.note, NOW() - INTERVAL '2 days'
FROM (VALUES
  ('driver3@returnload.com', 'rejected', 'RC image was blurred; please upload a clearer copy.'),
  ('driver3@returnload.com', 'resubmitted', 'Updated RC document submitted for review.'),
  ('driver4@returnload.com', 'rejected', 'Document details did not match the registration information.')
) AS v(email, action, note)
JOIN users u ON u.email = v.email;

COMMIT;

-- Quick verification after the script completes:
-- SELECT role, COUNT(*) FROM users GROUP BY role ORDER BY role;
-- SELECT status, COUNT(*) FROM loads GROUP BY status ORDER BY status;
-- SELECT status, COUNT(*) FROM bookings GROUP BY status ORDER BY status;
-- SELECT 'users' AS table_name, COUNT(*) FROM users
-- UNION ALL SELECT 'trucks', COUNT(*) FROM trucks
-- UNION ALL SELECT 'loads', COUNT(*) FROM loads
-- UNION ALL SELECT 'bookings', COUNT(*) FROM bookings;
