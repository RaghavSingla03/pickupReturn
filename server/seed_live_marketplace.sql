-- Smart Return Load Platform: add realistic, current-looking marketplace data
-- Run AFTER the main seed.sql, against the development database only.
-- Adds open load postings and a few already-active bookings.
-- Safe to re-run: duplicate loads/bookings are skipped using their identifying fields.

BEGIN;

-- Confirm the main seed accounts exist before adding marketplace rows.
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM users WHERE email IN (
    'shipper@returnload.com', 'shipper2@returnload.com', 'shipper3@returnload.com',
    'driver@returnload.com', 'driver2@returnload.com', 'driver3@returnload.com',
    'driver4@returnload.com', 'driver5@returnload.com', 'driver6@returnload.com'
  )) <> 9 THEN
    RAISE EXCEPTION 'Expected demo shipper/driver accounts are missing. Run the main seed.sql first.';
  END IF;
END $$;

-- Make the demo shipper and driver accounts available to the application.
UPDATE users
SET is_active = 1
WHERE email IN (
  'shipper@returnload.com', 'shipper2@returnload.com', 'shipper3@returnload.com',
  'driver@returnload.com', 'driver2@returnload.com', 'driver3@returnload.com',
  'driver4@returnload.com', 'driver5@returnload.com', 'driver6@returnload.com'
);

-- OPEN LOADS: these are the postings that should appear in a driver's Browse Loads screen.
-- created_at and timelines are relative to NOW(), so records look recent whenever seeded.
INSERT INTO loads
  (user_id, pickup_lat, pickup_lng, delivery_lat, delivery_lng,
   pickup_city, delivery_city, cargo_type, weight_tons, description,
   handling_instructions, offered_price, timeline, status, created_at)
SELECT u.id, v.pickup_lat, v.pickup_lng, v.delivery_lat, v.delivery_lng,
       v.pickup_city, v.delivery_city, v.cargo_type, v.weight_tons,
       v.description, v.handling_instructions, v.offered_price,
       v.timeline, 'open', NOW() - v.age
FROM (VALUES
  ('shipper@returnload.com',  28.6139, 77.2090, 19.0760, 72.8777, 'Delhi',      'Mumbai',       'Electronics',       8.0,  'Consumer electronics cartons for retail distribution',       'Keep dry; stack cartons carefully.',                  43500.0, 'Pickup within 24 hours',       INTERVAL '18 minutes'),
  ('shipper@returnload.com',  30.7333, 76.7794, 26.9124, 75.7873, 'Chandigarh', 'Jaipur',       'FMCG',              7.0,  'Packaged FMCG stock for distributor warehouse',             'Covered vehicle preferred.',                           24800.0, 'Pickup tomorrow morning',      INTERVAL '42 minutes'),
  ('shipper@returnload.com',  28.4595, 77.0266, 27.1767, 78.0081, 'Gurugram',   'Agra',         'Auto parts',        4.0,  'Automobile spare parts in sealed boxes',                   'Avoid water exposure; handle boxes with care.',        11200.0, 'Pickup within 2 days',         INTERVAL '1 hour'),
  ('shipper@returnload.com',  28.6139, 77.2090, 30.9010, 75.8573, 'Delhi',      'Ludhiana',     'Packaging material',10.0, 'Packaging rolls and corrugated sheets',                    'Keep load covered and secured.',                       19500.0, 'Pickup today',                 INTERVAL '2 hours'),
  ('shipper2@returnload.com', 26.9124, 75.7873, 23.0225, 72.5714, 'Jaipur',     'Ahmedabad',    'Textiles',          9.0,  'Cotton fabric rolls for garment manufacturer',            'Protect from rain and dust.',                          22600.0, 'Pickup within 3 days',          INTERVAL '25 minutes'),
  ('shipper2@returnload.com', 19.0760, 72.8777, 18.5204, 73.8567, 'Mumbai',     'Pune',         'Pharmaceuticals',   4.0,  'Sealed non-hazardous pharmaceutical cartons',             'Clean, dry vehicle; no direct sunlight.',             12800.0, 'Pickup tomorrow',              INTERVAL '55 minutes'),
  ('shipper2@returnload.com', 18.5204, 73.8567, 19.9975, 73.7898, 'Pune',       'Nashik',       'Machinery',         6.0,  'Small industrial machines secured on pallets',            'Use straps; avoid sudden movement.',                  14500.0, 'Pickup within 48 hours',        INTERVAL '90 minutes'),
  ('shipper2@returnload.com', 23.0225, 72.5714, 21.1702, 72.8311, 'Ahmedabad',  'Surat',        'Consumer appliances',5.0, 'Home appliances in manufacturer packaging',               'Keep upright; fragile labels on cartons.',           10500.0, 'Pickup today evening',         INTERVAL '3 hours'),
  ('shipper3@returnload.com', 12.9716, 77.5946, 17.3850, 78.4867, 'Bengaluru',  'Hyderabad',    'Industrial parts', 14.0, 'Machine components packed on pallets',                    'Use load straps and keep packing intact.',           26800.0, 'Pickup within 24 hours',        INTERVAL '12 minutes'),
  ('shipper3@returnload.com', 26.8467, 80.9462, 25.3176, 82.9739, 'Lucknow',    'Varanasi',     'Agricultural goods',7.0, 'Bagged packaged grain for wholesale market',              'Keep bags covered and ventilated.',                   14800.0, 'Pickup this week',              INTERVAL '35 minutes'),
  ('shipper3@returnload.com', 13.0827, 80.2707, 12.9716, 77.5946, 'Chennai',    'Bengaluru',    'Packaged food',    8.0, 'Shelf-stable packaged food products',                     'Keep shipment clean and dry.',                        18400.0, 'Pickup within 2 days',          INTERVAL '75 minutes'),
  ('shipper3@returnload.com', 22.5726, 88.3639, 20.2961, 85.8245, 'Kolkata',    'Bhubaneswar',  'Consumer goods',   6.5, 'Retail cartons for regional distribution',                'Secure cartons to prevent shifting.',                 15800.0, 'Pickup tomorrow',              INTERVAL '2 hours')
) AS v(email, pickup_lat, pickup_lng, delivery_lat, delivery_lng,
       pickup_city, delivery_city, cargo_type, weight_tons, description,
       handling_instructions, offered_price, timeline, age)
