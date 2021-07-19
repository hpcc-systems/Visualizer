import { Utility, Widget } from "@hpcc-js/common";
import { Workunit } from "@hpcc-js/comms";
import { Dermatology, Persist } from "@hpcc-js/composite";
import { Button } from "@hpcc-js/form";
import { topoJsonFolder } from "@hpcc-js/map";
import { cache, createConnection, enableCache, Persist as Persist2 } from "@hpcc-js/other";
import { Dashboard, VisualizerGrid } from "./Dashboard";
import { __HPCC_VISUALIZATION, WUWidget } from "./WUWidget";

topoJsonFolder("https://unpkg.com/@hpcc-js/map@2.0.0/TopoJSON");
enableCache(true);

const HPCC_VIZBUNDLE = "HPCC-Visualizer";
const PERSIST = "persist";

//  ===========================================================================

export class WUDashboard {
    _espUrl: string;
    _espWorkunit: any;
    _wuWidgets: WUWidget[] = [];
    _wuWidgetMap = {};
    _wuDashSel = {};

    grid: VisualizerGrid;

    constructor(espUrl: string) {
        this._espUrl = espUrl;
        this._espWorkunit = createConnection(this._espUrl);
        this._wuWidgets = [];
        this._wuWidgetMap = {};
        this._wuDashSel = {};
    }

    resetPersist() {
        return this._espWorkunit.appData(HPCC_VIZBUNDLE, PERSIST, " ");
    }

    submitPersist() {
        if (this.grid) {
            const persistStr = Persist2.serialize(this.grid);
            this._espWorkunit.appData(HPCC_VIZBUNDLE, PERSIST, persistStr);
        }
    }

    fetchPersist() {
        return this._espWorkunit.appData(HPCC_VIZBUNDLE, PERSIST).then(function (persistStr: string) {
            if (persistStr) {
                const state = JSON.parse(persistStr);
                switch (state.__class) {
                    case "visualizer_Dashboard":
                        return Persist.deserializeFromObject(new Dashboard(), state);
                    case "visualizer_VisualizerGrid":
                        return Persist.deserializeFromObject(new VisualizerGrid(), state);
                    default:
                        return Persist.create(persistStr);
                }
            }
            return Promise.resolve(null);
        }).catch((e: Error) => {
            return Promise.resolve(null);
        });
    }

    fetchWUWidgets(): Promise<WUWidget[]> {
        return this._espWorkunit.results().then(function (results) {
            const promises: Array<Promise<WUWidget>> = [];
            results.filter(function (result) {
                return Utility.endsWith(result.name(), __HPCC_VISUALIZATION);
            }).forEach(function (result) {
                const wuWidget = new WUWidget(result);
                promises.push(wuWidget.resolve());
            });
            return Promise.all(promises);
        });
    }

