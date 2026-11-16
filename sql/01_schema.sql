
CREATE TABLE cities (
    city_id INT PRIMARY KEY,
    city_name VARCHAR(100),
    state VARCHAR(100)
);

CREATE TABLE builders (
    builder_id INT PRIMARY KEY,
    builder_name VARCHAR(150),
    founded_year INT
);

CREATE TABLE amenities (
    amenity_id INT PRIMARY KEY,
    amenity_name VARCHAR(100)
);

CREATE TABLE users (
    user_id INT PRIMARY KEY,
    full_name VARCHAR(150),
    phone VARCHAR(20),
    email VARCHAR(150),
    user_type VARCHAR(20),
    agent_rera_id VARCHAR(50),
    created_at TIMESTAMP
);

CREATE TABLE localities (
    locality_id INT PRIMARY KEY,
    city_id INT,
    locality_name VARCHAR(100),
    pincode VARCHAR(10),
    center_lat DECIMAL(10,6),
    center_lng DECIMAL(10,6),
    FOREIGN KEY (city_id) REFERENCES cities(city_id)
);

CREATE TABLE projects (
    project_id INT PRIMARY KEY,
    builder_id INT,
    locality_id INT,
    project_name VARCHAR(150),
    rera_id VARCHAR(50),
    possession_status VARCHAR(30),
    possession_date DATE,
    total_units INT,
    FOREIGN KEY (builder_id) REFERENCES builders(builder_id),
    FOREIGN KEY (locality_id) REFERENCES localities(locality_id)
);

CREATE TABLE project_amenities (
    project_id INT,
    amenity_id INT,
    PRIMARY KEY (project_id, amenity_id),
    FOREIGN KEY (project_id) REFERENCES projects(project_id),
    FOREIGN KEY (amenity_id) REFERENCES amenities(amenity_id)
);

CREATE TABLE properties (
    property_id INT PRIMARY KEY,
    listed_by INT,
    project_id INT,
    locality_id INT,
    listing_type VARCHAR(20),
    property_type VARCHAR(40),
    bhk INT,
    carpet_area_sqft INT,
    floor_no INT,
    total_floors INT,
    furnishing VARCHAR(30),
    facing VARCHAR(20),
    price DECIMAL(14,2),
    maintenance_monthly DECIMAL(12,2),
    security_deposit DECIMAL(14,2),
    available_from DATE,
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    is_verified BOOLEAN,
    status VARCHAR(20),
    posted_at TIMESTAMP,
    FOREIGN KEY (listed_by) REFERENCES users(user_id),
    FOREIGN KEY (project_id) REFERENCES projects(project_id),
    FOREIGN KEY (locality_id) REFERENCES localities(locality_id)
);

CREATE TABLE enquiries (
    enquiry_id INT PRIMARY KEY,
    property_id INT,
    user_id INT,
    channel VARCHAR(20),
    message TEXT,
    created_at TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES properties(property_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE shortlists (
    user_id INT,
    property_id INT,
    added_at TIMESTAMP,
    PRIMARY KEY (user_id, property_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (property_id) REFERENCES properties(property_id)
);

CREATE TABLE site_visits (
    visit_id INT PRIMARY KEY,
    property_id INT,
    user_id INT,
    scheduled_at TIMESTAMP,
    status VARCHAR(20),
    feedback_rating INT,
    FOREIGN KEY (property_id) REFERENCES properties(property_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE price_changes (
    change_id INT PRIMARY KEY,
    property_id INT,
    old_price DECIMAL(14,2),
    new_price DECIMAL(14,2),
    changed_at TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES properties(property_id)
);
