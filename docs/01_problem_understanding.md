# Problem Understanding — Housing.com Database Optimization

## 1. Business Context

Housing.com is a real-estate platform that connects home seekers with property owners, agents, and builders. Users can search for properties to rent or buy, explore projects, compare prices and amenities, contact owners or agents, and schedule site visits.

The existing database was developed without proper schema documentation or constraints. As the platform grows, several teams are experiencing performance issues across property discovery, listing management, engagement workflows, analytics, and platform operations.

The primary objective is to reconstruct a reliable database schema and optimize query performance while preserving existing query results and supporting an expected **20× increase in listings**.

## 2. Problem Understanding and Stakeholders

| Problem | Business Need | Affected Stakeholders | Classification |
|---|---|---|---|
| **P1 — Search Performance** | Enable home seekers to quickly search rental and sale properties using filters such as price, locality, BHK, carpet area, amenities, price per sq. ft., and map location. | Home seekers (tenants and buyers) | Customer-facing / Real-time |
| **P2 — Property & Project Pages** | Load property details, project information, builder details, and RERA registration information quickly and reliably. | Home seekers, builders, investors | Customer-facing / Real-time |
| **P3 — Owner & Agent Operations** | Provide responsive dashboards for managing listings, tracking enquiries, scheduling site visits, monitoring price changes, and updating listing statuses. | Owners, agents | Customer-facing / Real-time |
| **P4 — Alerts & Follow-ups** | Identify price drops, enquiries without scheduled visits, and stale listings through hourly background processing so that users receive timely alerts and teams can follow up. | Home seekers, owners, agents, growth | Customer-facing / Real-time |
| **P5 — Projects Without Listings** | Correctly identify builders' projects that currently have no associated property listings, enabling partnership teams to identify opportunities and onboard more inventory. | Builders, growth | Reporting / Analytics |
| **P6 — Business Insights** | Generate reliable insights into property price trends, rental yields, agent performance, site-visit ratings, and the enquiry-to-visit conversion funnel. | Investors, agents, growth | Reporting / Analytics |
| **P7 — Trust, Safety & Scalability** | Support efficient trust and safety checks, platform-wide reporting, and operational queries while accommodating a projected 20× growth in listings. | Trust & safety, growth, platform operations | Reporting / Analytics |

## 3. Performance Classification

The problems are divided into two categories because they have different performance expectations.

### A. Customer-facing / Real-time

These operations directly affect the user experience and should return results with minimal latency.

- P1: Property search and filtering.
- P2: Property, project, and RERA information retrieval.
- P3: Owner and agent dashboards and operational workflows.
- P4: Hourly alert generation and follow-up workflows.

**Performance priority:** Low query latency, efficient indexing, predictable response times, and reliable concurrent access.

### B. Reporting / Analytics

These operations primarily support business decisions, monitoring, and strategic planning rather than immediate user interactions.

- P5: Projects without property listings.
- P6: Price trends, rental yield, agent leaderboard, visit ratings, and conversion funnel.
- P7: Trust and safety reports and platform-wide reporting.

**Performance priority:** Efficient aggregation, scalable data access, optimized joins, and acceptable execution times for larger datasets.

## 4. Assumptions

1. **Existing data:** The surviving data exports represent the current production database and will be treated as the source of truth during schema reconstruction.
2. **Property types:** Properties can either belong to a registered project or exist independently, such as standalone houses, villas, and plots.
3. **Listing purpose:** A property may be listed for sale or rent, and its listing status can change over time.
4. **Project and builder relationship:** A builder can develop multiple projects, while each project belongs to a builder.
5. **RERA registration:** Projects may have RERA registration details, which need to be stored and queried efficiently.
6. **Enquiries and visits:** Enquiries and site visits are separate records associated with properties and home seekers.
7. **Price history:** Property price changes must be preserved so that historical trends and price-drop alerts can be generated.
8. **Amenities:** Amenities may be associated with projects and potentially individual properties.
9. **Hourly workflows:** Alert and follow-up jobs are expected to execute approximately once every hour.
10. **Growth:** The database must accommodate a 20× increase in listings without significant degradation in critical query performance.
11. **Result consistency:** Query optimization must not change the existing business logic, filtering conditions, or expected results.

## 5. Overall Objective

The goal is not simply to add indexes to the existing database. It is to understand the business requirements, reconstruct a correct and well-constrained relational schema from the available exports, establish performance baselines for the 30 most important queries, and optimize database operations without changing their results.

The final database design should provide fast property discovery, reliable listing management, accurate business insights, and sufficient scalability to support Housing.com's future growth.