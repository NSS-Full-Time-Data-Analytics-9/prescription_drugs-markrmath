-- 1a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT npi, SUM(total_claim_count) as claims_total
FROM prescription
GROUP BY npi
ORDER BY claims_total DESC
LIMIT 1;

--    1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT npi, pvdr.nppes_provider_first_name, pvdr.nppes_provider_last_org_name, pvdr.specialty_description, SUM(prescrp.total_claim_count) AS total_claims
FROM prescriber AS pvdr
INNER JOIN prescription AS prescrp
	USING(npi)
GROUP BY npi, pvdr.nppes_provider_first_name, pvdr.nppes_provider_last_org_name, pvdr.specialty_description 
ORDER BY total_claims DESC
LIMIT 1;

--     2a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT pvdr.specialty_description, SUM(prescrp.total_claim_count) AS total_claims
FROM prescriber AS pvdr
INNER JOIN prescription AS prescrp
	USING(npi)
GROUP BY pvdr.specialty_description
ORDER BY total_claims DESC;

--     2b. Which specialty had the most total number of claims for opioids?

SELECT pvdr.specialty_description, SUM(total_claim_count)
FROM prescriber AS pvdr
INNER JOIN prescription AS prescrp
	USING(npi)
INNER JOIN drug
	USING(drug_name)
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY pvdr.specialty_description
ORDER BY SUM(total_claim_count) DESC;

--     2c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT pvdr.specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber AS pvdr
LEFT JOIN prescription AS prescrp
	USING(npi)
GROUP BY pvdr.specialty_description
HAVING SUM(total_claim_count) IS NULL;

--     2d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

SELECT prvdr.specialty_description,
	SUM(CASE WHEN prscrpt.drug_name IN (SELECT drug_name
										FROM drug
										WHERE opioid_drug_flag = 'Y') --summing the opioids 
	THEN prscrpt.total_claim_count END) AS opioid_prescriptions,
	SUM(prscrpt.total_claim_count) AS total_specialty_claims, --summing the total claims per specialty
	ROUND((SUM(CASE WHEN prscrpt.drug_name IN (SELECT drug_name
											   FROM drug
											   WHERE opioid_drug_flag = 'Y') --mashing the last 2 together and getting the %
	THEN prscrpt.total_claim_count END) / SUM(prscrpt.total_claim_count)) * 100,2) AS opioid_prescription_percentage
FROM prescription AS prscrpt
INNER JOIN prescriber AS prvdr
	USING (npi)
GROUP BY prvdr.specialty_description
ORDER BY opioid_prescription_percentage DESC NULLS LAST;

--     3a. Which drug (generic_name) had the highest total drug cost?

SELECT drug.generic_name, SUM(prescrp.total_drug_cost) AS tdc
FROM drug
INNER JOIN prescription AS prescrp
	ON drug.drug_name = prescrp.drug_name
GROUP BY drug.generic_name
ORDER BY tdc DESC
LIMIT 1;

--     3b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT drug.generic_name,
	ROUND(SUM(prescrp.total_drug_cost) / SUM(prescrp.total_day_supply), 2) AS total_cost_per_day
FROM drug
INNER JOIN prescription AS prescrp
	USING(drug_name)
GROUP BY drug.generic_name
ORDER BY total_cost_per_day DESC
LIMIT 1;
 
--     4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT generic_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'Opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'Antibiotic'
		ELSE 'Neither' END AS drug_type
FROM drug
ORDER BY drug_type;

--     4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT CASE WHEN opioid_drug_flag = 'Y' THEN 'Opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'Antibiotic'
		ELSE 'Neither' END AS drug_type, SUM(total_drug_cost) AS total_cost
FROM prescription AS prescrp
INNER JOIN drug
	USING(drug_name)
GROUP BY drug_type
ORDER BY total_cost DESC;

--     5a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(DISTINCT cbsaname)
FROM cbsa
WHERE cbsaname LIKE '%TN%';

--     5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsaname, SUM(pop.population) AS total_pop
FROM cbsa 
INNER JOIN population AS pop
	USING(fipscounty)
