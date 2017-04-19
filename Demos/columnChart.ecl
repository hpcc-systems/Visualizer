#WORKUNIT('name', 'hpcc-viz-ColumnChart');
IMPORT $.^.SampleData.Sales;
IMPORT $.^.Visualizer;

//  Output "2D" dataset:  "Region" v "sum of Profit"
OUTPUT(TABLE(Sales.CleanDataset, {Region, UNSIGNED INTEGER4 Sum_Profit := SUM(GROUP, Profit)}, Region, FEW), NAMED('RegionProfit_Viz'));

//  Create the visualization, giving it a uniqueID "bubble" and supplying the result name "RegionProfit_Viz"
Visualizer.MultiD.column('myChart', /*datasource*/, 'RegionProfit_Viz', /*mappings*/, /*filteredBy*/, /*dermatologyProperties*/ );
