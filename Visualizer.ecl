EXPORT Visualizer := MODULE
    IMPORT Std;

    EXPORT Bundle := MODULE(Std.BundleBase)
        EXPORT Name := 'Visualizer';
        EXPORT Description := 'ECL Visualization Bundle';
        EXPORT Authors := ['HPCC Systems'];
        EXPORT License := 'http://www.apache.org/licenses/LICENSE-2.0';
        EXPORT Copyright := 'Copyright (C) 2017 HPCC Systems';
        EXPORT DependsOn := [];
        EXPORT Version := '1.0.1';
    END;

    EXPORT KeyValueDef := RECORD 
        STRING key;
        STRING value 
    END;
    SHARED NullKeyValue := DATASET([], KeyValueDef);

    EXPORT FiltersDef := RECORD 
        STRING source;
        DATASET(KeyValueDef) mappings;
    END;
    SHARED NullFilters := DATASET([], FiltersDef);

    /**
    * Meta - Outputs visualization meta information  
    *
    * Creates a "special" output file, containing the meta information for 
    * the visualization.
    * 
    * @param _classID       Visualization Type
    * @param _id            Visualization ID
    * @param _dataSource    Location of result (WU, Logical File, Roxie)
    * @param _outputName    Result name (ignored for Logical Files)
    * @param _mappings      Maps Column Name <--> field ID
    * @param _filteredBy    Specifies filter condition
    * @param _properties    User specified dermatology properties
    * @return               A "meta" output describing the visualization 
    **/    
    EXPORT Meta(STRING _classID, STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
        MetaDef := RECORD 
            STRING classid;
            STRING datasource;
            STRING resultname;
            DATASET(KeyValueDef) mappings;
            DATASET(FiltersDef) filteredby;
            DATASET(KeyValueDef) properties;
        END;

        id := IF(_id = '', _outputName, _id);
        ds := DATASET([{_classID, _dataSource, _outputName, _mappings, _filteredBy, _properties}], MetaDef);
        RETURN OUTPUT(ds, NAMED(id + '__hpcc_visualization'));
    END;

    /*  -----------------------------------------------------------------------
    */    
    EXPORT Any := MODULE
           
        /**
        * Grid - Renders data in a data grid / table 
        *
        * mappings can be used to limit / rename the columns.
        * 
        * @param _id            Visualization ID
        * @param _dataSource    Location of result (WU, Logical File, Roxie), defaults to current WU
        * @param _outputName    Result name (ignored for Logical Files)
        * @param _mappings      Maps Column Name <--> field ID
        * @param _filteredBy    Specifies filter condition
        * @param _properties    User specified dermatology properties
        * @return               A "meta" output describing the visualization 
        * @see                  Common/Meta
        **/    
        EXPORT Grid(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Meta('other_Table', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;

        EXPORT HandsonGrid(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Meta('handson_Table', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;


        EXPORT __test := FUNCTION
            ds := DATASET([ {'English', 5, 43, 41, 92},
                            {'History', 17, 43, 83, 93},
                            {'Geography', 7, 45, 52, 83},
                            {'Chemistry', 16, 73, 52, 83},
                            {'Spanish', 26, 83, 11, 72},
                            {'Biology', 66, 60, 85, 6},
                            {'Physics', 46, 20, 53, 7},
                            {'Math', 98, 30, 23, 13}],
                            {STRING subject, INTEGER4 year1, INTEGER4 year2, INTEGER4 year3, INTEGER4 year4});
            data_exams := OUTPUT(ds, NAMED('ChartAny__test'));

            viz_grid := Grid('grid',, 'ChartAny__test');
            viz_grid2 := HandsonGrid('handsonGrid',, 'ChartAny__test', DATASET([{'Subject', 'subject'}, {'2013', 'year3'}, {'2014', 'year4'}], KeyValueDef), , DATASET([{'fixedColumn', true}], KeyValueDef));
            
            RETURN PARALLEL(data_exams, viz_grid, viz_grid2);
        END;
    END;
   
    /*  -----------------------------------------------------------------------
        Two Dimensional Visualizations

        Default Data requirements (can be overriden by mappings):
        * 2 Columns
        - Column 1 (string):  Label
        - Column 2 (number):  Value

        All other columns will be ignored.  See __test for an example.
    */    
    EXPORT TwoD := MODULE
            
        /**
        * Bubble - Renders data in a data grid / table 
        *
        * mappings can be used to limit / rename the columns.
        * 
        * @param _id            Visualization ID
        * @param _dataSource    Location of result (WU, Logical File, Roxie), defaults to current WU
        * @param _outputName    Result name (ignored for Logical Files)
        * @param _mappings      Maps Column Name <--> field ID
        * @param _filteredBy    Specifies filter condition
        * @param _properties    User specified dermatology properties
        * @return               A "meta" output describing the visualization 
        * @see                  Common/Meta
        **/    
        EXPORT Bubble(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Meta('chart_Bubble', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;
        
        EXPORT Pie(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Meta('chart_Pie', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;
        
        EXPORT Summary(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            _props2 := DATASET([{'playInterval', 3000}], KeyValueDef) + _properties;
            RETURN Meta('chart_Summary', _id, _dataSource, _outputName, , _filteredBy, _props2);
        END;

        EXPORT WordCloud(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Meta('other_WordCloud', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;
        

        EXPORT __test := FUNCTION
            ds := DATASET([ {'English', 5},
                            {'History', 17},
                            {'Geography', 7},
                            {'Chemistry', 16},
                            {'Irish', 26},
                            {'Spanish', 67},
                            {'Biology', 66},
                            {'Physics', 46},
                            {'Math', 98}],
                            {STRING subject, INTEGER4 year});
            data_exams := OUTPUT(ds, NAMED('TwoD__test'));
            
            viz_bubble := Bubble('bubble',, 'TwoD__test');
            viz_pie := Pie('pie',, 'TwoD__test');
            viz_summary := Summary('summary',, 'TwoD__test');
            viz_wordCloud := WordCloud('wordCloud',, 'TwoD__test');
            
            RETURN PARALLEL(data_exams, viz_bubble, viz_pie, viz_summary, viz_wordCloud);
        END;
       
    END;

    /*  -----------------------------------------------------------------------
        Multi Dimensional Visualizations

        Data requirements (can be overriden by mappings):
        * N Columns
        - Column 1 (string):  Label
        - Column 2 (number):  Value
        - Column 3 (number):  Value
        ...
        - Column N (number):  Value

        See __Test for an example.
    */    
    EXPORT MultiD := MODULE
        
        /**
        * Area - Renders data in a XY Axis chart 
        *
        * mappings can be used to limit / rename the columns.
        * 
        * @param _id            Visualization ID
        * @param _dataSource    Location of result (WU, Logical File, Roxie), defaults to current WU
        * @param _outputName    Result name (ignored for Logical Files)
        * @param _mappings      Maps Column Name <--> field ID
        * @param _filteredBy    Specifies filter condition
        * @param _properties    User specified dermatology properties
        * @return               A "meta" output describing the visualization 
        * @see                  Common/Meta
        **/    
        EXPORT Area(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Meta('chart_Area', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;
        
        EXPORT Bar(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Meta('chart_Bar', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;
        
        EXPORT Column(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Meta('chart_Column', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;

        EXPORT HexBin(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Meta('chart_HexBin', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;

        EXPORT Line(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Meta('chart_Line', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;

        EXPORT Scatter(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Meta('chart_Scatter', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;

        EXPORT Step(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Meta('chart_Step', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;

    
        EXPORT __test := FUNCTION
            ds := DATASET([ {'English', 5, 43, 41, 92},
                            {'History', 17, 43, 83, 93},
                            {'Geography', 7, 45, 52, 83},
                            {'Chemistry', 16, 73, 52, 83},
                            {'Spanish', 26, 83, 11, 72},
                            {'Biology', 66, 60, 85, 6},
                            {'Physics', 46, 20, 53, 7},
                            {'Math', 98, 30, 23, 13}],
                            {STRING subject, INTEGER4 year1, INTEGER4 year2, INTEGER4 year3, INTEGER4 year4});
            data_exams := OUTPUT(ds, NAMED('MultiD__test'));

            viz_area := Area('area',, 'MultiD__test');
            viz_bar := Bar('bar',, 'MultiD__test');
            viz_column := Column('column',, 'MultiD__test');
            viz_hexBin := HexBin('hexBin',, 'MultiD__test');
            viz_line := Line('line',, 'MultiD__test');
            viz_scatter := Scatter('scatter',, 'MultiD__test');
            viz_step := Step('step',, 'MultiD__test');
            
            RETURN PARALLEL(data_exams, viz_area, viz_bar, viz_column, viz_hexBin, viz_line, viz_scatter, viz_step);
        END;
    END;
    
    /*  -----------------------------------------------------------------------
        Geo Spatial Visualizations

        Data requirements (can be overriden by mappings):
        * 2 Columns
        - Column 1 (string):  location ID (depends on geo spatial type)
        - Column 2 (number):  Value

        See __Test for an example.
    */    
    EXPORT Choropleth := MODULE

        /**
        * USStates - US States Choropleth 
        *
        * Data requirements (can be overriden by mappings):
        *  * 2 Columns
        *    - Column 1 (string):  State 2 letter code
        *    - Column 2 (number):  Value
        *
        * @param _id            Visualization ID
        * @param _dataSource    Location of result (WU, Logical File, Roxie), defaults to current WU
        * @param _outputName    Result name (ignored for Logical Files)
        * @param _mappings      Maps Column Name <--> field ID
        * @param _filteredBy    Specifies filter condition
        * @param _properties    User specified dermatology properties
        * @return               A "meta" output describing the visualization 
        * @see                  Common/Meta
        **/    
        EXPORT USStates(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Meta('map_ChoroplethStates', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;

        /**
        * USCounties - US States Choropleth 
        *
        * Data requirements (can be overriden by mappings):
        *  * 2 Columns
        *    - Column 1 (number):  FIPS code
        *    - Column 2 (number):  Value
        *
        * @param _id            Visualization ID
        * @param _dataSource    Location of result (WU, Logical File, Roxie), defaults to current WU
        * @param _outputName    Result name (ignored for Logical Files)
        * @param _mappings      Maps Column Name <--> field ID
        * @param _filteredBy    Specifies filter condition
        * @param _properties    User specified dermatology properties
        * @return               A "meta" output describing the visualization 
        * @see                  Common/Meta
        **/    
        EXPORT USCounties(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Meta('map_ChoroplethCounties', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;

        /**
        * Euro - US States Choropleth 
        *
        * Data requirements (can be overriden by mappings):
        *  * 2 Columns
        *    - Column 1 (number):  Administration name
        *    - Column 2 (number):  Value
        *
        * @param _id            Visualization ID
        * @param _region        2 Letter Euro Code (GB, IE etc.)
        * @param _dataSource    Location of result (WU, Logical File, Roxie), defaults to current WU
        * @param _outputName    Result name (ignored for Logical Files)
        * @param _mappings      Maps Column Name <--> field ID
        * @param _filteredBy    Specifies filter condition
        * @param _properties    User specified dermatology properties
        * @return               A "meta" output describing the visualization 
        * @see                  Common/Meta
        **/    
        EXPORT Euro(STRING _id, STRING _region, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            _props2 := DATASET([{'region', _region}], KeyValueDef) + _properties;
            RETURN Meta('map_TopoJSONChoropleth', _id, _dataSource, _outputName, _mappings, _filteredBy, _props2);
        END;

        EXPORT EuroIE(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Euro(_id, 'IE', _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;

        EXPORT EuroGB(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Euro(_id, 'GB', _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;

        SHARED __testData := FUNCTION
            _usStates := DATASET([  {'AL', 4779736}, 
                                    {'AK', 710231}, 
                                    {'AZ', 6392017}, 
                                    {'AR', 2915918}],
                                    {STRING State, INTEGER4 weight});
            data_usStates := OUTPUT(_usStates, NAMED('choro_usStates'));

            _usCounties := DATASET([    {1073,29.946185501741},
                                        {1097,0.79566003616637},
                                        {1117,1.5223596574691},
                                        {4005,27.311773623042}],
                                        {STRING FIPS, INTEGER4 weight});
            data_usCounties := OUTPUT(_usCounties, NAMED('choro_usCounties'));
            
            _euroIE := DATASET([    {'Carlow', '27431', '27181', '54612'}, 
                                    {'Dublin City', '257303', '270309', '527612'}, 
                                    {'Kilkenny', '47788', '47631', '95419'}, 
                                    {'Cork', '198658', '201144', '399802'}],
                                    {STRING region, INTEGER4 males, INTEGER4 females, INTEGER4 total});
            data_euroIE := OUTPUT(_euroIE, NAMED('choro_euroIE'));
            
            RETURN PARALLEL(data_usStates, data_usCounties, data_euroIE);
        END;

        EXPORT __test := FUNCTION
            viz_usstates := USStates('usStates',, 'choro_usStates');
            viz_uscounties := USCounties('usCounties',, 'choro_usCounties');
            viz_euroIE := EuroIE('euroIE',, 'choro_euroIE', DATASET([{'County', 'region'}, {'Population', 'total'}], KeyValueDef),, DATASET([{'paletteID', 'Greens'}], KeyValueDef));
            viz_euroGB := EuroGB('euroGB');
            
            RETURN PARALLEL(__testData, viz_usstates, viz_uscounties, viz_euroIE, viz_euroGB);
        END;
    END;

    EXPORT main := FUNCTION
        RETURN PARALLEL(Any.__test, TwoD.__test, MultiD.__test, Choropleth.__test);
    END;
END;
