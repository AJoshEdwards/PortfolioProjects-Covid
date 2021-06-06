/* 
Covid 19 Data Exploration
Data Source: https://ourworldindata.org/covid-deaths

The aim of this project is to explore and investigate the data provided above, to provide potential insights and represent the data via a Power BI Dashboard
I've split the data from the full dataset into two tables initially, Covid Deaths and Covid Vaccinations and imported these to SQL to produce cleaner and easier to read queries. 
*/

-- Review Data from Covid Database to ensure the data has been correctly imported
select * from CovidDeaths
select * from CovidVaccinations

-- Review Data (more specifically with some of the columns I'll be using)
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

/* Considering the data, it'd be good to show things like infection rate (likely to be infected), mortality rate (likelihood of dying if you contract Covid), how these vary over time, by Country and Continent */

-- Total Cases vs Total Deaths
-- Shows mortality rate by Country

Select 
	Location as Country
	,Continent
	,Date
	,total_cases
	,total_deaths
	,(total_deaths/total_cases)*100 as MortalityPercentage
from
	CovidDeaths
where continent is not null --This removes the cases where Location is a Continent
order by 
	1,3

/* Here notably the Location has both countries and continents, even though there is a separate Continent column within the data. For the queries by Country I'm going to exclude the cases where Location is a Continent, 
and for the Continent queries I'll be using the Continent column and grouping instead of using the "Location is a Continent" cases. */

-- Total Cases vs Population
-- Shows infection rate by Country
Select 
	Location as Country
	,continent
	,Date
	,population
	,total_cases
	,(total_cases/population)*100 as InfectionRate
from
	CovidDeaths
where continent is not null
order by 
	1,3

--Total Cases vs Population (Ranked highest to lowest)
-- Shows infection rate by country ranked
Select
	Location as Country
	,population
	,max(total_cases) as TotalCases
	,(max(total_cases)/population)*100 as InfectionRate
from
	CovidDeaths
where 
	continent is not null
group by
	location,population
order by 
	4 desc

--Mortality Count vs Population (Ranked highest to lowest)
-- Shows the total mortality count by Country vs the Population of the Country, for example: Hungary has had 0.3% of it's population die due to Covid. (This does assume that within the data Total Deaths are directly caused by Covid)
Select
	Location as Country
	,population
	,max(cast(total_deaths as int)) as TotalDeaths
	,(max(cast(total_deaths as int))/population)*100 as DeathRate
from
	CovidDeaths
where
	continent is not null
group by
	location,population
order by 
	4 desc

--Mortality Count vs Total Cases (Ranked highest to lowest)
-- Shows Mortality rate by Country (the likelihood you'll die if you catch Covid by Country)
Select 
	Location as Country
	,max(total_cases) as TotalCases
	,max(cast(total_deaths as int)) as TotalDeaths
	,(max(cast(total_deaths as int))/max(total_cases))*100 as DeathPerecentage
from
	CovidDeaths
where
	continent is not null
group by 
	location
order by 
	4 desc

/* The next few queries will be by Continent instead of Country, as mentioned above there are continents within the location column, so there are a couple of ways to represent the data via continent. I'll show both here */	 
--Query 1
--Infection rate with Population by Continent
with cte as (            -- this first CTE displays all Countries and their Population
				select  
				continent,
				location,
				population,
				max(cast(total_cases as int)) as TotalCases
				from CovidDeaths
				where continent is not null
				group by continent,location,population
			) 
select 
	cte.continent,
	sum(cte.population) as Population,
	sum(cte.TotalCases) as TotalCases,
	sum(cte.TotalCases)/sum(cte.population)*100 as InfectionRate
from 
	cte
group by 
	cte.continent
order by 
	4 desc;
-- Query 2
--Infection rate with Population by Continent (Ranked highest to lowest)
select
	location
	,population
	,max(cast(total_cases as int)) as TotalCases
	,(max(cast(total_cases as int))/population)*100 as InfectionRate
from
	CovidDeaths
where
	continent is null
group by
	location,population
order by 
	4 desc;

/*	Query 2 (above) is simpler to write and provides more information than grouping by the Continent column (European Union for example is not included in query 1)
however comparing the outputs, the numbers differ slightly (specifically for Population counts, and Europe's TotalCases amount). It would be worth investigating how the data is captured leading to these slight descrepancies.
 */

/* I want to demonstrate the Infection Rate by Continent and how it's grown over the timeline, within the data new countries are added at different points creating a fluctuating population total as the timeline progresses, 
To circumvent this I've added a CTE to include max population regardless of date. 
Within the data there's both a TotalCases column and NewCases column, theoretically a rolling count of the new cases should equal the TotalCases column. The query below shows both methods (TotalCases column and NewCases rolling count) below
and highlights the slight differences in the two, these are due to (what are assumed to be errors within the data) when the New Cases column starts. Another highlighted issue is the lack of completeness for 2021/06/02 so this date has been excluded. */

--Infection Rate by Continent over time
-- popcountry creates a table with each countries population, popcont takes that table and groups by continent instead. Rollingcount produces the rolling count of new cases by continent.
with popcountry as (
select  
	continent,
	location,
	population
from 
	CovidDeaths
where 
	continent is not null
group by
	continent,location,population
				), 
	popcont as (
select 
	popcountry.continent,
	sum(popcountry.population) as Population
from 
	popcountry
group by 
	popcountry.continent
				),
	rollingcount as (
select distinct
	date,
	cd.continent,
	sum(new_cases) OVER (Partition by cd.continent order by cd.continent,cd.date) as RollingTotalCasesCount,
	popcont.population population
from 
	CovidDeaths cd left join popcont on popcont.continent = cd.continent
where 
	cd.continent is not null
					) 
select 
	rc.date,
	rc.continent,
	max(case when rollingtotalcasescount is null then 0 else RollingTotalCasesCount end) RollingTotalCasesCount,
	sum(case when total_cases is null then 0 else total_cases end) TotalCases,
	max(rc.population) Population,
	max(case when rollingtotalcasescount is null then 0 else RollingTotalCasesCount end)/max(rc.population)*100 as InfectionRateRTC,
	sum(case when total_cases is null then 0 else total_cases end)/max(rc.population)*100 as InfectionRateTC
from 
	rollingcount rc left join CovidDeaths cd on rc.continent = cd.continent and rc.date = cd.date 
where 
	cd.continent is not null and cd.date <> '2021-06-02 00:00:00.000' 
group by 
	rc.date,rc.continent 
order by 1

--Global Numbers Total Cases and Deaths
with cte as (
				select  				
				location,
				case when population is null then 0 else population end as Population,
				max(case when cast(total_cases as int) is null then 0 else cast(total_cases as int) end) as TotalCases,
				max(case when cast(total_deaths as int) is null then 0 else cast(total_deaths as int) end) as TotalDeaths
				from CovidDeaths
				where continent is not null
				group by location,population
			) 
select 
	sum(cte.population) as Population,
	sum(cte.TotalCases) as TotalCases,
	sum(cte.TotalDeaths) as TotalDeaths,
	sum(cte.TotalCases)/sum(cte.population)*100 as InfectionRate
from 
	cte

--Incorporating Covid Vaccinations Table
--Total Population vs Vaccinations per day (2 methods) (this shows a rolling count of people vaccinated by Country and Date)
--1st method with CTE,  
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
Select *,(RollingPeopleVaccinatedCount/Population)*100 as VaccinationRate from PopvsVacas;

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

