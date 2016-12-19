#WORKUNIT('name', 'hpcc-viz-SimpleDashbaord');
IMPORT $.^.SampleData.Sales;
IMPORT $.^.Visualizer;

//  Aggregate by Ship_Mode ---
OUTPUT(TABLE(Sales.CleanDataset, {Ship_Mode, UNSIGNED INTEGER4 Sum_Order_Quantity := SUM(GROUP, Order_Quantity)}, Ship_Mode, FEW), NAMED('Ship_Mode'));
Visualizer.MultiD.Column('myColumnChart',, 'Ship_Mode',,, DATASET([{'xAxisFocus', false}], Visualizer.KeyValueDef));

//  Aggregate by Order_Priority ---
OUTPUT(TABLE(Sales.CleanDataset, {Order_Priority, UNSIGNED INTEGER4 SumOrderQuantity := SUM(GROUP, Order_Quantity)}, Order_Priority, FEW), NAMED('Order_Priority'));
Visualizer.TwoD.Pie('myPieChart',, 'Order_Priority');

//  Aggregate by Region ---
OUTPUT(TABLE(Sales.CleanDataset, {Region, UNSIGNED INTEGER4 SumOrderQuantity := SUM(GROUP, Order_Quantity)}, Region, FEW), NAMED('Region'));
Visualizer.MultiD.Bar('myBarChart',, 'Region');

//  All data filtered by previous visualizations ---
OUTPUT(CHOOSEN(SORT(Sales.CleanDataset, Fixed_Order_Date), ALL), NAMED('Sales'));

mappings :=  DATASET([  {'Date', 'Fixed_Order_Date'}, 
                        {'Unit Price', 'Unit_Price'}, 
                        {'Shipping Cost', 'Shipping_Cost'}], Visualizer.KeyValueDef);

filter := DATASET([     {'myColumnChart', [{'Ship_Mode', 'Ship_Mode'}]},
                        {'myPieChart', [{'Order_Priority', 'Order_Priority'}]},
                        {'myBarChart', [{'Region', 'Region'}]}], Visualizer.FiltersDef);

properties := DATASET([ {'xAxisType', 'time'}, 
                        {'xAxisTypeTimePattern', '%Y-%m-%d'}, 
                        {'xAxisFocus', true},
                        {'interpolate', 'cardinal'}
                        ], Visualizer.KeyValueDef);

Visualizer.MultiD.Area('myLine',, 'Sales', mappings, filter, properties);
