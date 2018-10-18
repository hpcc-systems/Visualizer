import { PropertyExt, Widget } from "@hpcc-js/common";
import { Edge, Graph, Vertex } from "@hpcc-js/graph";
// @ts-ignore
import { createResult, flattenResult } from "@hpcc-js/other";
import { Dashboard } from "./Dashboard";

declare function require(pkgNames: string[], callback: (...pkgs: any[]) => void);

export const __HPCC_VISUALIZATION = "__hpcc_visualization";

export class WUMetaDef extends PropertyExt {
    _metaResult;
    _id = "";
    _columns = [];
    _data = [];

    constructor(wuResult) {
        super();
        this._metaResult = wuResult;
        this._id = this._metaResult.name();
        this._columns = [];
        this._data = [];
    }

    mapData(result: object[]): object[] {
        const mappings = this.mappings();
        if (!mappings.length) return result;
        return result.map(row => {
            const retVal = {};
            for (const mapping of mappings) {
                retVal[mapping.key] = row[mapping.value.toLowerCase()];
            }
            return retVal;
        });
    }

    refreshData(selections = {}, maxRowCount: number = -1): Promise<{ columns: any[]; data: any[]; }> {
        const filterRequest = {};
        let isFiltered = false;
        let filterCount = 0;
        this.filteredBy().forEach(function (filter) {
            const selection = selections[filter.source + __HPCC_VISUALIZATION];
            if (selection) {
                ++filterCount;
                filter.mappings.forEach(function (mapping) {
                    filterRequest[mapping.value.toLowerCase()] = selection.row[mapping.key] || selection.row[mapping.key.toLowerCase()];
                });
            }
            isFiltered = true;
        }, this);

        let result: Promise<any>;
        if (!isFiltered || filterCount > 0) {
            const dataResult = createResult(this._metaResult.url(), this.dataSource(), this.resultName());
            result = dataResult.query({ Start: 0, Count: maxRowCount }, filterRequest).then(r => flattenResult(r, this.mappings()));
        } else {
            result = Promise.resolve({
                columns: [],
                data: []
            });
        }
        return result;
    }

}
WUMetaDef.prototype._class += " WUWudget";

export interface WUMetaDef {
    widgetClassID(): string;
    widgetClassID(_: string): this;
    widgetClass(): any;
    widgetClass(_: any): this;
    dataSource(): string;
    dataSource(_: string): this;
    resultName(): string;
    resultName(_: string): this;
    mappings(): any;
    mappings(_: any): this;
    filteredBy(): any;
    filteredBy(_: any): this;
    properties(): any;
    properties(_: any): this;
}

WUMetaDef.prototype.publish("widgetClassID", null, "string", "ESP Url");
WUMetaDef.prototype.publish("widgetClass", null, "object", "Widget Class Declaration");
WUMetaDef.prototype.publish("dataSource", null, "string", "Data Source");
WUMetaDef.prototype.publish("resultName", null, "string", "Result Name");
WUMetaDef.prototype.publish("mappings", null, "object", "Widget Mappings");
WUMetaDef.prototype.publish("filteredBy", null, "object", "Widget Filter Properties");
WUMetaDef.prototype.publish("properties", null, "object", "Widget Properties");

export class WUWidget extends Widget {
    _metaResult;
    _id = "";
    _columns = [];
    _data = [];

    constructor(wuResult) {
        super();
        this._metaResult = wuResult;
        this._id = this._metaResult.name();
        this._columns = [];
        this._data = [];
    }

    createWidget() {
        const WidetClass = this.widgetClass();
        const widget = new WidetClass()
            .id(this.id())
            ;

        this.properties().forEach(function (property) {
            if (typeof (widget[property.key]) === "function") {
                widget[property.key](property.value);
            }
        });
        return widget;
    }

    parseClassID(classID) {
        const parts = classID.split("_");
        return {
            pkg: "@hpcc-js/" + parts[0],
            def: parts[1]
        };
    }

    requireWidget(classID): Promise<Widget> {
        const context = this;
        return new Promise(function (resolve, reject) {
            const parsedClassID = context.parseClassID(classID);
            if (parsedClassID.pkg === "@hpcc-js/visualizer") {
                switch (parsedClassID.def) {
                    case "Dashboard":
                        resolve(Dashboard as any);
                        break;
                }
            } else {
                require([parsedClassID.pkg], function (pkg) {
                    resolve(pkg[parsedClassID.def]);
                });
            }
        });
    }

    resolveWidget(): Promise<void> {
        const context = this;
        return this.requireWidget(context.widgetClassID()).then(function (Widget) {
            context.widgetClass(Widget);
        });
    }

