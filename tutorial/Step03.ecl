IMPORT $.^.Visualizer;
IMPORT $.DataDictionary AS DD;

//  Create grouped aggregate by State  ---
state := TABLE(DD.Dataset_Person, {state, UNSIGNED INTEGER4 rowcount := COUNT(GROUP)}, state, FEW);

//  Output data to named result for visualization  ---
OUTPUT(state, NAMED('state_rowcount'));

//  Create "Bubble" Visualization  ---
Visualizer.Choropleth.USStates('Step03', , 'state_rowcount');
