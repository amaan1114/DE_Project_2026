-- Indexes for Housing.com Property Search Database
-- Each index states which queries it serves and why this type/column order.
SET search_path TO housing;

-- R01, R02, R05, R11, R18: filtered searches on properties by listing_type/status
-- Equality columns first (status, listing_type), then range/sort columns.
CREATE INDEX idx_properties_status_listing ON properties (status, listing_type);

-- R01, R02, R04, R15: joins on properties.locality_id for locality-based searches
CREATE INDEX idx_properties_locality_id ON properties (locality_id);

-- R06, W02, W05: owner/agent dashboard filters by listed_by
CREATE INDEX idx_properties_listed_by ON properties (listed_by);

-- R11, R09: filter by project_id on properties
CREATE INDEX idx_properties_project_id ON properties (project_id);

-- W04, R17: status + posted_at for time-based filters on active listings
CREATE INDEX idx_properties_status_posted ON properties (status, posted_at);

-- R05: map view lat/lng range filter on active rentals
CREATE INDEX idx_properties_lat_lng ON properties (latitude, longitude)
  WHERE status = 'ACTIVE' AND listing_type = 'RENT';

-- R20: date-range filter on posted_at for growth queries
CREATE INDEX idx_properties_posted_date ON properties ((posted_at::date));

-- R22: pagination by posted_at DESC
CREATE INDEX idx_properties_posted_desc ON properties (posted_at DESC);

-- R06, R12, R17, R19, R25: enquiries lookups by property_id
CREATE INDEX idx_enquiries_property_id ON enquiries (property_id);

-- R12: NOT EXISTS check on site_visits by (property_id, user_id)
CREATE INDEX idx_sitevisits_property_user ON site_visits (property_id, user_id);

-- R07: site visits by scheduled date
CREATE INDEX idx_sitevisits_scheduled ON site_visits (scheduled_at);

-- R21: site visits with feedback rating for locality aggregation
CREATE INDEX idx_sitevisits_feedback ON site_visits (property_id)
  WHERE feedback_rating IS NOT NULL;

-- R08: price changes by date range
CREATE INDEX idx_pricechanges_changed ON price_changes (changed_at);

-- R23: sign-in by phone number
CREATE INDEX idx_users_phone ON users (phone);

-- R14: agent leaderboard filter by user_type
CREATE INDEX idx_users_type ON users (user_type);

-- R10: RERA id lookup on projects
CREATE INDEX idx_projects_rera ON projects (rera_id);

-- R16: ILIKE '%greens%' text search on project_name (trigram)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_projects_name_trgm ON projects USING gin (project_name gin_trgm_ops);

-- R01: locality lookup by name and city
CREATE INDEX idx_localities_name_city ON localities (locality_name, city_id);

-- R25: enquiries lookup by (property_id, user_id) for EXISTS check in funnel query
CREATE INDEX idx_enquiries_prop_user ON enquiries (property_id, user_id);

ANALYZE;
