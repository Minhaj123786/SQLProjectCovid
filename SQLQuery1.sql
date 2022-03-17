SELECT * from ..CovidDeaths
ORDER BY 3,4

--SELECT * from ..CovidVaccinations
--ORDER BY 3,4

-- Select data to be used
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM ..CovidDeaths 
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if COVID-19 contracted in UK.
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM ..CovidDeaths 
WHERE location like '%kingdom%'
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows percentage of population that have contracted COVID-19.
SELECT location, date, population, total_cases, (total_cases/population)*100 as InfectionPercentage
FROM ..CovidDeaths 
--WHERE location like '%kingdom%'
ORDER BY 1,2


-- Looking at Highest Infection Rate compared to Population
SELECT location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as InfectionPercentage
FROM ..CovidDeaths 
--WHERE location like '%kingdom%'
GROUP BY location, population
ORDER BY 4 desc


-- Looking at countries with Highest Death Count per Population
SELECT location, max(cast(total_deaths as int)) as HighestDeathCount
FROM ..CovidDeaths 
-- The data has mixed locations and continents, to avoid obtaining data for continents, the WHERE clause should be executed.
WHERE continent is not null
GROUP BY location
ORDER BY 2 desc


-- LOOKING AT IT FROM CONTINENT VIEW

-- Showing continents with highest death counts

-- Accurate Numbers: 
SELECT location, max(cast(total_deaths as int)) as HighestDeathCount
FROM ..CovidDeaths 
-- The data has mixed locations and continents, to avoid obtaining data for continents, the WHERE clause should be executed.
WHERE continent is null
GROUP BY location
ORDER BY 2 desc

-- For visualisation purposes: 
SELECT continent, max(cast(total_deaths as int)) as HighestDeathCount
FROM ..CovidDeaths 
-- The data has mixed locations and continents, to avoid obtaining data for continents, the WHERE clause should be executed.
WHERE continent is not null
GROUP BY continent
ORDER BY 2 desc


--GLOBAL NUMBERS

-- Global Death Percent per Date
SELECT  date, SUM(new_cases) as TotalCases,SUM(cast(new_deaths as int)) as TotalDeaths, (SUM(cast(new_deaths as int)) / SUM(new_cases)) *100 as DeathPercent
FROM ..CovidDeaths 
--WHERE location like '%kingdom%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


-- JOIN BOTH TABLES AND VEIWING SOME DATA

--Total Population vs Total Vaccinations
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations
FROM CovidDeaths as death
JOIN CovidVaccinations as vaccine
ON death.location = vaccine.location
   and death.date = vaccine.date
WHERE death.continent is not null
ORDER BY 2,3

-- Same but with rolling count of Total Vaccinations for each location
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations as VaccinationsPerDay, 
(SUM(convert(bigint,vaccine.new_vaccinations)) OVER (Partition by death.location ORDER BY death.location, death.date)) as RollingCountVaccinations
FROM CovidDeaths as death
JOIN CovidVaccinations as vaccine
ON death.location = vaccine.location
   and death.date = vaccine.date
WHERE death.continent is not null
ORDER BY 2,3


-- This time with Rolling count of Percent of Population Vaccinated
-- This cannot be done by doing (RollingCountVaccinations/population) as SQL does not allow us to use columns we have just created.
-- Thus, a TEMP TABLE can be created which can be used to perform this. 

DROP TABLE if exists #PercentPopulationVaccinated -- If query is run multiple times, prevents errors being thrown. 
Create Table #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingCountVaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated

SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations as VaccinationsPerDay, 
(SUM(convert(bigint,vaccine.new_vaccinations)) OVER (Partition by death.location ORDER BY death.location, death.date)) as RollingCountVaccinations
FROM CovidDeaths as death
JOIN CovidVaccinations as vaccine
ON death.location = vaccine.location
   and death.date = vaccine.date
WHERE death.continent is not null
ORDER BY 2,3

SELECT *,  (RollingCountVaccinations/Population)*100
FROM #PercentPopulationVaccinated


-- Creating view for Data Visualisations

CREATE VIEW PercentPopulationVaccinated as
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations as VaccinationsPerDay, 
(SUM(convert(bigint,vaccine.new_vaccinations)) OVER (Partition by death.location ORDER BY death.location, death.date)) as RollingCountVaccinations
FROM CovidDeaths as death
JOIN CovidVaccinations as vaccine
ON death.location = vaccine.location
   and death.date = vaccine.date
WHERE death.continent is not null
--ORDER BY 2,3