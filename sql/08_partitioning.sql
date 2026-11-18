-- ============================================================================
-- Checkpoint 4 (CP4): Table Partitioning Implementation for Housing.com
-- Database Architecture & Scalability Phase
-- Target Table: housing.properties
-- ============================================================================

SET search_path TO housing;

-- ----------------------------------------------------------------------------
-- 1. Partitioning Strategy & Architectural Rationale
-- ----------------------------------------------------------------------------
-- The properties table is the central fact table of Housing.com:
--   - Seed dataset: 120,060 listings (~25 MB table + 21 MB indexes)
--   - Large dataset: ~2,401,000 listings (~500 MB table + 420 MB indexes)
--   - 100x Scale: ~12,000,000 listings (~2.5 GB table + 2.1 GB indexes)
--
-- Why Partition by LIST (listing_type)?
-- 1. Domain Separation: 95%+ of user workflows strictly bifurcate into Renters
--    and Buyers. Rent queries (R01, R05) never scan sale listings; Buy queries
--    (R02, R04) never scan rental listings.
-- 2. Attribute Specificity: Rental listings carry rental-specific attributes
--    (security_deposit, furnishing, maintenance_monthly), while sale listings
--    focus on capital investment metrics (carpet area, price per sqft, builder).
-- 3. Partition Pruning Efficiency: With LIST (listing_type), PostgreSQL's planner
--    prunes exactly 50% of the table data upfront for R01, R02, R05, R17, R18,
--    cutting index depth and scan ranges in half.
--
-- Note on PostgreSQL Partitioning Constraint Rules:
-- In PostgreSQL declarative partitioning, any UNIQUE or PRIMARY KEY constraint
-- on a partitioned table MUST contain all columns of the partition key.
-- Therefore, the new composite primary key is: PRIMARY KEY (property_id, listing_type).
-- ----------------------------------------------------------------------------

-- Step 1: Create the new partitioned parent table
DROP TABLE IF EXISTS properties_partitioned CASCADE;

CREATE TABLE properties_partitioned (
    property_id INT NOT NULL,
    listed_by INT NOT NULL,
    project_id INT,
    locality_id INT NOT NULL,
    listing_type VARCHAR(20) NOT NULL,
    property_type VARCHAR(40) NOT NULL,
    bhk INT,
    carpet_area_sqft INT NOT NULL,
    floor_no INT,
    total_floors INT,
    furnishing VARCHAR(30),
    facing VARCHAR(20),
    price DECIMAL(14,2) NOT NULL,
    maintenance_monthly DECIMAL(12,2),
    security_deposit DECIMAL(14,2),
    available_from DATE,
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    is_verified BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    posted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Partition Key Constraint: must include listing_type
    CONSTRAINT pk_properties_partitioned PRIMARY KEY (property_id, listing_type),
    CONSTRAINT fk_prop_part_user FOREIGN KEY (listed_by) REFERENCES users(user_id),
    CONSTRAINT fk_prop_part_project FOREIGN KEY (project_id) REFERENCES projects(project_id),
    CONSTRAINT fk_prop_part_locality FOREIGN KEY (locality_id) REFERENCES localities(locality_id),
    CONSTRAINT chk_listing_type CHECK (listing_type IN ('RENT', 'SALE')),
    CONSTRAINT chk_status CHECK (status IN ('ACTIVE', 'RENTED', 'SOLD', 'UNDER_OFFER', 'INACTIVE'))
) PARTITION BY LIST (listing_type);

-- Step 2: Create individual child partitions
CREATE TABLE properties_rent PARTITION OF properties_partitioned
    FOR VALUES IN ('RENT');

CREATE TABLE properties_sale PARTITION OF properties_partitioned
    FOR VALUES IN ('SALE');

-- ----------------------------------------------------------------------------
-- 2. Local Indexes on Partitions
-- ----------------------------------------------------------------------------
-- In PostgreSQL declarative partitioning, indexes defined on the parent
-- automatically cascade to child partitions, creating partition-local indexes.

-- Filtered searches on status + locality (R01, R02)
CREATE INDEX idx_prop_part_status_loc ON properties_partitioned (status, locality_id);