    resolve(): Promise<WUWidget> {
        return this._metaResult.query().then(result => {
            if (result && result.length) {
                if (result[0].vertices) {
                    this
                        .widgetClassID(result[0].classid)
                        .verticesMeta(new WUMetaDef(this._metaResult)
                            .widgetClassID(result[0].vertices[0].classid)
                            .dataSource(result[0].vertices[0].datasource || this._metaResult.wuid())
                            .resultName(result[0].vertices[0].resultname)
                            .mappings(result[0].vertices[0].mappings)
                            .filteredBy(result[0].vertices[0].filteredby)
                            .properties(result[0].vertices[0].properties))
                        .edgesMeta(new WUMetaDef(this._metaResult)
                            .widgetClassID(result[0].edges[0].classid)
                            .dataSource(result[0].edges[0].datasource || this._metaResult.wuid())
                            .resultName(result[0].edges[0].resultname)
                            .mappings(result[0].edges[0].mappings)
                            .filteredBy(result[0].edges[0].filteredby)
                            .properties(result[0].edges[0].properties))
                        .filteredBy(result[0].filteredby)
                        .properties(result[0].properties)
                        ;
                } else {
                    result[0].properties.push({ key: "baseUrl", value: `${this._metaResult._protocol}//${this._metaResult._host}/` });
                    this
                        .widgetClassID(result[0].classid)
                        .widgetMeta(new WUMetaDef(this._metaResult)
                            .widgetClassID(result[0].classid)
                            .dataSource(result[0].datasource || this._metaResult.wuid())
                            .resultName(result[0].resultname)
                            .mappings(result[0].mappings)
                            .filteredBy(result[0].filteredby)
                            .properties(result[0].properties))
                        .filteredBy(result[0].filteredby)
                        .properties(result[0].properties)
                        ;
                }
            } else {
                console.log("Visualizer meta-data is empty.");
            }
            return this.resolveWidget().then(() => this);
        });
    }

    refreshData(selections = {}, maxRowCount: number = -1) {
        const widget = this.widget();
        if (widget instanceof Graph) {
            return Promise.all([this.verticesMeta().refreshData(selections, maxRowCount), this.edgesMeta().refreshData({}, -1)]).then(results => {
                return this.refreshGraph(widget, results[0].data, this.verticesMeta().properties(), results[1].data, this.edgesMeta().properties());
            });
        } else {
            return this.widgetMeta().refreshData(selections, maxRowCount).then(results => {
                return this.refreshWidget(widget, results);
            });
        }
    }

    refreshWidget(widget: Widget, result: { columns: any[]; data: any[]; }) {
        widget
            .columns(result.columns)
            .data(result.data)
            .lazyRender()
            ;
    }

    refreshGraph(widget: Graph, vData: object[], vProps, eData: object[], eProps) {
        const vertexMap: { [id: string]: Vertex } = {};
        const vertices: Vertex[] = vData.map(row => {
            const vertex = new Vertex()
                .text(row[1])
                ;
            if (row[2]) {
                vertex.faChar(row[2]);
            } else {
                vertex.icon_diameter(0);
            }
            vProps.forEach(row => {
                if (typeof vertex[row.key] === "function") {
                    vertex[row.key](row.value);
                }
            });
            vertexMap[row[0]] = vertex;
            return vertex;
        });
        const edges: Edge[] = eData.map(row => {
            const source = vertexMap[row[0]];
            const target = vertexMap[row[1]];
            if (source && target) {
                const edge = new Edge()
                    .sourceVertex(source)
                    .targetVertex(target)
                    .text(row[2])
                    ;
                if (row[2]) {
                    edge.text(row[2]);
                }
                eProps.forEach(row => {
                    if (typeof edge[row.key] === "function") {
                        edge[row.key](row.value);
                    }
                });
                return edge;
            } else if (source) {
                console.log(`Invalid edge - no target vertex.`);
            } else if (target) {
                console.log(`Invalid edge - no source vertex.`);
            } else {
                console.log(`Invalid edge - no source or target verticies.`);
            }
            return undefined;
        }).filter(e => !!e) as Edge[];
        widget
            .data({ vertices, edges })
            .lazyRender()
            ;
    }

}
WUWidget.prototype._class += " WUWudget";

export interface WUWidget {
    widgetClassID(): string;
    widgetClassID(_: string): this;
    widgetClass(): any;
    widgetClass(_: any): this;
    widget(): Widget | Graph;
    widget(_: Widget | Graph): this;
    widgetMeta(): WUMetaDef;
    widgetMeta(_: WUMetaDef): this;
    verticesMeta(): WUMetaDef;
    verticesMeta(_: WUMetaDef): this;
    edgesMeta(): WUMetaDef;
    edgesMeta(_: WUMetaDef): this;
    filteredBy(): any;
    filteredBy(_: any): this;
    properties(): any;
    properties(_: any): this;
}

WUWidget.prototype.publish("widgetClassID", null, "string");
WUWidget.prototype.publish("widgetClass", null, "object", "Widget Class Declaration");
WUWidget.prototype.publish("widget", null, "object", "Widget Instance");
WUWidget.prototype.publish("widgetMeta", null, "object");
WUWidget.prototype.publish("verticesMeta", null, "object");
WUWidget.prototype.publish("edgesMeta", null, "object");
WUWidget.prototype.publish("filteredBy", null, "object", "Widget Filter Properties");
WUWidget.prototype.publish("properties", null, "object", "Widget Properties");

//  ===========================================================================
