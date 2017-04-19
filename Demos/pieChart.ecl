#WORKUNIT('name', 'hpcc-viz-PieChart');
IMPORT $.^.SampleData.Sales;
IMPORT $.^.Visualizer;

//  Output "2D" dataset:  "Ship_Mode" v "sum of Order_Quantity"
OUTPUT(TABLE(Sales.CleanDataset, {Ship_Mode, UNSIGNED INTEGER4 Sum_Order_Quantity := SUM(GROUP, Order_Quantity)}, Ship_Mode, FEW), NAMED('Ship_Mode_Viz'));

//  Create the visualization, giving it a uniqueID "bubble" and supplying the result name "Ship_Mode_Viz"
Visualizer.TwoD.Pie('myChart', /*datasource*/, 'Ship_Mode_Viz', /*mappings*/, /*filteredBy*/, /*dermatologyProperties*/ );
