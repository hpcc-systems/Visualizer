#WORKUNIT('name', 'hpcc-viz-grid-properties');
IMPORT $.^.Visualizer;

ds := DATASET([ {'English', 5, 43, 41, 92},
                {'History', 17, 43, 83, 93},
                {'Geography', 7, 45, 52, 83},
                {'Chemistry', 16, 73, 52, 83},
                {'Spanish', 26, 83, 11, 72},
                {'Biology', 66, 60, 85, 6},
                {'Physics', 46, 20, 53, 7},
                {'Math', 98, 30, 23, 13}],
                {STRING subject, INTEGER4 year1, INTEGER4 year2, INTEGER4 year3, INTEGER4 year4});

OUTPUT(ds, NAMED('ChartAny__test'));

//  Declare some "dermatology" properties
properties := DATASET([ {'collumnWidth', 'none'},
                        {'sortable', true}
                        ], Visualizer.KeyValueDef);

Visualizer.Any.Grid('grid',, 'ChartAny__test', /*mappings*/, /*filteredBy*/, properties);
