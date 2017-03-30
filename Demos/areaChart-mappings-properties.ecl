#WORKUNIT('name', 'hpcc-viz-AreaChart-mappinggs-properties');
IMPORT $.^.SampleData.Sales;
IMPORT $.^.Visualizer;

//  Output subset of data - can be any shape
OUTPUT(CHOOSEN(SORT(Sales.CleanDataset(Region='West'), Fixed_Order_Date), ALL), NAMED('Sales'));

//  Declare viz columns <--> output field mapping (the viz pulls only the columns of data it needs from the entire dataset)
mappings :=  DATASET([  {'Date', 'Fixed_Order_Date'}, 
                        {'Unit Price', 'Unit_Price'}, 
                        {'Shipping Cost', 'Shipping_Cost'}], Visualizer.KeyValueDef);

//  Declare some "dermatology" properties
properties := DATASET([ {'xAxisType', 'time'}, 
                        {'xAxisTypeTimePattern', '%Y-%m-%d'}, 
                        {'yAxisType', 'pow'},
                        {'yAxisTypePowExponent', 0.3}
                        ], Visualizer.KeyValueDef);

//  Create the visualization
Visualizer.MultiD.area('myChart', /*datasource*/, 'Sales', mappings, /*filteredBy*/, properties );
