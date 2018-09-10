IMPORT $.^.Visualizer;
IMPORT $.DataDictionary AS DD;

//  Create grouped aggregate by Gender  ---
gender := TABLE(DD.Dataset_Person, {gender, UNSIGNED INTEGER4 rowcount := COUNT(GROUP)}, gender, FEW);
OUTPUT(gender, NAMED('gender_rowcount'));
Visualizer.TwoD.Bubble('Step02', , 'gender_rowcount');

//  Create grouped aggregate by State  ---
state := TABLE(DD.Dataset_Person, {state, UNSIGNED INTEGER4 rowcount := COUNT(GROUP)}, state, FEW);
OUTPUT(state, NAMED('state_rowcount'));
Visualizer.Choropleth.USStates('Step03b', , 'state_rowcount', , , DATASET([{'paletteID', 'Blues'}], Visualizer.KeyValueDef));

//  Create filtered view ---
Visualizer.Any.Grid('Step05', 
        DD.LogicalFile_Person,, 
        DATASET([{'ID', 'personid'}, {'First Name', 'firstname'}, {'Last Name', 'lastname'}, {'Gender', 'gender'}, {'State', 'state'}], Visualizer.KeyValueDef), 
        DATASET([{'Step02', [{'gender', 'gender'}]}, {'Step03b', [{'state', 'state'}]}], Visualizer.FiltersDef)
        );
