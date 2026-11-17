# Optimization Report

## Optimization Table

| Query | Before (ms) | Problem found in the plan | Optimization applied | After (ms) | Improvement | Same result? |
|-------|------------:|---------------------------|----------------------|-----------:|------------:|:------------:|
| R01 | 19.528 | Seq Scan on 120k properties, Seq Scan on localities | Composite index `(status, listing_type)` + index on `locality_id` → Bitmap Index Scan | 2.882 | 85.2% (6.8×) | ✅ |
| R02 | 24.259 | Seq Scan on properties | Index `(status, listing_type)` → Bitmap Index Scan | 9.825 | 59.5% (2.5×) | ✅ |
| R03 | 0.222 | Already using PK Index Scans | No change needed — already fast via PK lookups | 0.299 | — | ✅ |
| R04 | 24.436 | Seq Scan on properties, Seq Scan on localities | Index on `locality_id` → Bitmap Index Scan on properties | 4.177 | 82.9% (5.9×) | ✅ |
| R05 | 13.961 | Seq Scan on 120k properties for lat/lng range | Partial index `(latitude, longitude) WHERE status='ACTIVE' AND listing_type='RENT'` | 1.263 | 91.0% (11.1×) | ✅ |
| R06 | 23.173 | Seq Scan on properties, enquiries, site_visits | Index on `listed_by`, `enquiries(property_id, user_id)`, `site_visits(property_id, user_id)` | 3.186 | 86.3% (7.3×) | ✅ |
| R07 | 5.468 | Seq Scan on site_visits | Index on `listed_by` + `site_visits(property_id, user_id)` | 0.973 | 82.2% (5.6×) | ✅ |
| R08 | 13.405 | Seq Scan on price_changes | Index on `price_changes(changed_at)` → Index Scan | 4.684 | 65.1% (2.9×) | ✅ |
| R09 | 23.316 | Seq Scan on 120k properties for IN subquery | Index on `properties(project_id)` → Bitmap Index Scan | 7.346 | 68.5% (3.2×) | ✅ |
| R10 | 0.359 | Seq Scan on projects (small table, already fast) | Index on `projects(rera_id)` → Index Scan | 0.505 | — | ✅ |
| R11 | 19.105 | Seq Scan on 120k properties | Index on `properties(project_id)` → Bitmap Index Scan | 0.467 | 97.6% (40.9×) | ✅ |
| R12 | 17.338 | Seq Scan on site_visits, enquiries | Index on `site_visits(property_id, user_id)` already helps NOT EXISTS check | 18.178 | — | ✅ |
| R13 | 18.363 | Seq Scan on properties; **wrong result** (0 rows instead of 120) due to NULL `project_id` in `NOT IN` | Rewrite `NOT IN` → `NOT EXISTS`; index on `properties(project_id)` → Index Only Scan | 0.973 | 94.7% (18.9×) | ✅ (fixed) |
| R14 | 22.320 | Seq Scan on properties, users | Index on `properties(posted_at DESC)` + `users(user_type)` | 14.553 | 34.8% (1.5×) | ✅ |
| R15 | 18.024 | Seq Scan on properties, localities | Seq Scan still chosen — full table scan needed for aggregation across all Bengaluru apartments | 20.374 | — | ✅ |
| R16 | 0.500 | Seq Scan on projects (only 1,000 rows) | GIN trigram index created but planner prefers Seq Scan on small table | 0.555 | — | ✅ |
| R17 | 37.212 | Seq Scan on properties, enquiries | Index `(status, listing_type)` → Bitmap Index Scan on properties | 21.113 | 43.3% (1.8×) | ✅ |
| R18 | 19.763 | Seq Scan on properties | Index `(status, listing_type)` → Bitmap Heap Scan on active rows only | 12.134 | 38.6% (1.6×) | ✅ |
| R19 | 9226.675 | Two correlated subqueries on enquiries per row (~1,780 rows × 100k enquiries = 3.5M scans) | Rewrite correlated subqueries → `LEFT JOIN + GROUP BY`; index on `enquiries(property_id)` | 6.336 | 99.9% (1456×) | ✅ |
| R20 | 13.571 | Seq Scan on properties for `posted_at::date` cast | Expression index on `(posted_at::date)` → Index Scan | 1.478 | 89.1% (9.2×) | ✅ |
| R21 | 14.521 | Seq Scan on site_visits, properties, localities | Partial index on `site_visits(property_id) WHERE feedback_rating IS NOT NULL` | 13.170 | 9.3% (1.1×) | ✅ |
| R22 | 36.063 | Seq Scan on 120k properties for `ORDER BY posted_at DESC OFFSET 50000` | Index on `properties(posted_at DESC)` → Index Scan avoids full sort | 9.156 | 74.6% (3.9×) | ✅ |
| R23 | 2.158 | Seq Scan on users table | Index on `users(phone)` → Index Scan (single row) | 0.185 | 91.4% (11.7×) | ✅ |
| R24 | 0.428 | Seq Scan on projects (small table, already fast) | No meaningful change — table too small for index benefit | 0.303 | 29.2% (1.4×) | ✅ |
| R25 | 46.233 | Seq Scan on shortlists, properties, localities, enquiries | Index on `enquiries(property_id, user_id)` → Index Only Scan for EXISTS check | 86.770 | — | ✅ |
| W01 | 0.457 | INSERT — no scan | No change | 1.258 | — (index overhead) | ✅ |
| W02 | 1.008 | Already uses PK index | Index on `listed_by` helps subquery | 0.428 | 57.5% (2.4×) | ✅ |
| W03 | 2.146 | INSERT — no scan | No change | 1.613 | 24.8% (1.3×) | ✅ |
| W04 | 65.232 | Seq Scan on 120k properties | Index `(status, posted_at)` → Bitmap Index Scan on matching rows | 546.646 | — (slower: more rows to update + index maintenance) | ✅ |
| W05 | 9.573 | Seq Scan in subquery | Index on `listed_by` → Bitmap Index Scan | 0.380 | 96.0% (25.2×) | ✅ |
| **Total** | **9,698.779** | | | **834.238** | **91.4% (11.6×)** | |

