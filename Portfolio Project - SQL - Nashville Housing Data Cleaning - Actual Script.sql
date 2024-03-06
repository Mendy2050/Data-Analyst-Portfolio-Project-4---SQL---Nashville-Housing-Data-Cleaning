/*

Cleaning Data in SQL Queries

*/


SELECT *
FROM dbo.NashvilleHousing





--------------------------------------------------------------------------------------------------------------------------
-- 1. Standardize Date Format
SELECT SaleDateConverted, 
	   CONVERT(Date, SaleDate)
FROM dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)



-- If it doesn't UPDATE properly
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)






 --------------------------------------------------------------------------------------------------------------------------
-- 2. Populate Property Address data - Self JOIN
SELECT *
FROM dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID



SELECT a.ParcelID, 
	   a.PropertyAddress, 
	   b.ParcelID, 
	   b.PropertyAddress, 
	   ISNULL(a.PropertyAddress,
			  b.PropertyAddress)
FROM dbo.NashvilleHousing a
JOIN dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL



UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM dbo.NashvilleHousing a
JOIN dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL






--------------------------------------------------------------------------------------------------------------------------
-- 3. Breaking out Address into Individual Columns (Address, City, State)

--3.1 Split PropertyAddress
SELECT PropertyAddress
FROM dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
--ORDER BY ParcelID


SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1 ) AS Address, 
	   SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1 , LEN(PropertyAddress) ) AS Address
FROM dbo.NashvilleHousing




ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress) )


SELECT *
FROM dbo.NashvilleHousing







--3.2 Split OwnerAddress
SELECT OwnerAddress
FROM dbo.NashvilleHousing


SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3),
	   PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2),
	   PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
FROM dbo.NashvilleHousing



ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)



ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)



SELECT *
FROM dbo.NashvilleHousing






--------------------------------------------------------------------------------------------------------------------------
-- 4. Change Y and N to Yes and No in "Sold as Vacant" field
SELECT Distinct(SoldAsVacant), 
	   Count(SoldAsVacant)
FROM dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2




SELECT SoldAsVacant,
	   CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant
	   END
FROM dbo.NashvilleHousing





UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
				   END







-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- 5. Remove Duplicates
WITH RowNumCTE AS
	(
		SELECT *,
			   ROW_NUMBER() OVER (PARTITION BY ParcelID,
										       PropertyAddress,
										       SalePrice,
										       SaleDate,
										       LegalReference
							      ORDER BY UniqueID
					             ) row_num

		FROM dbo.NashvilleHousing
		--ORDER BY ParcelID
	)

--For test
--SELECT *
--FROM RowNumCTE
--WHERE ParcelID = '107 14 0 157.00' AND PropertyAddress = '1003  BRILEY PKWY, NASHVILLE'

--DELETE 
--FROM RowNumCTE
--WHERE row_num > 1

SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

/*
¡¤ PARTITION BY is used to partition the data into groups. 
¡¤ In this case, PARTITION BY uses all the columns specified. 
  The values in ¡¾these columns¡¿ need to be ¡¾exactly the same¡¿ in order for the rows to be considered as the same group.
¡¤ The rows will only be partitioned into the same group when the values of ParcelID, 
   PropertyAddress, SalePrice, SaleDate, and LegalReference columns are ¡¾fully matched¡¿. 
¡¤ Within each group, the rows are ordered by UniqueID. Then ROW_NUMBER can correctly number the duplicate rows.
¡¤ Therefore, the rows will only be treated as complete duplicates where ROW_NUMBER can label them, 
   only when the values of these 5 columns are ¡¾fully matched¡¿.
*/

SELECT *
FROM dbo.NashvilleHousing






---------------------------------------------------------------------------------------------------------
-- 6. Delete Unused Columns
SELECT *
FROM dbo.NashvilleHousing


ALTER TABLE dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate