----------------------------------------------------------------------------------		
		           --GUIDED DATA CLEANING PORTFOLIO PROJECT--
SELECT*
FROM HousingData.dbo.NashvilleHousing
----------------------------------------------------------------------------------
--1. Standardize Date Format
SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM HousingData.dbo.NashvilleHousing

--1.1For some reason this method does not work
UPDATE HousingData..NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)
FROM HousingData.dbo.NashvilleHousing

--1.2Alternative method of Standardizing Date Format
ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;
UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

----------------------------------------------------------------------------------

--2. Populate Property Address Data 
SELECT *
FROM HousingData.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID
--2.1: Spot where the PropertyAddress is NULL

SELECT *
FROM HousingData.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID

--2.2 Figure out why the PropertyAddress is NULL
SELECT *
FROM HousingData.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

--2.3: Figure out how to fix the problem
SELECT nh1.ParcelID, nh1.PropertyAddress, nh2.ParcelID, nh2.PropertyAddress, ISNULL(nh1.PropertyAddress, nh2.PropertyAddress)
FROM HousingData.dbo.NashvilleHousing nh1
JOIN HousingData.dbo.NashvilleHousing nh2
	ON nh1.ParcelID = nh2.ParcelID 
	AND nh1.[UniqueID ] <> nh2.[UniqueID ]
WHERE nh1.PropertyAddress IS NULL

--2.4: Update PropertyAddress for NULL values
UPDATE nh1
SET PropertyAddress = ISNULL(nh1.PropertyAddress, nh2.PropertyAddress) --(ISNULL(value1,value2): If value1 is Null, change value1 into value2)
FROM HousingData.dbo.NashvilleHousing nh1
JOIN HousingData.dbo.NashvilleHousing nh2
	ON nh1.ParcelID = nh2.ParcelID 
	AND nh1.[UniqueID ] <> nh2.[UniqueID ]
WHERE nh1.PropertyAddress IS NULL
-----------------------------------------------------------------------------------------

--3. Breaking out Address in Individual Columns (Address, City, State)
SELECT PropertyAddress
FROM HousingData.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
--ORDER BY ParcelID

--3.1: Split the PropertyAddress column into Address and City
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
--SUBSTRING(What column, where to begin(index), where to stop(index))
--CHARINDEX(',', PropertyAddress): Will give the number that indicates the location of ',' in PropertyAddress
-- Add '-1' or '+1' so the Address and City don't include the comma 
FROM HousingData.dbo.NashvilleHousing


--3.2: Create 2 New Columns to embed them into the table
--*NOTE: You cannot split a column and directly add the split stuff into the table, 
---------you HAVE TO create 2 new columns and add them into the table

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);
UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

SELECT *
FROM HousingData.dbo.NashvilleHousing

--3.3: Using PARSENAME to Split OwnerAddress into Address, City, and State
--PARSENAME: looks for comma to split and it begins backward: PARSENAME(column, the backward position of the period '.')
--*NOTE: PARSENAME: looks for period '.'
--Therefore, in this case, we will replace the period '.', with comma ',', to split OwnerAddress columm
SELECT *
FROM HousingData.dbo.NashvilleHousing

SELECT PARSENAME(REPLACE(OwnerAddress,',','.'),3)
,PARSENAME(REPLACE(OwnerAddress,',','.'),2)
,PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM HousingData.dbo.NashvilleHousing

--3.4: Create New Split Columns and add them into the Table

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);
UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(PropertyAddress,',','.'),1)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);
UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(PropertyAddress,',','.'),2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);
UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

--Double Check The Results
SELECT *
FROM HousingData.dbo.NashvilleHousing

---------I made a typo mistake while creating a new column so I had to drop a column
ALTER TABLE NashvilleHousing
DROP COLUMN PropertySplitState;
----------------------------------------------------------------------------------------------------

--4. Using CASE STATEMENT to change Y and N to Yes and No in SoldAsVacant Column 
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM HousingData.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM HousingData.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
---------------------------------------------------------------------------------

--5. Remove Duplicates by using ROW_NUMBER
----ROW_NUMBER(): assigns unique number to each row to which is applied. Use this with PARTITION BY to select
---------------- the criteria that qualifies that row as a duplicate (eg: the number assigned of that row != 1)

----Create a CTE (kinda like a TEMP TABLE) so it's easier to check the duplicates found
WITH Row_Num_CTE AS(
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
			PropertyAddress, 
			SaleDate, 
			SalePrice, 
			LegalReference
			ORDER BY UniqueID
			) row_num
FROM HousingData.dbo.NashvilleHousing
)

--5.1: Copy this and put below the CTE above and run both this and the CTE to double check the duplicates
SELECT *
FROM Row_Num_CTE
WHERE row_num > 1
ORDER BY PropertyAddress


-- 5.2:  Copy this and put below the CTE above and run both this and the CTE to DELETE the duplicates
DELETE
FROM Row_Num_CTE
WHERE row_num > 1

------------------------------------------------------------------------------------------------

--6. DELETE Unused Columns (OwnerAddress, TaxDistrict, PropertyAddress, and SaleDate)
ALTER TABLE HousingData..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

------Forgot to drop SaleDate too :)
ALTER TABLE HousingData..NashvilleHousing
DROP COLUMN SaleDate

------Let's check if they are deleted
SELECT *
FROM HousingData..NashvilleHousing

-------------------------------------------------------------------------------------------------
