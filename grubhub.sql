 -- Checking All fields
SELECT * FROM arboreal-vision-339901.take_home_v2.virtual_kitchen_grubhub_hours LIMIT 5;

CREATE TEMP FUNCTION jsonObjectKeys(input STRING)
RETURNS ARRAY<String>
LANGUAGE js AS """
  return Object.keys(JSON.parse(input));
""";

-- The semicolon was missing here
WITH keys AS (
  SELECT
    jsonObjectKeys(TO_JSON_STRING(response)) AS keys
  FROM
    `arboreal-vision-339901.take_home_v2.virtual_kitchen_grubhub_hours`
  WHERE response IS NOT NULL
)
SELECT
  DISTINCT k
FROM keys
CROSS JOIN UNNEST(keys.keys) AS k
ORDER BY k;

-- Another semicolon was missing here
WITH schedule_rules AS (
  SELECT 
    JSON_EXTRACT_SCALAR(value, '$.days_of_week[0]') AS day,
    JSON_EXTRACT_SCALAR(value, '$.from') AS open_time,    
    JSON_EXTRACT_SCALAR(value, '$.to') AS close_time
  FROM `arboreal-vision-339901.take_home_v2.virtual_kitchen_grubhub_hours`, 
  UNNEST(JSON_EXTRACT_ARRAY(response, '$.availability_by_catalog.STANDARD_DELIVERY.schedule_rules')) AS value 
)
SELECT 
  day, 
  open_time,
  close_time
FROM schedule_rules;

-- Create temporary function
CREATE TEMP FUNCTION ExtractHours(json STRING)
RETURNS ARRAY<STRING>
LANGUAGE js AS """
  const data = JSON.parse(json);
  if (data.availability_by_catalog && data.availability_by_catalog.STANDARD_DELIVERY && data.availability_by_catalog.STANDARD_DELIVERY.schedule_rules) {
    const hours = data.availability_by_catalog.STANDARD_DELIVERY.schedule_rules;
    return hours.map(rule => {
      return rule.days_of_week[0] + ':' + 
             rule.from + '-' + 
             rule.to;
    });
  } else {
    return [];
  }
""";

SELECT
  response,
  ExtractHours(TO_JSON_STRING(response)) AS hours 
FROM `arboreal-vision-339901.take_home_v2.virtual_kitchen_grubhub_hours`;


-- Nested JSON extract
SELECT 
  vb_name,
  JSON_EXTRACT(response, '$.availability_by_catalog.STANDARD_DELIVERY.schedule_rules') as sch
FROM 
  `arboreal-vision-339901.take_home_v2.virtual_kitchen_grubhub_hours` LIMIT 5;


-- Prefinal Query to extract JSON data.

WITH schedule_rules AS (

  SELECT 
    vb_name,
    JSON_EXTRACT_SCALAR(value, '$.from') AS open_time,    
    JSON_EXTRACT_SCALAR(value, '$.to') AS close_time  
  FROM `arboreal-vision-339901.take_home_v2.virtual_kitchen_grubhub_hours`,
   UNNEST(JSON_QUERY_ARRAY(response, 
     '$.availability_by_catalog.STANDARD_DELIVERY.schedule_rules')) AS value
)

SELECT * 
FROM schedule_rules;

