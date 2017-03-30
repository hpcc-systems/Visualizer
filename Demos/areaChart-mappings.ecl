#WORKUNIT('name', 'hpcc-viz-AreaChart-mappings');
IMPORT $.^.SampleData.Sales;
IMPORT $.^.Visualizer;

//  Output entire dataset - can be any shape
OUTPUT(CHOOSEN(SORT(Sales.CleanDataset, Fixed_Order_Date), ALL), NAMED('Sales'));

//  Declare viz columns <--> output field mapping (the viz pulls only the columns of data it needs from the entire dataset)
mappings :=  DATASET([  {'Date', 'Fixed_Order_Date'}, 
                        {'Unit Price', 'Unit_Price'}, 
                        {'Shipping Cost', 'Shipping_Cost'}], Visualizer.KeyValueDef);

//  Create the visualization
Visualizer.MultiD.area('myChart', /*datasource*/, 'Sales', mappings, /*filteredBy*/, /*dermatologyProperties*/ );

//  Note - we can do better see areaChart-mappings-properties.ecl'