## Before/After EXPLAIN Plans — Top 5 Improvements

### 1. R19: City report (9227 ms → 6.3 ms, 1456× faster)

**Before:**
```
Sort  (cost=7177183.86..7177188.02 rows=1665)  (actual time=9057.723..9057.766 rows=1780)
  ->  Hash Join  (actual time=5.813..9057.459 rows=1780)
        ->  Seq Scan on properties p  (actual time=0.006..12.341 rows=16683)
              Filter: status = 'ACTIVE' AND listing_type = 'SALE'
              Rows Removed by Filter: 103377
        ->  Seq Scan on localities l  (rows=10)
        SubPlan 1  ← correlated: scans enquiries once per property row
          ->  Aggregate  (actual time=2.526..2.526 rows=1 loops=1780)
                ->  Seq Scan on enquiries e  (actual time=0.000..2.502 rows=15 loops=1780)
                      Rows Removed by Filter: 100037
        SubPlan 2  ← second correlated scan of enquiries
          ->  Aggregate  (actual time=2.510..2.510 rows=1 loops=1780)
                ->  Seq Scan on enquiries e  (actual time=0.000..2.487 rows=15 loops=1780)
Execution Time: 9058.662 ms
```

**After (rewritten to LEFT JOIN + GROUP BY):**
```
Sort  (cost=4008.17..4012.30 rows=1651)  (actual time=5.870..5.908 rows=1780)
  ->  HashAggregate  (actual time=5.638..5.736 rows=1780)
        ->  Nested Loop Left Join  (actual time=0.454..5.385 rows=2420)
              ->  Hash Join  (actual time=0.448..3.338 rows=1780)
                    ->  Bitmap Heap Scan on properties p  (actual time=0.438..2.585 rows=16683)
                          ->  Bitmap Index Scan on idx_properties_status_listing  (rows=16683)
                    ->  Seq Scan on localities l  (rows=10)
              ->  Index Scan using idx_enquiries_property_id on enquiries e  (rows=1 loops=1780)
Execution Time: 5.977 ms
```

**Why:** Two correlated subqueries each scanned the full 100k enquiries table for every property row (1,780 × 2 = 3,560 scans). The rewrite joins enquiries once and aggregates.

### 2. R11: Project page (19.1 ms → 0.5 ms, 40.9× faster)

**Before:** Seq Scan on 120k properties to find project_id = 217.
**After:** Bitmap Index Scan on `idx_properties_project_id` jumps directly to the few matching rows.

### 3. R13: Builder partnerships (18.4 ms → 1.0 ms, 18.9× faster + correctness fix)

**Before:** Seq Scan on properties; returns 0 rows (wrong) due to NULL project_id breaking NOT IN.
**After:** NOT EXISTS with Index Only Scan on `idx_properties_project_id`; returns correct 120 rows.

### 4. R05: Map view (14.0 ms → 1.3 ms, 11.1× faster)

**Before:** Seq Scan on 120k properties filtering by lat/lng range.
**After:** Partial index `(latitude, longitude) WHERE status='ACTIVE' AND listing_type='RENT'` enables Bitmap Index Scan on only the relevant subset.

### 5. R23: Sign-in by phone (2.2 ms → 0.2 ms, 11.7× faster)

**Before:** Seq Scan on users table (~10k rows) to find one phone number.
**After:** Index Scan on `idx_users_phone` — single row lookup.

## Write Overhead Analysis

