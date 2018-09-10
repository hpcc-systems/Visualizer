IMPORT $.^.Visualizer;
IMPORT $.DataDictionary AS DD;

//  Create grouped aggregate by Gender  ---
gender := TABLE(DD.Dataset_Person, {gender, UNSIGNED INTEGER4 rowcount := COUNT(GROUP)}, gender, FEW);

//  Output data to named result for visualization  ---
OUTPUT(gender, NAMED('gender_rowcount'));

//  Create "Bubble" Visualization  ---
Visualizer.TwoD.Bubble('Step02', , 'gender_rowcount');
