*Visualization Introduction*
============================

The Visualization bundle is an open-source add-on to the HPCC platform to allow you to create visualizations from the results of queries written in ECL.

Visualizations are an important means of conveying information from massive data. A good visual representation can help a human produce actionable analysis. A visually comprehensive representation of the information can help make the obscure more obvious.

Pie Charts, Line graphs, Maps, and other visual graphs help us understand the answers found in data queries. Crunching big data is only part of a solution; we must be able to make sense of the data, too. Data visualizations simplify the complex.

The Visualizer bundle extends the HPCC platform's functionality by allowing you to plot your data onto charts, graphs, and maps to add a visual representation that can be easily understood.

In addition, the underlying visualization framework supports advanced features to allow you to combine graphs to make interactive dashboards.


Installation
============

To install, use the ecl command line interface.
1. Download:  https://github.com/hpcc-systems/Visualizer/archive/master.zip
2. Unzip to “Visualizer” folder:  ```…\Downloads\Visualizer-master.zip -> …\Downloads\Visualizer```
3. Install using the command line interface:  ```ecl bundle install %USERPROFILE%\Downloads\Visualizer```

Alternatively you can install direct from GitHub:
```
ecl bundle install https://github.com/hpcc-systems/Visualizer.git
```

**Note**:  Depending on your OS you may need to run `cmd` as administrator.

All going well you should see:
```
Installing bundle Visualizer version 2.1.0
Visualizer    2.1.0      ECL Visualization
Bundle Installation complete
```    

**Note I**:  You may find it easier to manually set the PATH to include the ecl client tools:
```
set PATH=%PATH%;"c:\Program Files (x86)\HPCCSystems\7.4.0\clienttools\bin"
```

**Note II**:  To use the "ecl bundle install &lt;git url&gt;" command, git must be installed on your machine and accessible to the user (in the path).


Using the Visualization library
===============================

Once installed, you merely IMPORT the library, then call any method that is appropriate for your data shape.

For Example:
```
IMPORT Visualizer;
ds := DATASET([ {'English', 5},
                {'History', 17},
                {'Geography', 7},
                {'Chemistry', 16},
                {'Irish', 26},
                {'Spanish', 67},
                {'Bioligy', 66},
                {'Physics', 46},
                {'Math', 98}],
                {STRING subject, INTEGER4 year});
OUTPUT(ds, NAMED('chartData'));
Visualizer.TwoD.pie('myChart',, 'chartData');
```

Viewing the Visualization
=========================

After running a query with a visualization included, you can see the visualization in ECL Watch.

Open the workunit, then select the **Resources** tab.

Tutorial / Demos
================
* Tutorial:  
    * [Interactive Dashboard](tutorial/README.md)
* Demos:
    * [Hello World](Demos/helloWorld)
    * [Pie Chart](Demos/pieChart.ecl)
    * [Column Chart](Demos/columnChart.ecl)
    * [Area Chart (with mappings)](Demos/areaChart-mappings.ecl)
    * [Area Chart (with mappings + properties)](Demos/areaChart-mappings-properties.ecl)
    * [Dashboard](Demos/dashboard.ecl)
    * [Roxie Dashboard](Demos/roxieDashboard.ecl)