GROUP BY cbsaname
ORDER BY total_pop DESC
LIMIT 1; --largest pop

SELECT cbsaname, SUM(pop.population) AS total_pop
FROM cbsa 
INNER JOIN population AS pop
	USING(fipscounty)
GROUP BY cbsaname
ORDER BY total_pop
LIMIT 1; --small pop

--     5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT fc.county, pop.population
FROM population AS pop
INNER JOIN fips_county AS fc
	USING(fipscounty)
WHERE NOT EXISTS
	(SELECT fipscounty
	FROM cbsa
	WHERE cbsa.fipscounty = pop.fipscounty)
ORDER BY pop.population DESC
LIMIT 1;

--     6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

--     6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug.drug_name, prescrp.total_claim_count,
	CASE WHEN drug.opioid_drug_flag = 'Y' THEN 'Opioid'
		ELSE 'Not an opioid' END
FROM prescription AS prescrp
INNER JOIN drug
	USING(drug_name)
WHERE total_claim_count >= 3000;

--     6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT drug.drug_name, prvdr.nppes_provider_first_name, prvdr.nppes_provider_last_org_name, prescrp.total_claim_count,
	CASE WHEN drug.opioid_drug_flag = 'Y' THEN 'Opioid'
		ELSE 'Not an opioid' END
FROM prescription AS prescrp
INNER JOIN drug
	USING(drug_name)
INNER JOIN prescriber AS prvdr
	USING(npi)
WHERE prescrp.total_claim_count >= 3000
ORDER BY total_claim_count DESC;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT prvdr.npi, drug.drug_name
FROM prescriber AS prvdr
	CROSS JOIN drug
WHERE prvdr.specialty_description = 'Pain Management'
	AND prvdr.nppes_provider_city = 'NASHVILLE'
	AND drug.opioid_drug_flag = 'Y';

--     7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
	
SELECT prvdr.npi, drug.drug_name, prscrpt.total_claim_count
FROM prescriber AS prvdr
	CROSS JOIN drug
	LEFT JOIN prescription AS prscrpt
		ON prvdr.npi = prscrpt.npi
		AND drug.drug_name = prscrpt.drug_name
WHERE prvdr.specialty_description = 'Pain Management'
	AND prvdr.nppes_provider_city = 'NASHVILLE'
	AND drug.opioid_drug_flag = 'Y'
ORDER BY prvdr.npi DESC;
	
--     7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT prvdr.npi, drug.drug_name,
	(CASE WHEN prscrpt.total_claim_count IS NULL THEN 0
		WHEN prscrpt.total_claim_count IS NOT NULL THEN total_claim_count END) AS total_claim_count
FROM prescriber AS prvdr
	CROSS JOIN drug
	LEFT JOIN prescription AS prscrpt
		ON prvdr.npi = prscrpt.npi
		AND drug.drug_name = prscrpt.drug_name
WHERE prvdr.specialty_description = 'Pain Management'
	AND prvdr.nppes_provider_city = 'NASHVILLE'
	AND drug.opioid_drug_flag = 'Y'
ORDER BY prvdr.npi DESC;

-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT COUNT(npi) AS non-prescribing_npis
FROM prescriber
WHERE npi NOT IN
	(SELECT DISTINCT npi
	FROM prescription);

-- 2a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT drug.generic_name, SUM(prescrpt.total_claim_count) AS total_prescribed
FROM prescriber AS prvdr
INNER JOIN prescription AS prescrpt
	USING(npi)
INNER JOIN drug
	USING(drug_name)
WHERE prvdr.specialty_description = 'Family Practice'
GROUP BY drug.generic_name
ORDER BY total_prescribed DESC;

-- 2b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT drug.generic_name, SUM(prescrpt.total_claim_count) AS total_prescribed
FROM prescriber AS prvdr
INNER JOIN prescription AS prescrpt
	USING(npi)
INNER JOIN drug
	USING(drug_name)
