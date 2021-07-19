#WORKUNIT('name', 'hpcc-viz-observable');
IMPORT $.^.SampleData.Sales;
IMPORT $.^.Visualizer;
IMPORT $;

OUTPUT(Sales.CleanDataset, NAMED('my_data'), ALL);

Visualizer.Observable.Markdown('visualizer', $.observable_file);
