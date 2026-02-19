CREATE TABLE technical_support
(
	status VARCHAR(15),
	ticket_id INT PRIMARY KEY,
	priority VARCHAR(10),
	"source" VARCHAR(10),
	topic VARCHAR(50),
	agent_group VARCHAR(20),
	agent_name VARCHAR(50),
	created_time TIMESTAMP,
	expected_SLA_to_resolve TIMESTAMP, 
	expected_SLA_to_first_response TIMESTAMP,
	first_response_time TIMESTAMP,     
	SLA_for_first_response VARCHAR(15),
	resolution_time TIMESTAMP,
	SLA_for_resolution VARCHAR(15),
	close_time TIMESTAMP,
	agent_interaction INT,
	survey_results INT,               
	product_group TEXT,
	support_level VARCHAR(15),
	country VARCHAR(50),
	latitude DECIMAL(9,6),    
	longitude DECIMAL(9,6)       
);
SELECT * FROM technical_support;