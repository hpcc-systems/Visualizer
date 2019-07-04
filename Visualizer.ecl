EXPORT Visualizer := MODULE
    IMPORT Std;

    EXPORT Bundle := MODULE(Std.BundleBase)
        EXPORT Name := 'Visualizer';
        EXPORT Description := 'ECL Visualization Bundle';
        EXPORT Authors := ['HPCC Systems'];
        EXPORT License := 'http://www.apache.org/licenses/LICENSE-2.0';
        EXPORT Copyright := 'Copyright (C) 2019 HPCC Systems';
        EXPORT DependsOn := [];
        EXPORT Version := '2.1.0';
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

    EXPORT MetaDef := RECORD 
        STRING classid;
        STRING datasource;
        STRING resultname;
        DATASET(KeyValueDef) mappings;
        DATASET(FiltersDef) filteredby;
        DATASET(KeyValueDef) properties;
    END;

    EXPORT lookupFlatDataset(lf) := FUNCTIONMACRO
        RETURN DATASET(lf, RECORDOF(lf, LOOKUP), FLAT);
    ENDMACRO;

    EXPORT lookupCSVDataset(lf) := FUNCTIONMACRO
        RETURN DATASET(lf, RECORDOF(lf, LOOKUP), CSV);
    ENDMACRO;

    SHARED lowCardinalityFields(inFile, maxCardinality = 64) := FUNCTIONMACRO
        LOADXML('<xml/>');
        #EXPORTXML(inFileFields, RECORDOF(inFile));
        #DECLARE(recLevel);
        #DECLARE(needsDelim);

        #SET(recLevel, 0)
        #FOR(inFileFields)
            #FOR(field)
                #IF(%{@isRecord}% = 1 OR %{@isDataset}% = 1)
                    #SET(recLevel, %recLevel% + 1)
                #ELSEIF(%{@isEnd}% = 1)
                    #SET(recLevel, %recLevel% - 1)
                #ELSEIF(%recLevel% = 0)
                    #EXPAND(%'@name'% + '_table') := CHOOSEN(TABLE(inFile, {STRING value := (STRING)#EXPAND(%'@name'%), UNSIGNED INTEGER4 rowcount := COUNT(GROUP)}, #EXPAND(%'@name'%), FEW), maxCardinality + 1);
                #END
            #END
        #END

        ValueRowCount := RECORD
            STRING value;
            UNSIGNED INTEGER4 rowcount;
        END;

        FieldValues := RECORD
            STRING fieldID;
            UNSIGNED INTEGER4 valueCount;
            DATASET(ValueRowCount) values;
        END;

        retVal := DATASET([
            #SET(recLevel, 0)
            #SET(needsDelim, 0)
            #FOR(inFileFields)
                #FOR(field)
                    #IF(%{@isRecord}% = 1 OR %{@isDataset}% = 1)
                        #SET(recLevel, %recLevel% + 1)
                    #ELSEIF(%{@isEnd}% = 1)
                        #SET(recLevel, %recLevel% - 1)
                    #ELSEIF(%recLevel% = 0)
                        #IF(%needsDelim% = 1) , #END                
                        {
                            %'@name'%,
                            COUNT(#EXPAND(%'@name'% + '_table')),
                            #EXPAND(%'@name'% + '_table')
                        }
                        #SET(needsDelim, 1)                    
                    #END
                #END
            #END
        ], FieldValues);
        RETURN retVal(valueCount <= maxCardinality);
    ENDMACRO;

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
            RETURN Meta('dgrid_Table', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
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
            
            RETURN PARALLEL(data_exams, viz_grid);
        END;
    END;
   
    /*  -----------------------------------------------------------------------
        Two Dimensional "Ordinal" Visualizations

        Default Data requirements (can be overridden by mappings):
        * 2 Columns
        - Column 1 (string):  Label
        - Column 2 (number):  Value

        All other columns will be ignored.  See __test for an example.
    */    
    EXPORT TwoD := MODULE
            
        /**
        * Renders data into a 2D Visualization 
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

        EXPORT RadialBar(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Meta('chart_RadialBar', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;

        EXPORT WordCloud(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Meta('chart_WordCloud', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;
        

        EXPORT __test := FUNCTION
            ds := DATASET([ {'English', 55},
                            {'History', 77},
                            {'Geography', 67},
                            {'Chemistry', 46},
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
            viz_radialBar := RadialBar('radialBar',, 'TwoD__test');
            viz_wordCloud := WordCloud('wordCloud',, 'TwoD__test');
            
            RETURN PARALLEL(data_exams, viz_bubble, viz_pie, viz_summary, viz_radialBar, viz_wordCloud);
        END;
       
    END;

    /*  -----------------------------------------------------------------------
        Two Dimensional "Linear" Visualizations

        Default Data requirements (can be overridden by mappings):
        * 2 Columns
        - Column 1 (number):  ValueX
        - Column 2 (number):  ValueY

        All other columns will be ignored.  See __test for an example.
    */    
    EXPORT TwoDLinear := MODULE
            
        /**
        * Renders data in a visualization 
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
        EXPORT Scatter(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            _props2 := DATASET([{'xAxisType', 'linear'}], KeyValueDef) + _properties;
            RETURN Meta('chart_Scatter', _id, _dataSource, _outputName, _mappings, _filteredBy, _props2);
        END;
        
        EXPORT HexBin(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            _props2 := DATASET([{'xAxisType', 'linear'}], KeyValueDef) + _properties;
            RETURN Meta('chart_HexBin', _id, _dataSource, _outputName, _mappings, _filteredBy, _props2);
        END;
        
        EXPORT Contour(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            _props2 := DATASET([{'xAxisType', 'linear'}, {'contourBandwidth', 15}], KeyValueDef) + _properties;
            RETURN Meta('chart_Contour', _id, _dataSource, _outputName, , _filteredBy, _props2);
        END;


        EXPORT __test := FUNCTION
            ds := DATASET([
                {5.1,3.5},{4.9,3.0},{4.7,3.2},{4.6,3.1},{5.0,3.6},{5.4,3.9},{4.6,3.4},{5.0,3.4},{4.4,2.9},{4.9,3.1},{5.4,3.7},{4.8,3.4},{4.8,3.0},{4.3,3.0},{5.8,4.0},{5.7,4.4},{5.4,3.9},{5.1,3.5},{5.7,3.8},{5.1,3.8},{5.4,3.4},{5.1,3.7},{4.6,3.6},{5.1,3.3},{4.8,3.4},{5.0,3.0},{5.0,3.4},{5.2,3.5},{5.2,3.4},{4.7,3.2},{4.8,3.1},{5.4,3.4},{5.2,4.1},{5.5,4.2},{4.9,3.1},{5.0,3.2},{5.5,3.5},{4.9,3.6},{4.4,3.0},{5.1,3.4},{5.0,3.5},{4.5,2.3},{4.4,3.2},{5.0,3.5},{5.1,3.8},{4.8,3.0},{5.1,3.8},{4.6,3.2},{5.3,3.7},{5.0,3.3},{7.0,3.2},{6.4,3.2},{6.9,3.1},{5.5,2.3},{6.5,2.8},{5.7,2.8},{6.3,3.3},{4.9,2.4},{6.6,2.9},{5.2,2.7},{5.0,2.0},{5.9,3.0},{6.0,2.2},{6.1,2.9},{5.6,2.9},{6.7,3.1},{5.6,3.0},{5.8,2.7},{6.2,2.2},{5.6,2.5},{5.9,3.2},{6.1,2.8},{6.3,2.5},{6.1,2.8},{6.4,2.9},{6.6,3.0},{6.8,2.8},{6.7,3.0},{6.0,2.9},{5.7,2.6},{5.5,2.4},{5.5,2.4},{5.8,2.7},{6.0,2.7},{5.4,3.0},{6.0,3.4},{6.7,3.1},{6.3,2.3},{5.6,3.0},{5.5,2.5},{5.5,2.6},{6.1,3.0},{5.8,2.6},{5.0,2.3},{5.6,2.7},{5.7,3.0},{5.7,2.9},{6.2,2.9},{5.1,2.5},{5.7,2.8},{6.3,3.3},{5.8,2.7},{7.1,3.0},{6.3,2.9},{6.5,3.0},{7.6,3.0},{4.9,2.5},{7.3,2.9},{6.7,2.5},{7.2,3.6},{6.5,3.2},{6.4,2.7},{6.8,3.0},{5.7,2.5},{5.8,2.8},{6.4,3.2},{6.5,3.0},{7.7,3.8},{7.7,2.6},{6.0,2.2},{6.9,3.2},{5.6,2.8},{7.7,2.8},{6.3,2.7},{6.7,3.3},{7.2,3.2},{6.2,2.8},{6.1,3.0},{6.4,2.8},{7.2,3.0},{7.4,2.8},{7.9,3.8},{6.4,2.8},{6.3,2.8},{6.1,2.6},{7.7,3.0},{6.3,3.4},{6.4,3.1},{6.0,3.0},{6.9,3.1},{6.7,3.1},{6.9,3.1},{5.8,2.7},{6.8,3.2},{6.7,3.3},{6.7,3.0},{6.3,2.5},{6.5,3.0},{6.2,3.4},{5.9,3.0}
                ],
                {REAL subject, REAL year});
            data_points := OUTPUT(ds, NAMED('TwoDLinear__test'));
            
            viz_scatter := Scatter('ScatterLinear',, 'TwoDLinear__test');
            viz_hexbin := HexBin('HexBinLinear',, 'TwoDLinear__test');
            viz_contour := Contour('ContourLinear',, 'TwoDLinear__test');
            
            RETURN PARALLEL(data_points, viz_scatter, viz_hexbin, viz_contour);
        END;
       
    END;

    /*  -----------------------------------------------------------------------
        Multi Dimensional Visualizations

        Data requirements (can be overridden by mappings):
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

        EXPORT Line(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Meta('chart_Line', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
        END;

        EXPORT Radar(STRING _id, STRING _dataSource = '', STRING _outputName = '', DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue) := FUNCTION
            RETURN Meta('chart_Radar', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
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
            viz_line := Line('line',, 'MultiD__test');
            viz_radar := Radar('radar',, 'MultiD__test');
            viz_scatter := Scatter('scatter',, 'MultiD__test');
            viz_step := Step('step',, 'MultiD__test');
            
            RETURN PARALLEL(data_exams, viz_area, viz_bar, viz_column, viz_line, viz_radar, viz_scatter, viz_step);
        END;
    END;
    
    /*  -----------------------------------------------------------------------
        Relational Visualizations

        Data requirements (can be overridden by mappings):
        * 2 Tables
          * Vertices (nodes):
            * 3 Columns
            - Column 1 (any):  Id
            - Column 2 (string):  Label
            - Column 3 (string):  Icon - see https://fontawesome.com/v4.7.0/cheatsheet/ 
          * Edges (links):
            * 2 Columns
            - Column 1 (any):  SourceId
            - Column 2 (any):  TargetId
            - Column 3 (string):  Label (optional)

        See __test for an example.
    */    
    EXPORT Relational := MODULE
        /**
        * Graph - Renders data in a entity relation chart 
        *
        * mappings can be used to limit / rename the columns.
        * 
        * @param _id                    Visualization ID
        * @param _verticesDatasource    Location of "vertices" result (WU, Logical File, Roxie), defaults to current WU
        * @param _verticesOutputName    "Vertices" result name (ignored for Logical Files)
        * @param _verticesMappings      Maps "Vertices" Column Name <--> field ID
        * @param _verticesProperties    User specified dermatology properties (vertices)
        * @param _edgesDatasource       Location of "vertices" result (WU, Logical File, Roxie), defaults to current WU
        * @param _edgesOutputName       "Vertices" result name (ignored for Logical Files)
        * @param _edgesMappings         Maps "Vertices" Column Name <--> field ID
        * @param _edgesProperties       User specified dermatology properties (edges)
        * @param _properties            User specified dermatology properties (graph)
        * @return                       A "meta" output describing the visualization 
        * @see                          Common/Meta
        **/    
        EXPORT Network(STRING _id, 
                    STRING _verticesDatasource = '', STRING _verticesOutputName = '', DATASET(KeyValueDef) _verticesMappings = NullKeyValue, DATASET(FiltersDef) _verticesFilteredBy = NullFilters, DATASET(KeyValueDef) _verticesProperties = NullKeyValue,
                    STRING _edgesDatasource = '', STRING _edgesOutputName = '', DATASET(KeyValueDef) _edgesMappings = NullKeyValue, DATASET(FiltersDef) _edgesFilteredBy = NullFilters,  DATASET(KeyValueDef) _edgesProperties = NullKeyValue,
                    DATASET(KeyValueDef) _graphProperties = NullKeyValue) := FUNCTION

            _verticesProperties2 := DATASET([
                {'icon_diameter', 48}, 
                {'icon_shape_colorStroke', 'transparent'}, 
                {'icon_shape_colorFill', 'transparent'}, 
                {'icon_image_colorFill', '#333333'}, 
                {'iconAnchor', 'middle'}, 
                {'textbox_shape_colorStroke', 'transparent'}, 
                {'textbox_shape_colorFill', 'white'}, 
                {'textbox_text_colorFill', '#333333'}], KeyValueDef) + _verticesProperties;

            _graphProperties2 := DATASET([
                {'layout', 'ForceDirected'}, 
                {'applyScaleOnLayout', true}], KeyValueDef) + _graphProperties;

            GraphMetaDef := RECORD
                STRING classid;
                DATASET(MetaDef) vertices;
                DATASET(MetaDef) edges;
                DATASET(KeyValueDef) properties;
            END;

            id := IF(_id = '', _verticesDatasource, _id);
            vds := DATASET([{'graph_Vertex', _verticesDatasource, _verticesOutputName, _verticesMappings, _verticesfilteredBy, _verticesProperties2}], MetaDef);
            eds := DATASET([{'graph_Edge', _edgesDatasource, _edgesOutputName, _edgesMappings, _edgesFilteredBy, _edgesProperties}], MetaDef);
            ds := DATASET([{'graph_Graph', vds, eds, _graphProperties2}], GraphMetaDef);
            RETURN OUTPUT(ds, NAMED(id + '__hpcc_visualization'));
        END;

        SHARED __testData := FUNCTION
            _vertices := DATASET([  {1, 'Home', u'\uf015'}, 
                                    {2, 'Woman', u''}, 
                                    {3, 'Man', u''}],
                                    {INTEGER4 id, STRING label, UTF8 faChar});
            data_vertices := OUTPUT(_vertices, NAMED('graph_vertices'));

            _edges := DATASET([     {1, 2},
                                    {1, 3}],
                                    {INTEGER4 sourceID, INTEGER4 targetID});
            data_edges := OUTPUT(_edges, NAMED('graph_edges'));
            
            RETURN PARALLEL(data_vertices, data_edges);
        END;

        EXPORT __test := FUNCTION
            viz_graph := Network('graph',
            /*_verticesDatasource*/, 'graph_vertices', /*_verticesMappings*/, /*_verticesfilteredBy*/, /*_verticesProperties*/,
            /*_edgesDatasource*/, 'graph_edges', /*_edgesMappings*/, /*_edgesFilteredBy*/, /*_edgesProperties*/,
            /*graphProps*/ );

            RETURN PARALLEL(__testData, viz_graph);
        END;
    END;        

    /*  -----------------------------------------------------------------------
        Geo Spatial Visualizations

        Data requirements (can be overridden by mappings):
        * 2 Columns
        - Column 1 (string):  location ID (depends on geo spatial type)
        - Column 2 (number):  Value

        See __Test for an example.
    */    
    EXPORT Choropleth := MODULE

        /**
        * USStates - US States Choropleth 
        *
        * Data requirements (can be overridden by mappings):
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
        * Data requirements (can be overridden by mappings):
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
        * Data requirements (can be overridden by mappings):
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

    EXPORT AutoDash := MODULE
        SHARED _postFix := '__hpcc_profile';

        SHARED _logicalfile(STRING _id, STRING _dataSource = '', STRING _outputName = '', VIRTUAL DATASET inFile, DATASET(KeyValueDef) _mappings = NullKeyValue, DATASET(FiltersDef) _filteredBy = NullFilters, DATASET(KeyValueDef) _properties = NullKeyValue, INTEGER maxCardinality = 64) := FUNCTION
            LOCAL profile := OUTPUT(lowCardinalityFields(inFile, maxCardinality), NAMED(_id + _postFix));
            LOCAL metaTmp := Meta('visualizer_Dashboard', _id, _dataSource, _outputName, _mappings, _filteredBy, _properties);
            RETURN PARALLEL(profile, metaTmp);
        END;

        EXPORT logicalfileExt(STRING _id, STRING _datasource, VIRTUAL DATASET _dataset, INTEGER maxCardinality = 64) := FUNCTION
            RETURN _logicalfile(_id, '', _id + _postFix, _dataset,,, DATASET([{'logicalFile', _datasource}], KeyValueDef), maxCardinality);
        END;

        EXPORT logicalfile(_id, _datasource, maxCardinality = 64) := FUNCTIONMACRO
            IMPORT Visualizer AS this;
            RETURN this.AutoDash.logicalfileExt(_id, _datasource, this.lookupFlatDataset(_datasource), maxCardinality);
        ENDMACRO;

        EXPORT __test := FUNCTION
            viz_dataset := lookupFlatDataset('~progguide::exampledata::accounts');
            viz_dashboard := logicalfileExt('dash', '~progguide::exampledata::accounts', viz_dataset);
            RETURN PARALLEL(viz_dashboard);
        END;
    END;

    EXPORT main := FUNCTION
        RETURN PARALLEL(Any.__test, TwoD.__test, TwoDLinear.__test, MultiD.__test, Relational.__test, Choropleth.__test);
    END;
END;
