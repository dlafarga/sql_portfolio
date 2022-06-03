SELECT *
From PortfolioProject..CovidDeaths$
where continent is not NULL
order by 3,4

SELECT *
From PortfolioProject..CovidVaccinations$
order by 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths$
order by 1,2 -- order by location and date (column 1 and 2)

-- Looking at Total cases vs Total deaths in the US

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage -- sets alias, makes new col
From PortfolioProject..CovidDeaths$
Where location like '%states%' -- not sure what the exact name is 
-- the % means 0 1 or multiple characters
-- example if you want something that starts with a do a%
-- if you want something that ends with a do %a
-- if you want something with states somewhere in the name do %states%
-- the "_" means a character so if you want something AT LEAST 3 letters in length do a__
order by 1,2

-- Looking at the total cases vs the population
-- shows what % of pop got covid
SELECT location, date, total_cases, population, (total_cases/population)*100 as percent_pop_infected
From PortfolioProject..CovidDeaths$
Where location like '%states%'
order by 1,2

-- what counteries have the highest infection rate compared to pop?

SELECT location, population, MAX(total_cases) as Highest_Infection_Cnt,MAX(total_cases/population)*100 as percent_pop_infected
From PortfolioProject..CovidDeaths$
Group by location, population
order by percent_pop_infected desc


-- showing how many people died
SELECT location, MAX(cast(total_deaths as int)) as max_tot_deaths
From PortfolioProject..CovidDeaths$
where continent is not NULL
Group by location
order by max_tot_deaths desc

-- BREAKING IT BY CONTINENT
SELECT location, MAX(cast(total_deaths as int)) as max_tot_deaths
From PortfolioProject..CovidDeaths$
where continent is NULL
Group by location
order by max_tot_deaths desc

SELECT continent, MAX(cast(total_deaths as int)) as max_tot_deaths
From PortfolioProject..CovidDeaths$
where continent is not NULL
Group by continent
order by max_tot_deaths desc

-- now we want to think about visualizing this 
-- we want to drill down
-- so we see continent then we see the locations inside of that

-- GLOBAL NUMBERS
-- calculate everything accross the entire world
SELECT date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths ,(sum(cast(new_deaths as int))/sum(new_cases))*100 as Death_Percentage 
From PortfolioProject..CovidDeaths$
Where continent is not NULL
group by date
order by 1,2

SELECT sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths ,(sum(cast(new_deaths as int))/sum(new_cases))*100 as Death_Percentage 
From PortfolioProject..CovidDeaths$
Where continent is not NULL
order by 1,2


-- Joining tables
SELECT *
From PortfolioProject..CovidDeaths$ dea -- giving alias dea
Join PortfolioProject..CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date

-- looking at total pop vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PortfolioProject..CovidDeaths$ dea -- giving alias dea
Join PortfolioProject..CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
Where vac.new_vaccinations is not null and dea.continent is not null
order by 1,2,3

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as int)) 
over(partition by dea.location order by dea.location, dea.date) as rolling_pep_vac
From PortfolioProject..CovidDeaths$ dea -- giving alias dea
Join PortfolioProject..CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
Where  dea.continent is not null
order by 2,3

-- use CTE
With PopvsVac(continent, location, date, pop, new_vac, rolling_pep_vac)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as int)) 
over(partition by dea.location order by dea.location, dea.date) as rolling_pep_vacc
From PortfolioProject..CovidDeaths$ dea -- giving alias dea
Join PortfolioProject..CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
Where  dea.continent is not null
)
select *, (rolling_pep_vac/pop) * 100 as percent_vac_pop
from PopvsVac

-- Temp table
drop table if exists #PercentPopVaccinated
create table #PercentPopVaccinated(
continent nvarchar(255),
loc nvarchar(255),
date datetime,
pop numeric,
new_vac numeric,
rolling_pep_vac numeric
)
select *
from #PercentPopVaccinated

Insert into #PercentPopVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, 
dea.date) as rolling_pep_vacc
From PortfolioProject..CovidDeaths$ dea 
Join PortfolioProject..CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
Where dea.continent is not null

select *
from #PercentPopVaccinated

--creating view to store data for later vis
create View PercentPopVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, 
dea.date) as rolling_pep_vacc
From PortfolioProject..CovidDeaths$ dea 
Join PortfolioProject..CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
Where dea.continent is not null

select *
from PercentPopVaccinated