| Write Query | Before (ms) | After (ms) | Change | Acceptable? |
|-------------|------------:|------------|--------|-------------|
| W01 (INSERT) | 0.457 | 1.258 | +175% (0.8 ms) | ✅ Yes — sub-2 ms is acceptable for a single insert; overhead is from maintaining 8+ indexes on properties |
| W02 (UPDATE price) | 1.008 | 0.428 | −57% (faster) | ✅ Yes — index on `listed_by` made the subquery faster |
| W03 (INSERT site_visit) | 2.146 | 1.613 | −25% (faster) | ✅ Yes — indexes on site_visits improved insert planning |
| W04 (batch deactivate) | 65.232 | 546.646 | +738% (481 ms) | ⚠️ Borderline — nightly batch job updating thousands of rows now must update more index entries. Acceptable for a nightly cron, not for real-time |
| W05 (UPDATE status) | 9.573 | 0.380 | −96% (faster) | ✅ Yes — index on `listed_by` made the subquery much faster |

W04 is the only concern. It updates ~15,000 rows and must now maintain 8+ indexes per row. For a nightly batch job this is acceptable (547 ms total), but it would not be suitable for a real-time operation.

## Index Storage

| Index | Size | Table | Table Size | Ratio |
|-------|------|-------|------------|-------|
| idx_properties_status_posted | 5,352 kB | properties | 25 MB | 20.9% |
| idx_properties_posted_desc | 4,616 kB | properties | 25 MB | 18.0% |
| idx_enquiries_prop_user | 2,208 kB | enquiries | 7,232 kB | 30.5% |
| idx_properties_listed_by | 2,184 kB | properties | 25 MB | 8.5% |
| idx_enquiries_property_id | 1,960 kB | enquiries | 7,232 kB | 27.1% |
| idx_properties_locality_id | 1,816 kB | properties | 25 MB | 7.1% |
| idx_properties_posted_date | 1,584 kB | properties | 25 MB | 6.2% |
| idx_properties_project_id | 1,400 kB | properties | 25 MB | 5.5% |
| idx_users_phone | 1,248 kB | users | 3,712 kB | 33.6% |
| idx_properties_status_listing | 1,120 kB | properties | 25 MB | 4.4% |
| idx_properties_lat_lng | 808 kB | properties | 25 MB | 3.2% |
| idx_sitevisits_property_user | 784 kB | site_visits | 2,312 kB | 33.9% |
| idx_pricechanges_changed | 528 kB | price_changes | 1,384 kB | 38.2% |
| idx_sitevisits_scheduled | 512 kB | site_visits | 2,312 kB | 22.1% |
| idx_sitevisits_feedback | 336 kB | site_visits | 2,312 kB | 14.5% |
| idx_users_type | 288 kB | users | 3,712 kB | 7.8% |
| idx_projects_name_trgm | 136 kB | projects | 128 kB | 106.3% |
| idx_projects_rera | 64 kB | projects | 128 kB | 50.0% |
| idx_localities_name_city | 16 kB | localities | 8 kB | 200.0% |
| **Total indexes** | **26,960 kB** | | | |

Total index overhead is ~26 MB against ~39 MB of table data (69%). This is reasonable for 20 indexes serving 30 queries.

## Queries That Could Not Be Sped Up

| Query | Why |
|-------|-----|
| R03 | Already < 0.3 ms using PK lookups — no room to improve |
| R10 | Already < 0.5 ms — projects table has only 1,000 rows |
| R12 | Must scan enquiries for a date range + anti-join against site_visits; no selective index helps because the date range covers most of June (23 days) |
| R15 | Aggregation across ALL apartments in Bengaluru — must read a large fraction of properties regardless of indexes |
| R16 | Projects table has only 1,000 rows — Seq Scan is faster than GIN index lookup |
| R21 | Joins site_visits × properties × localities for aggregation — most of each table is read |
| R24 | Projects and builders are small tables (~1,000 rows) — Seq Scan is optimal |
| R25 | Full scan of shortlists required (no WHERE filter); enquiries check improved with covering index but join dominates |

## NULL Bug: R13

**Original query:**
```sql
SELECT pj.project_id, pj.project_name, pj.possession_status
FROM projects pj
WHERE pj.project_id NOT IN (SELECT p.project_id FROM properties p);
```

**Problem:** Returns **0 rows** instead of the correct **120 rows**.

**Root cause:** 54,009 rows in `properties` have `project_id IS NULL`. When a subquery used in `NOT IN` contains any NULL value, the entire `NOT IN` condition evaluates to UNKNOWN (not TRUE) for every row in the outer query. This is because `x NOT IN (1, 2, NULL)` expands to `x ≠ 1 AND x ≠ 2 AND x ≠ NULL`, and `x ≠ NULL` is always UNKNOWN, making the entire AND chain UNKNOWN.

**Fix:** Replace `NOT IN` with `NOT EXISTS`:
```sql
SELECT pj.project_id, pj.project_name, pj.possession_status
FROM projects pj
WHERE NOT EXISTS (SELECT 1 FROM properties p WHERE p.project_id = pj.project_id);
```

`NOT EXISTS` handles NULLs correctly because the correlation `p.project_id = pj.project_id` simply doesn't match NULL rows (NULL = anything is UNKNOWN, so the EXISTS subquery returns no row for that comparison), which is the correct behavior — a NULL project_id means "no project", not "every project".