JOIN users u ON u.email = v.email AND u.role = 'shipper' AND u.is_active = 1
WHERE NOT EXISTS (
  SELECT 1 FROM loads existing
  WHERE existing.user_id = u.id
    AND existing.pickup_city = v.pickup_city
    AND existing.delivery_city = v.delivery_city
    AND existing.cargo_type = v.cargo_type
    AND existing.description = v.description
);

-- ALREADY-BOOKED WORK: these should appear under a driver's My Bookings / Active Jobs view,
-- not in the unbooked Browse Loads list.
INSERT INTO loads
  (user_id, pickup_lat, pickup_lng, delivery_lat, delivery_lng,
   pickup_city, delivery_city, cargo_type, weight_tons, description,
   handling_instructions, offered_price, timeline, status, created_at)
SELECT u.id, v.pickup_lat, v.pickup_lng, v.delivery_lat, v.delivery_lng,
       v.pickup_city, v.delivery_city, v.cargo_type, v.weight_tons,
       v.description, v.handling_instructions, v.offered_price,
       v.timeline, v.load_status, NOW() - INTERVAL '1 day'
FROM (VALUES
  ('shipper@returnload.com',  28.6139, 77.2090, 26.9124, 75.7873, 'Delhi',     'Jaipur',    'Retail fixtures',  9.0,  'Retail display racks and store fixtures', 'Secure metal frames; protect painted surfaces.', 21500.0, 'Pickup completed; delivery in progress', 'booked'),
  ('shipper2@returnload.com', 19.0760, 72.8777, 18.5204, 73.8567, 'Mumbai',    'Pune',      'Dairy products',   5.0,  'Chilled dairy products in insulated crates', 'Refrigerated vehicle required; maintain cold chain.', 16500.0, 'Picked up; delivery scheduled today', 'in_transit'),
  ('shipper3@returnload.com', 12.9716, 77.5946, 17.3850, 78.4867, 'Bengaluru', 'Hyderabad', 'Electrical goods', 11.0, 'Electrical equipment packed on pallets', 'Keep dry; secure pallets before departure.', 23900.0, 'Driver confirmed; pickup pending', 'booked')
) AS v(email, pickup_lat, pickup_lng, delivery_lat, delivery_lng,
       pickup_city, delivery_city, cargo_type, weight_tons, description,
       handling_instructions, offered_price, timeline, load_status)
