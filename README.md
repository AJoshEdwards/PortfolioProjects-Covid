# PortfolioProjects-Covid <br>
Portfolio Project analysing Covid dataset from https://ourworldindata.org/covid-deaths <br>
Utilising SQL to explore the data extract and Power BI to demonstrate different factors within. <br>

--------------------

There are 3 files within this Project: <br>
&nbsp; &nbsp; • SQL file with all the queries I used to explore the data along with comments explaining what I'm investigating and how the query works.<br>
&nbsp; &nbsp; • PDF file with snapshots of the 2 page PowerBI dashboard for easy user viewing.<br>
&nbsp; &nbsp; • Power BI template file for the full interactive viewing.<br>

--------

Method:<br>
I downloaded the static CSV file from the ourworldindata website, and split the full file into two separate file for ease of use. <br>
&nbsp; &nbsp; • Covid Deaths file<br>
&nbsp; &nbsp; • Covid Vaccination file<br>
I imported the separate files into a SQL database to explore as mentioned above, and then loaded the specific queries into PowerBI - utilising Power Query steps to add any transformations not done within SQL. After this I represented the data using different visuals within PowerBI to allow the user to interrogate the data themselves. <br>

---------

Lessons:<br>
For a fully produced dashboard I would look to automatically pull the Covid database into the PowerBI Dashboard or SQL server (possibly by Webscraping or via an API) which would allow the data to remain up to date whenever the Power BI dashboard was refreshed.
