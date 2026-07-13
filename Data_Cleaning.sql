-- DATA CLEANING
USE World_layoffs;

SELECT * FROM layoffs;

-- 1. REMOVE DUPLICATES
-- 2. STANDARDISE DATA
-- 3. NO VALUES/BLANK VALUES
-- 4. REMOVE UNNECESSARY ROWS AND COLUMNS

-- REMOVING DUPLICATE COLUMNS
CREATE TABLE layoffs_staging LIKE layoffs;

SELECT * FROM layoffs_staging;

INSERT INTO layoffs_staging 
SELECT * FROM layoffs;

SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company,location,industry,total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as Row_num
FROM layoffs_staging;

WITH Duplicate_cte AS
(
	SELECT *, 
    ROW_NUMBER() OVER(
    PARTITION BY company,location,industry,total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as Row_num
    FROM layoffs_staging
)
SELECT * FROM Duplicate_cte
WHERE Row_num>1;

WITH Duplicate_cte AS
(
	SELECT *, 
    ROW_NUMBER() OVER(
    PARTITION BY company,location,industry,total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as Row_num
    FROM layoffs_staging
)
DELETE 
FROM Duplicate_cte
WHERE Row_num>1;

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `Row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * FROM layoffs_staging2;

INSERT INTO layoffs_staging2 
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company,location,industry,total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as Row_num
FROM layoffs_staging;

SELECT * FROM layoffs_staging2 
WHERE Row_num>1;

DELETE FROM layoffs_staging2 
WHERE Row_num>1;

-- STANDARDIZING DATA (FINDING ISSUES IN DATA AND FIXING IT)

SELECT company, trim(company) FROM layoffs_staging2;

-- Removed unnecessary whitespace 
UPDATE layoffs_staging2
SET company = trim(company);

SELECT DISTINCT industry FROM layoffs_staging2 ORDER BY 1;

SELECT * FROM layoffs_staging2 where industry LIKE 'crypto%';

UPDATE layoffs_staging2
SET industry = 'crypto'
where industry LIKE 'crypto%';

SELECT DISTINCT Country
FROM layoffs_staging2;

SELECT DISTINCT Country, TRIM(TRAILING '.' FROM Country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET Country = TRIM(TRAILING '.' FROM Country)
WHERE Country = 'United States';

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%y')
FROM layoffs_staging2;

UPDATE layoffs_staging2 
SET `date` = STR_TO_DATE(`date`, '%m/%d/%y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- REMOVING NULL/BLANK VALUES

SELECT * FROM layoffs_staging2 WHERE total_laid_off IS NULL;

-- Convert whitespace to null
UPDATE layoffs_staging2
SET industry = null
WHERE industry = '';

SELECT T1.industry, T2.industry
FROM layoffs_staging2 T1
JOIN layoffs_staging2 T2
ON T1.company = T2.company
WHERE (T1.industry IS NULL OR T1.industry = '')
AND T2.industry IS NOT NULL;

-- Remove null values
UPDATE layoffs_staging2 T1
JOIN layoffs_staging2 T2
ON T1.company = T2.company
SET T1.industry = T2.industry
WHERE (T1.industry IS NULL OR T1.industry = '')
AND T2.industry IS NOT NULL;

SELECT * FROM layoffs_staging2
WHERE total_laid_off is NULL
AND percentage_laid_off IS NULL;

DELETE FROM layoffs_staging2
WHERE total_laid_off is NULL
AND percentage_laid_off IS NULL;

SELECT * FROM layoffs_staging2;

-- REMOVE COLUMNS

ALTER TABLE layoffs_staging2
DROP COLUMN Row_num;