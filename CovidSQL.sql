--Review Data
select * from CovidDeaths
where continent =  'North America'
-- Review Data
Select 
	Location
	,Date
	,total_cases
	,new_cases
	,total_deaths
	,population
from
	CovidDeaths
order by 
	1,2

-- Total Cases vs Total Deaths
Select 
	Location
	,Date
	,total_cases
	,total_deaths
	,(total_deaths/total_cases)*100 as DeathPerecentage
from
	CovidDeaths
order by 
	1,2

-- Total Cases vs Population
Select 
	Location
	,Date
	,population
	,total_cases
	,(total_cases/population)*100 as InfectionRate
from
	CovidDeaths
order by 
	1,2

--Infection Rate vs Population (Ranked highest to lowest)
Select
	Location
	,population
	,max(total_cases) as TotalCases
	,(max(total_cases)/population)*100 as InfectionRate
from
	CovidDeaths
group by
	location,population
order by 
	4 desc

--Death Count per Population (Ranked highest to lowest)
Select
	Location
	,population
	,max(cast(total_deaths as int)) as TotalDeaths
	,(max(cast(total_deaths as int))/population)*100 as DeathRate
from
	CovidDeaths
group by
	location,population
order by 
	4 desc

--Death Count per Population (Continent) (Ranked highest to lowest) --it's worth noting that Continents are included within Location data so there's an easier way to do this (shown below)
with cte as (
				select distinct 
				continent,
				location,
				population,
				max(cast(total_deaths as int)) as TotalDeaths
				from CovidDeaths
				where continent is not null
				group by continent,location,population
			)
select 
	cte.continent,
	sum(cte.population) as Population,
	sum(cte.totaldeaths) as TotalDeaths,
	sum(cte.TotalDeaths)/sum(cte.population)*100 as DeathRate
from 
	cte
group by 
	cte.continent

--Death Count per Population (Continent) (Ranked highest to lowest) -- Easier way due to data however numbers differ slightly to above due to data totals
Select
	location
	,population
	,max(cast(total_deaths as int)) as TotalDeaths
	,(max(cast(total_deaths as int))/population)*100 as DeathRate
from
	CovidDeaths
where
	continent is null
group by
	location,population
order by 
	3 desc

--Global Numbers Total New Cases and Deaths per Day (have to exclude places with no continent as these are Location = World,Asia etc). 
--We encounter an error here due to 02/06/2021 data having 0 new cases and 0 new deaths causing a divide by 0 hence the need for a case when, a different solution would be to drop this date prior to uploading to SQL
Select
	Date,
	sum(new_cases) as TotalCases,
	sum(cast(new_deaths as int)) as TotalDeaths,
	case when sum(new_cases) <> 0 then sum(cast(new_deaths as int))/sum(new_cases)*100 else 0 end as DeathPercentage
from 
	CovidDeaths
where
	continent is not null
group by 
	date
order by 
	1,2

--Incorporating Covid Vaccinations Table
--Total Population vs Vaccinations per day 2 methods
--1st method with CTE
with PopvsVacas (Continent,Location,Date,Population,New_Vaccinations,RollingPeopleVaccinatedCount)
as
(
Select 
	dea.continent,
	dea.location, 
	dea.date,
	dea.population, 
	vac.new_vaccinations 
	,sum(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinatedCount

from
	CovidDeaths dea 
	left join CovidVaccinations vac on dea.location = vac.location and dea.date = vac.date
where 
	dea.continent is not null
)
Select *,(RollingPeopleVaccinatedCount/Population)*100 as VaccinationRate from PopvsVacas

--2nd method with Temp Table
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations int,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select 
	dea.continent,
	dea.location, 
	dea.date,
	dea.population, 
	vac.new_vaccinations 
	,sum(convert(int,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinatedCount

from
	CovidDeaths dea 
	left join CovidVaccinations vac on dea.location = vac.location and dea.date = vac.date
where 
	dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100 as VaccinationRate 
from #PercentPopulationVaccinated
order by 2,3

