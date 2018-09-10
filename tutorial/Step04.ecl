IMPORT $.^.Visualizer;
IMPORT $.DataDictionary AS DD;

//  Create "Raw" Visualization  ---
Visualizer.Any.Grid('Step04', DD.LogicalFile_Person,, DATASET([
                                                            {'ID', 'personid'}, 
                                                            {'First Name', 'firstname'}, 
                                                            {'Last Name', 'lastname'}
                                                            ], Visualizer.KeyValueDef));
