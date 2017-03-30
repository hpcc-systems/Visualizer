#WORKUNIT('name', 'hpcc-viz-HelloWorld');
IMPORT $.^.Visualizer;

//  Create simple inline "2D" dataset.
ds := DATASET([ {'Hello', 20},
                {'World', 15}],
                {STRING subject, INTEGER4 year});

//  Output dataset giving it a "known" name so the visualization can locate the data
OUTPUT(ds, NAMED('HelloWorldViz'));

//  Create the visualization, giving it a uniqueID "bubble" and supplying the result name "HelloWorldViz"
Visualizer.TwoD.Bubble('bubble', /*datasource*/, 'HelloWorldViz', /*mappings*/, /*filteredBy*/, /*dermatologyProperties*/ );
