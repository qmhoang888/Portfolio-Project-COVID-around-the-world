SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM Portfolio_Project..CovidVaccinations
--ORDER BY 3,4

--Select Data that we r gonna use:
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Looking at Total Cases vs Total Deaths (Percentage Wise)
-- Shows the likelihood of dying if you contract COVID in your country
SELECT location, population, date, total_cases, total_deaths, (total_deaths/NULLIF(total_cases,0))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL and location LIKE '%states%'
ORDER BY 1,2

-- Looking at Total Cases VS Population
SELECT location, date, population, total_cases, (total_cases/population)*100 AS CasePercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
	AND location LIKE 'viet%'
ORDER BY 1,2

-- Looking at countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS "HighestInfectionCount", MAX(total_cases/population)*100 AS PercentofPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentofPopulationInfected DESC	



-- Showing the countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS INT)) AS "TotalDeathCount", MAX(total_deaths/population)*100 AS Death_Counts_Over_Population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC	

SELECT location, MAX(CAST(total_deaths AS INT)) AS "TotalDeathCount"
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC	

--LET'S BREAK THINGS DOWN BY CONTINENTS

--SHOWING CONTINENT WITH THE HIGHEST DEATH COUNT
SELECT continent, MAX(CAST(total_deaths AS INT)) AS "TotalDeathCount"
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC	


--GLOBAL NUMBERS
--New cases, New Deaths, and Death/Case Percentage per Day around the Globe
SELECT date, SUM(new_cases) AS New_cases, SUM(CAST(New_deaths AS INT)) AS new_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS Death_Percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

--Total Cases Around the World Upto This Point in time (8/14/2021)
SELECT SUM(new_cases) AS Total_cases, SUM(CAST(New_deaths AS INT)) AS Total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS Death_Percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--JOIN 2 TABLES
SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date

--LOOKING AT TOTAL VACCINATION VS TOTAL POPULATION
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location) AS total_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--LOOKING AT TOTAL VACCINATION PER DAY OF EVERY COUNTRY (ROLLING COUNT)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- LOOKING AT COUNTRIES' TOTAL VACCINATIONS VS TOTAL POPULATION 
SELECT dea.location, dea.population, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location) AS total_vaccinations
--total_vaccinations/dea.population*100 AS percentage_of_people_vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL


-- USE CTE
WITH PopVSVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)

SELECT *, RollingPeopleVaccinated/Population*100
FROM PopVSVac


--TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated 
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255), 
location nvarchar (255), 
date datetime, 
population numeric, 
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated


--CREATING VIEW TO STORE DATA LATE FOR VISUALIZATION
--PERCENTAGE OF PEOPLE GET VACCINATED COMPARED TO THE COUNTRY'S POPULATION
USE PortfolioProject
GO
CREATE VIEW PercentPopulationVaccinated5 AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GO
SELECT *
FROM PercentPopulationVaccinated5

--CREATING VIEW FOR COUNTRIES WITH HIGHEST DEATH COUNTS
USE PortfolioProject
GO
CREATE VIEW Country_With_Highest_Death_Counts AS
SELECT location, MAX(CAST(total_deaths AS INT)) AS "TotalDeathCount"
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
GO

--CREATING VIEW FOR CONTINENTS WITH HIGHEST DEATH COUNTS
USE PortfolioProject
GO
CREATE VIEW Continent_With_Highest_Death_Counts AS
SELECT continent, MAX(CAST(total_deaths AS INT)) AS "TotalDeathCount"
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent	
GO

--CREATING VIEW FOR DEATH COUNTS OVER POPULATION BY COUNTRY
USE PortfolioProject
GO
CREATE VIEW Death_Counts_Over_Population_By_Country AS
SELECT location, MAX(CAST(total_deaths AS INT)) AS "TotalDeathCount", MAX(total_deaths/population)*100 AS Death_Counts_Over_Population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
GO

--PERCENTAGE OF PEOPLE VACCINATED OVER POPULATION BY COUNTRY
USE PortfolioProject
GO
CREATE VIEW People_Vaccinated_Over_Population AS
SELECT ppv.location, CAST(MAX(ppv.RollingPeopleVaccinated/Population)*100 AS DECIMAL (5,2)) AS Vaccination_Over_Population
FROM PercentPopulationVaccinated5 ppv
GROUP BY location
GO
---------NICER FORMAT OF THE TABLE ABOVE --------
SELECT ppv.location, CAST(CAST(MAX(ppv.RollingPeopleVaccinated/Population)*100 AS DECIMAL (5,2)) AS varchar(255)) + ' %' as Percentage
FROM PercentPopulationVaccinated5 ppv
GROUP BY location

--CREATING VIEW FOR THE IMPACT OF STRINGENCY INDEX ON COVID AND HOW COUNTRIES RESPOND TO THE PANDEMIC
USE PortfolioProject
GO
CREATE VIEW Stringency_Index_Vs_COVID_Data AS
SELECT vac.location,
	vac.date,
	dea.population,
	vac.stringency_index AS Stringency_Index,
	dea.new_cases,
	dea.new_deaths,
	vac.new_tests,
	vac.new_vaccinations,
	SUM(dea.new_cases) OVER (PARTITION BY vac.location ORDER BY vac.location, vac.date) AS Rolling_New_Cases,
	SUM(CAST(dea.new_deaths AS INT)) OVER (PARTITION BY vac.location ORDER BY vac.location, vac.date) AS Rolling_New_Deaths,
	SUM(CAST(vac.new_tests AS INT)) OVER (PARTITION BY vac.location ORDER BY vac.location, vac.date) AS Rolling_New_Tests,
	SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY vac.location ORDER BY vac.location, vac.date) AS Rolling_New_Vaccinations
FROM PortfolioProject..CovidVaccinations vac
	JOIN PortfolioProject..CovidDeaths dea 
		ON vac.location = dea.location AND vac.date = dea.date
WHERE vac.continent IS NOT NULL
GO





