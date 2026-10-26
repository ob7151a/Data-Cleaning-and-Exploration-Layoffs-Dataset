# 1. remove duplicates
# 2. Standardize data
# 3. Null values or blank values (can you populate it?)
# 4. Remove any columns/rows that are unecessary

# ----- Create a TABLE where you copy all the raw data into a staging table -----
# CREATE TABLE layoffs_staging
# LIKE layoffs;

# ----- populates the datatable with all the info from layoffs -----
# INSERT layoffs_staging
# SELECT *
# FROM layoffs;

SELECT *
FROM layoffs_staging;
# why do we do this? You change the staging DB a lot, if you make a mistake, you want
# the raw data avaliable

# ------ Removing Duplicates ------
SELECT *,
ROW_NUMBER() OVER(
    PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`, country,
    funds_raised) AS row_num
FROM layoffs_staging;

WITH duplicate_cte AS
(SELECT *,
ROW_NUMBER() OVER(
               PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`, country, funds_raised
               ORDER BY company
           ) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

# this will print out duplicates, you want to get rid of those

SELECT *
FROM layoffs_staging
WHERE company = 'Oda';
# duplicates in Cazoo and Beyond Meat
DROP TABLE IF EXISTS `layoffs_staging2`;

# How to delete duplicates:
CREATE TABLE IF NOT EXISTS `layoffs_staging2` (
  `company` text,
  `location` text,
  `total_laid_off` double DEFAULT NULL,
  `date` text,
  `percentage_laid_off` double DEFAULT NULL,
  `industry` text,
  `source` text,
  `stage` text,
  `funds_raised` double DEFAULT NULL,
  `country` text,
  `date_added` text,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER( 
    PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`,
    stage, country, funds_raised) AS row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

## ---- 2. Standardizing Data (finding issues in your data and fixing it) ----
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company); # trim just removes the whitespace

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

# Changing Crypto to CryptoCurrency
UPDATE layoffs_staging2
SET industry = 'CryptoCurrency'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

# Changing United Arab Emirates to UAE
SELECT industry, company, stage, `date`, total_laid_off, percentage_laid_off, country, funds_raised
FROM layoffs_staging2
WHERE country = 'United Arab Emirates' OR country = 'UAE'
ORDER BY company ASC;

UPDATE layoffs_staging2
SET country = 'UAE'
WHERE country LIKE 'United Arab Emirates';

# NULL
SELECT industry, company, stage, `date`, total_laid_off, percentage_laid_off, country, funds_raised
FROM layoffs_staging2
WHERE Industry IS NULL
OR industry LIKE '';

# lets populate Appsmith -- industry is NULL
SELECT *
FROM layoffs_staging2
WHERE company = "Appsmith"; # after research, the industry for Appsmith will be 'Other'

UPDATE layoffs_staging2
SET industry = "Other"
WHERE company = "Appsmith"; # it worked yay

SELECT*
FROM layoffs_staging2
WHERE company IS NULL
    OR location IS NULL
    OR industry IS NULL
    OR total_laid_off IS NULL
    OR percentage_laid_off IS NULL
    OR `date` IS NULL
    OR stage IS NULL
    OR country IS NULL
    OR funds_raised IS NULL; # total_laid_off, percentage_laid_off, funds_raised have NULL values 

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; # the ones in this are relatively useless

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
OR percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off = ''
AND percentage_laid_off = '';

UPDATE layoffs_staging2
SET `date` =  STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE; # doing exploratory data analysis -- that's why this is here

# Ta-da! Now we have clean data. 