WHERE prvdr.specialty_description = 'Cardiology'
GROUP BY drug.generic_name
ORDER BY total_prescribed DESC;

--  2c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

SELECT generic_name
FROM drug
WHERE generic_name IN (SELECT drug.generic_name
						FROM prescriber AS prvdr
						INNER JOIN prescription AS prescrpt
							USING(npi)
						INNER JOIN drug
							USING(drug_name)
						WHERE prvdr.specialty_description = 'Family Practice'
						GROUP BY drug.generic_name
						ORDER BY SUM(total_claim_count) DESC
					  LIMIT 5)
					AND generic_name IN (SELECT drug.generic_name
						FROM prescriber AS prvdr
						INNER JOIN prescription AS prescrpt
							USING(npi)
						INNER JOIN drug
							USING(drug_name)
						WHERE prvdr.specialty_description = 'Cardiology'
						GROUP BY drug.generic_name
						ORDER BY SUM(total_claim_count) DESC
					  LIMIT 5);


-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.

SELECT npi, SUM(total_claim_count) AS total_claims, 'NASHVILLE' AS city
FROM prescriber AS prvdr
	INNER JOIN prescription AS prscrpt
		USING (npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi
ORDER BY total_claims DESC
LIMIT 5;

--     b. Now, report the same for Memphis.

SELECT npi, SUM(total_claim_count) AS total_claims, 'MEMPHIS' AS city
FROM prescriber AS prvdr
	INNER JOIN prescription AS prscrpt
		USING (npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi
ORDER BY total_claims DESC
LIMIT 5;
    
--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

SELECT npi, nppes_provider_city, SUM(total_claim_count) AS total_claims
FROM prescriber AS prvdr
	INNER JOIN prescription AS prscrpt
		USING (npi)
WHERE npi IN (SELECT npi
			 FROM prescriber AS prvdr
			 	INNER JOIN prescription AS prscrpt
			 		USING(npi)
			 WHERE nppes_provider_city = 'NASHVILLE'
			 GROUP BY npi
			 ORDER BY SUM(total_claim_count) DESC
			 LIMIT 5)
			OR npi IN (SELECT npi
					 FROM prescriber AS prvdr
						INNER JOIN prescription AS prscrpt
							USING(npi)
					 WHERE nppes_provider_city = 'MEMPHIS'
					 GROUP BY npi
					 ORDER BY SUM(total_claim_count) DESC
					 LIMIT 5)
			OR npi IN (SELECT npi
					 FROM prescriber AS prvdr
						INNER JOIN prescription AS prscrpt
							USING(npi)
					 WHERE nppes_provider_city = 'KNOXVILLE'
					 GROUP BY npi
					 ORDER BY SUM(total_claim_count) DESC
					 LIMIT 5)
			OR npi IN (SELECT npi
					 FROM prescriber AS prvdr
						INNER JOIN prescription AS prscrpt
							USING(npi)
					 WHERE nppes_provider_city = 'CHATTANOOGA'
					 GROUP BY npi
					 ORDER BY SUM(total_claim_count) DESC
					 LIMIT 5)
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC;

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.
SELECT fipscounty, SUM(deaths)
FROM overdoses
GROUP BY fipscounty
HAVING SUM(deaths) > (SELECT AVG(deaths)
					FROM overdoses);

-- 5.
--     a. Write a query that finds the total population of Tennessee.

SELECT SUM(population) AS total_tn_pop
FROM population AS pop
INNER JOIN fips_county
	USING (fipscounty)
WHERE fips_county.state = 'TN';
    
--     b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.

WITH tn_total AS (SELECT SUM(population) AS total_tn_pop
				  FROM population AS pop
				  	INNER JOIN fips_county
						USING (fipscounty)
					WHERE fips_county.state = 'TN')
SELECT fips_county.county,
		pop.population,
		ROUND((pop.population/tn_total.total_tn_pop)*100,2) AS percent_of_tn_pop
FROM tn_total, population AS pop
	INNER JOIN fips_county
		USING(fipscounty)
ORDER BY percent_of_tn_pop DESC;