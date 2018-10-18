# Dashboard Tutorial 
_The goal of this tutorial is to demonstrate how to create a data driven interactive dashboard._

##  Step 1 - Generate Sample Data

* [Step01.ecl](./Step01.ecl) - Generates some sample data.  Original code is taken from Programmers Guide.
* [Step01b.ecl](./Step01b.ecl) - Create Roxie Query.

##  Step 2 - Visualize Gender Distribution

[Step02.ecl](./Step02.ecl) - 
* Create grouped aggregate of "Gender" + "Row Count".
* Output data to a named result "gender_rowcount".
* Visualize data in a bubble chart.

##  Step 3 - Visualize US State Distribution

[Step03.ecl](./Step03.ecl) - 
* Create grouped aggregate of "State" + "Row Count".
* Output data to a named result "state_rowcount".
* Visualize data in a US State Choropleth.

##  Step 4 - Visualize Logical File Raw Data

[Step04.ecl](./Step04.ecl) - 
* Visualize logical file data in a Grid with some column mappings.

##  Step 5 - Combine Steps 2 -> 4 into a Dashboard

[Step05.ecl](./Step05.ecl) - 
* Combine steps 02, 03, 04 into single file
* Filter logical file based on selection of "Gender" and "State" visualizations.

##  Step 6 - Add roxie driven visualization

[Step06.ecl](./Step06.ecl) - 
* Add Roxie based Visualization
* Roxie inputs are based on Grid selection.

##  Bonus Step - AutoDash POC

[Step07.ecl](./Step07.ecl) - 
* Auto Generated Dashboard POC