    createGrid() {
        const context = this;
        return Promise.all([this.fetchPersist(), this.fetchWUWidgets()]).then(function (promises) {
            context.grid = promises[0];
            context._wuWidgets = [];
            context._wuWidgetMap = {};
            const metas: WUWidget[] = promises[1];

            if (!context.grid) {
                //  Check if its an instance of Grid
                if (metas.length === 1 && metas[0].widgetClass() === Dashboard) {
                    context.grid = metas[0].createWidget();
                    metas[0].widget(context.grid);
                    return metas[0].refreshData({}, context.grid.maxRowCount()).then(() => {
                        return context.grid;
                    });
                }
                context.grid = new VisualizerGrid();
            }

            //  Create Widgets  ---
            const maxColPos = Math.ceil(Math.sqrt(metas.length));
            const maxRowPos = Math.ceil(metas.length / maxColPos);
            const snappingColumns = (maxColPos + 1) * 3;
            const snappingRows = (maxRowPos + 1) * 3;
            context.grid
                .snappingColumns(snappingColumns)
                .snappingRows(snappingRows)
                ;
            metas.forEach(async function (wuWidget: WUWidget, i) {
                let widget = context.grid.getContent(wuWidget.id());
                if (!widget) {
                    let rowPos = 0;
                    let colPos = 0;
                    const cellDensity = 3;
                    widget = wuWidget.createWidget();
                    while (context.grid.getCell(rowPos * cellDensity, colPos * cellDensity) !== null) {
                        ++colPos;
                        if (colPos >= maxColPos) {
                            colPos = 0;
                            ++rowPos;
                        }
                    }
                    context.grid.setContent(rowPos * cellDensity, colPos * cellDensity, widget, null, cellDensity, cellDensity);
                }
                switch (widget.classID()) {
                    case "observable-md_ObservableMD":
                    case "observable-md_Observable":
                        const wu = await Workunit.attach({ baseUrl: `${context._espWorkunit._protocol}//${context._espWorkunit._host}` }, context._espWorkunit._wuid);
                        const results = await wu.fetchResults();
                        const plugins = {
                            wuid: () => wu.Wuid,
                            outputs: () => {
                                return results.map(r => {
                                    return {
                                        name: r.Name,
                                        count: r.Total,
                                        value: r.Value,
                                        logicalFile: r.LogicalFileName
                                    };
                                });
                            }
                        };
                        results.forEach(r => {
                            plugins[r.Name] = async () => {
                                return r.fetchRows();
                            }
                        });
                        widget.plugins(plugins);
                        break;
                    case "graph_Graph":
                        widget.on("vertex_click", function (this: Widget, row, col, sel) {
                            context.refreshFilters(this.id(), row, col, sel);
                        });
                        break;
                    default:
                        widget.on("click", function (this: Widget, row, col, sel) {
                            context.refreshFilters(this.id(), row, col, sel);
                        });
                }
                widget._wuMeta = wuWidget;
                wuWidget.widget(widget);
                context._wuWidgets.push(wuWidget);
                context._wuWidgetMap[wuWidget.id()] = wuWidget;
            });

            return context.grid;
        });
    }

    refresh() {
        this._wuWidgets.forEach(wuWidget => {
            wuWidget.refreshData(this._wuDashSel, this.grid.maxRowCount());
        });
    }

    refreshFilters(id, row, col, sel) {
        if (sel) {
            this._wuDashSel[id] = {
                row,
                col
            };
        } else {
            delete this._wuDashSel[id];
        }
        this._wuWidgets.forEach(wuWidget => {
            wuWidget.filteredBy().forEach(filter => {
                if (id === filter.source + __HPCC_VISUALIZATION) {
                    wuWidget.refreshData(this._wuDashSel, this.grid.maxRowCount());
                }
            });
        });
    }
}

//  ===========================================================================

export class BundleDermatology extends Dermatology {
    wuDashboard;
    _resetButton;

    constructor() {
        super();
    }

    toggleProperties() {
        const retVal = Dermatology.prototype.toggleProperties.apply(this, arguments);
        if (!this._showProperties) {
            this.wuDashboard.submitPersist();
        }
        return retVal;
    }

    _prevEspUrl;
    reset() {
        const context = this;
        this.wuDashboard.resetPersist().then(function (response) {
            cache({});
            delete context._prevEspUrl;
            context.render((w) => {
            });
        });
    }

    enter() {
        Dermatology.prototype.enter.apply(this, arguments);

        const context = this;
        this._resetButton = new Button()
            .id(this.id() + "_reset")
            .value("Reset")
            .on("click", function () {
                context.reset();
            })
            ;
        this._toolbar.widgets([this._resetButton, this._propsButton]);
    }

    update() {
        Dermatology.prototype.update.apply(this, arguments);
        if (this._prevEspUrl !== this.espUrl()) {
            this._prevEspUrl = this.espUrl();
            if (this.espCache()) {
                cache(JSON.parse(this.espCache()));
            }

            const context = this;
            this.wuDashboard = new WUDashboard(this.espUrl());
            this.wuDashboard.createGrid().then(function (grid) {
                context
                    .widget(grid)
                    .render(function (w) {
                        context.wuDashboard.refresh();
                    })
                    ;
            });
        }
    }
}
BundleDermatology.prototype._class += " BundleDermatology";

export interface BundleDermatology {
    espUrl(): string;
    espUrl(_: string): this;
    espCache(): string;
    espCache(_: string): this;
}

BundleDermatology.prototype.publish("espUrl", null, "string", "ESP Url");
BundleDermatology.prototype.publish("espCache", null, "string", "ESP Cache");