-- Locality index for joins (R04, R15)
CREATE INDEX idx_prop_part_locality ON properties_partitioned (locality_id);

-- User/Agent dashboard filters (R06, W02, W05)
CREATE INDEX idx_prop_part_listed_by ON properties_partitioned (listed_by);

-- Project lookups (R09, R11)
CREATE INDEX idx_prop_part_project ON properties_partitioned (project_id);

-- Time-based queries and batch jobs (W04, R17)
CREATE INDEX idx_prop_part_status_posted ON properties_partitioned (status, posted_at);

-- Date pagination (R22)
CREATE INDEX idx_prop_part_posted_desc ON properties_partitioned (posted_at DESC);

-- Specialized Partial Index on the Rent partition: Map View (R05)
-- Only rental properties are queried on map coordinates in R05
CREATE INDEX idx_prop_rent_lat_lng ON properties_rent (latitude, longitude)
    WHERE status = 'ACTIVE';

-- ----------------------------------------------------------------------------
-- 3. Data Migration Script (From Unpartitioned to Partitioned Table)
-- ----------------------------------------------------------------------------
-- Insert all existing rows into the partitioned structure:
INSERT INTO properties_partitioned (
    property_id, listed_by, project_id, locality_id, listing_type,
    property_type, bhk, carpet_area_sqft, floor_no, total_floors,
    furnishing, facing, price, maintenance_monthly, security_deposit,
    available_from, latitude, longitude, is_verified, status, posted_at
)
SELECT 
    property_id, listed_by, project_id, locality_id, listing_type,
    property_type, bhk, carpet_area_sqft, floor_no, total_floors,
    furnishing, facing, price, maintenance_monthly, security_deposit,
    available_from, latitude, longitude, is_verified, status, posted_at
FROM properties;

ANALYZE properties_partitioned;

-- ----------------------------------------------------------------------------
-- 4. Demonstration of Partition Pruning
-- ----------------------------------------------------------------------------

-- Example A: Rent Query (Prunes 'properties_sale' completely)
-- Only properties_rent will appear in the execution plan!
EXPLAIN (ANALYZE, BUFFERS)
SELECT property_id, price, bhk, furnishing
FROM properties_partitioned
WHERE listing_type = 'RENT'
  AND status = 'ACTIVE'
  AND locality_id = 70
  AND price <= 40000;

-- Example B: Sale Query (Prunes 'properties_rent' completely)
-- Only properties_sale will appear in the execution plan!
EXPLAIN (ANALYZE, BUFFERS)
SELECT property_id, price, bhk, carpet_area_sqft
FROM properties_partitioned
WHERE listing_type = 'SALE'
  AND status = 'ACTIVE'
  AND price <= 12000000;

-- ----------------------------------------------------------------------------
-- 5. Range Partitioning Extension (Time-Series Lifecycle: posted_at)
-- ----------------------------------------------------------------------------
-- For long-term historical retention and fast W04 deactivations, properties can
-- alternatively be partitioned by RANGE (posted_at):
--
-- CREATE TABLE properties_by_year (
--     property_id INT NOT NULL,
--     posted_at TIMESTAMP NOT NULL,
--     ...
--     PRIMARY KEY (property_id, posted_at)
-- ) PARTITION BY RANGE (posted_at);
--
-- CREATE TABLE properties_y2025 PARTITION OF properties_by_year
--     FOR VALUES FROM ('2025-01-01 00:00:00') TO ('2026-01-01 00:00:00');
-- CREATE TABLE properties_y2026 PARTITION OF properties_by_year
--     FOR VALUES FROM ('2026-01-01 00:00:00') TO ('2027-01-01 00:00:00');
-- CREATE TABLE properties_y2027 PARTITION OF properties_by_year
--     FOR VALUES FROM ('2027-01-01 00:00:00') TO ('2028-01-01 00:00:00');
--
-- Benefit: Dropping or archiving listings older than 2 years becomes a metadata-only
-- instant operation: ALTER TABLE properties_by_year DETACH PARTITION properties_y2025;
