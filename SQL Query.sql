SELECT *
FROM CovidProject..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..CovidDeaths
WHERE continent is NOT NULL
ORDER by 1,2

--Global Numbers by Date (KPIs)
SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 as death_percentage
FROM CovidProject..CovidDeaths
WHERE continent is NOT NULL

--Total Cases vs Total Deaths
SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM CovidProject..CovidDeaths
WHERE location like '%indonesia%'
ORDER by 1,2

--Percentage of population got covid
SELECT location, date, total_cases, population, total_deaths, (total_cases/population)*100 as population_infected_percentage
FROM CovidProject..CovidDeaths
WHERE location like '%indonesia%'
ORDER by 1,2

--Countries with highest infection rate compared to population
SELECT location, MAX(total_cases) AS highest_infection_count, population, MAX(total_cases/population)*100 as covid_percentage
FROM CovidProject..CovidDeaths
WHERE continent is NOT NULL
GROUP by population, location
ORDER by covid_percentage desc

--Countries with highest death count per population
SELECT location, MAX(cast(total_deaths as int)) as total_death_count, population, (MAX(cast(total_deaths as int))/population)*100 as death_percentage
FROM CovidProject..CovidDeaths
WHERE continent is NOT NULL
GROUP by population, location
ORDER by total_death_count desc

--Continent with highest death count per population
SELECT continent, MAX(cast(total_deaths as int)) as total_death_count
FROM CovidProject..CovidDeaths
WHERE continent is NOT NULL
GROUP by continent
ORDER by total_death_count desc

--Total Population vs Vaccination
--CTE
With PopvsVac (Continent, Location, Date, Population, new_vaccinations, rolling_people_vaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(Convert(BIGINT, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date ROWS UNBOUNDED PRECEDING) as rolling_people_vaccinated
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is NOT NULL
)
Select*, (rolling_people_vaccinated/population)*100 as people_vaccinated_percentage
From PopvsVac

--Percentage of population who got vaccinated
--Temp Table
DROP table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)
Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(Convert(BIGINT, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date ROWS UNBOUNDED PRECEDING) as rolling_people_vaccinated
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is NOT NULL

Select*, (rolling_people_vaccinated/population)*100 as people_vaccinated_percentage
From #PercentPopulationVaccinated

--Create view to store data
Create view PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(Convert(BIGINT, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date ROWS UNBOUNDED PRECEDING) as rolling_people_vaccinated
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is NOT NULL

SELECT *
FROM PercentPopulationVaccinated