JOIN users u ON u.email = v.email AND u.role = 'shipper' AND u.is_active = 1
WHERE NOT EXISTS (
  SELECT 1 FROM loads existing
  WHERE existing.user_id = u.id
    AND existing.pickup_city = v.pickup_city
    AND existing.delivery_city = v.delivery_city
    AND existing.cargo_type = v.cargo_type
    AND existing.description = v.description
);

-- Create active bookings for the three booked/in-transit sample loads.
-- Uses the seeded driver accounts and avoids duplicate booking rows.
INSERT INTO bookings
  (load_id, driver_id, shipper_id, agreed_price, status,
   booked_at, picked_up_at, delivered_at)
SELECT l.id, d.id, s.id, v.agreed_price, v.booking_status,
       NOW() - INTERVAL '20 hours', v.picked_up_at, NULL
FROM (VALUES
  ('shipper@returnload.com',  'Delhi',     'Jaipur',    'Retail fixtures',  'driver@returnload.com',  21000.0, 'confirmed', NULL::timestamptz),
  ('shipper2@returnload.com', 'Mumbai',    'Pune',      'Dairy products',   'driver5@returnload.com', 16000.0, 'in_transit', NOW() - INTERVAL '5 hours'),
  ('shipper3@returnload.com', 'Bengaluru', 'Hyderabad', 'Electrical goods', 'driver6@returnload.com', 23500.0, 'confirmed', NULL::timestamptz)
) AS v(shipper_email, pickup_city, delivery_city, description, driver_email,
       agreed_price, booking_status, picked_up_at)
JOIN users s ON s.email = v.shipper_email AND s.role = 'shipper' AND s.is_active = 1
JOIN users d ON d.email = v.driver_email AND d.role = 'driver' AND d.is_active = 1
JOIN loads l ON l.user_id = s.id
  AND l.pickup_city = v.pickup_city
  AND l.delivery_city = v.delivery_city
  AND l.description LIKE v.description || '%'
WHERE NOT EXISTS (
  SELECT 1 FROM bookings b
  WHERE b.load_id = l.id AND b.driver_id = d.id
);

-- Add a few current tracking points to active bookings.
INSERT INTO tracking_updates (booking_id, lat, lng, status_message, created_at)
SELECT b.id, v.lat, v.lng, v.message, NOW() - v.age
FROM (VALUES
  ('shipper@returnload.com',  'Delhi',     'Jaipur',    'Retail fixtures', 28.6139, 77.2090, 'Driver confirmed; preparing for pickup', INTERVAL '30 minutes'),
  ('shipper2@returnload.com', 'Mumbai',    'Pune',      'Dairy products',  18.9500, 73.0000, 'Vehicle en route to Pune; cold chain active', INTERVAL '20 minutes'),
  ('shipper3@returnload.com', 'Bengaluru', 'Hyderabad', 'Electrical goods',12.9716, 77.5946, 'Driver confirmed; awaiting pickup', INTERVAL '15 minutes')
) AS v(shipper_email, pickup_city, delivery_city, description, lat, lng, message, age)
JOIN users s ON s.email = v.shipper_email
JOIN loads l ON l.user_id = s.id
  AND l.pickup_city = v.pickup_city
  AND l.delivery_city = v.delivery_city
  AND l.description LIKE v.description || '%'
JOIN bookings b ON b.load_id = l.id
WHERE NOT EXISTS (
  SELECT 1 FROM tracking_updates t
  WHERE t.booking_id = b.id AND t.status_message = v.message
);

COMMIT;

-- Useful checks:
-- Active shippers:
-- SELECT id, name, email FROM users WHERE role = 'shipper' AND is_active = 1;
-- Available postings for drivers:
-- SELECT l.id, s.name AS shipper, l.pickup_city, l.delivery_city,
--        l.cargo_type, l.weight_tons, l.offered_price, l.created_at
-- FROM loads l JOIN users s ON s.id = l.user_id
-- WHERE l.status = 'open' AND s.role = 'shipper' AND s.is_active = 1
-- ORDER BY l.created_at DESC;
-- Active bookings:
-- SELECT b.id, d.name AS driver, s.name AS shipper,
--        l.pickup_city, l.delivery_city, b.status
-- FROM bookings b
-- JOIN users d ON d.id = b.driver_id
-- JOIN users s ON s.id = b.shipper_id
-- JOIN loads l ON l.id = b.load_id
-- WHERE b.status IN ('confirmed', 'picked_up', 'in_transit');
