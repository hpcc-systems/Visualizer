function requireApp(require, callback) {
    "use strict";
    require(["d3", "src/composite/Dermatology", "src/common/Widget", "src/other/ESP", "src/layout/Grid", "src/other/Persist", "src/common/Utility", "src/composite/MegaChart", "src/form/Button"], function (d3, Dermatology, Widget, ESP, Grid, Persist, Utility, MegaChart, Button) {
        Dermatology = Dermatology.Dermatology || Dermatology;
        Widget = Widget.Widget || Widget;
        var __HPCC_VISUALIZATION = "__hpcc_visualization";
        var HPCC_VIZBUNDLE = "HPCC-Visualizer";
        var PERSIST = "persist";

        ESP.enableCache(true);

        //  ===================================================================
        function WUWidget(wuResult) {
            Widget.call(this);

            this._metaResult = wuResult;
            this._id = this._metaResult.name();
            this._columns = [];
            this._data = [];
        }
        WUWidget.prototype = Object.create(Widget.prototype);
        WUWidget.prototype.constructor = Widget;
        WUWidget.prototype._class += " WUWudget";

        WUWidget.prototype.publish("classID", null, "string", "ESP Url");
        WUWidget.prototype.publish("widgetClass", null, "object", "Widget Class Declaration");
        WUWidget.prototype.publish("widget", null, "object", "Widget Instance");
        WUWidget.prototype.publish("dataSource", null, "string", "Data Source");
        WUWidget.prototype.publish("resultName", null, "string", "Result Name");
        WUWidget.prototype.publish("mappings", null, "object", "Widget Mappings");
        WUWidget.prototype.publish("filteredBy", null, "object", "Widget Filter Properties");
        WUWidget.prototype.publish("properties", null, "object", "Widget Properties");

        WUWidget.prototype.createWidget = function () {
            var WidetClass = this.widgetClass();
            var widget = new WidetClass()
                .id(this.id())
                ;

            this.properties().forEach(function (property) {
                if (typeof (widget[property.key]) === "function") {
                    widget[property.key](property.value);
                }
            });
            return widget;
        };

        WUWidget.prototype.resolveWidget = function () {
            var context = this;
            return Utility.requireWidget(context.classID()).then(function (Widget) {
                context.widgetClass(Widget);
            });
        };

        WUWidget.prototype.resolve = function () {
            var context = this;
            return this._metaResult.query().then(function (result) {
                if (result && result.length) {
                    context
                        .classID(result[0].classid)
                        .mappings(result[0].mappings)
                        .filteredBy(result[0].filteredby)
                        .properties(result[0].properties)
                        .dataSource(result[0].datasource || context._metaResult.wuid())
                        .resultName(result[0].resultname)
                        ;
                }
                return context.resolveWidget().then(function () {
                    return context;
                });
            });
        };

        WUWidget.prototype.refreshData = function (selections) {
            var filterRequest = {};
            var isFiltered = false;
            var filterCount = 0;
            this.filteredBy().forEach(function (filter) {
                var selection = selections[filter.source + __HPCC_VISUALIZATION];
                if (selection) {
                    ++filterCount;
                    filter.mappings.forEach(function (mapping) {
                        filterRequest[mapping.value.toLowerCase()] = selection.row[mapping.key.toLowerCase()];
                    });
                }
                isFiltered = true;
            }, this);

            if (!isFiltered || filterCount > 0) {
                var context = this;
                var dataResult = ESP.createResult(this._metaResult.url(), this.dataSource(), this.resultName());
                dataResult.query(null, filterRequest).then(function (result) {
                    result = ESP.flattenResult(result, context.mappings());
                    context.widget()
                        .columns(result.columns)
                        .data(result.data)
                        .lazyRender()
                        ;
                });
            } else {
                this.widget()
                    .columns([])
                    .data([])
                    .lazyRender()
                    ;
            }
        };

        //  ===================================================================
        function WUDashboard(espUrl) {
            this._espUrl = espUrl;
            this._espWorkunit = ESP.createConnection(this._espUrl);
            this._wuWidgets = [];
            this._wuWidgetMap = {};
            this._wuDashSel = {};
        }

        WUDashboard.prototype.resetPersist = function () {
            return this._espWorkunit.appData(HPCC_VIZBUNDLE, PERSIST, " ");
        };

        WUDashboard.prototype.submitPersist = function () {
            if (this.grid) {
                var persistStr = Persist.serialize(this.grid);
                this._espWorkunit.appData(HPCC_VIZBUNDLE, PERSIST, persistStr);
            }
        };

        WUDashboard.prototype.fetchPersist = function () {
            return this._espWorkunit.appData(HPCC_VIZBUNDLE, PERSIST).then(function (persistStr) {
                if (persistStr) {
                    return Persist.create(persistStr);
                }
                return Promise.resolve(null);
            }).catch(function (e) {
                return Promise.resolve(null);
            });
        };

        WUDashboard.prototype.fetchWUWidgets = function () {
            var context = this;
            return this._espWorkunit.results().then(function (results) {
                var promises = [];
                results.filter(function (result) {
                    return Utility.endsWith(result.name(), __HPCC_VISUALIZATION);
                }).map(function (result) {
                    var wuWidget = new WUWidget(result);
                    promises.push(wuWidget.resolve());
                });
                return Promise.all(promises);
            });
        };

        WUDashboard.prototype.createGrid = function () {
            var context = this;
            return Promise.all([this.fetchPersist(), this.fetchWUWidgets()]).then(function (promises) {
                context.grid = promises[0];
                if (!context.grid) {
                    context.grid = new Grid();
                }

                //  Create Widgets  ---
                context._wuWidgets = [];
                context._wuWidgetMap = {};
                var metas = promises[1];
                var maxColPos = Math.ceil(Math.sqrt(metas.length));
                var maxRowPos = Math.ceil(metas.length / maxColPos);
                var snappingColumns = (maxColPos + 1) * 3;
                var snappingRows = (maxRowPos + 1) * 3;
                context.grid
                    .snappingColumns(snappingColumns)
                    .snappingRows(snappingRows)
                    ;
                metas.forEach(function (wuWidget, i) {
                    var widget = context.grid.getContent(wuWidget.id());
                    if (!widget) {
                        var rowPos = 0;
                        var colPos = 0;
                        var cellDensity = 3;
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
                    widget.on("click", function (row, col, sel) {
                        context.refreshFilters(this.id(), row, col, sel);
                    });
                    widget._wuMeta = wuWidget;
                    wuWidget.widget(widget);
                    context._wuWidgets.push(wuWidget);
                    context._wuWidgetMap[wuWidget.id] = wuWidget;
                });

                return context.grid;
            });
        };

        WUDashboard.prototype.refresh = function () {
            this._wuWidgets.forEach(function (wuWidget) {
                wuWidget.refreshData(this._wuDashSel);
            }, this);
        };

        WUDashboard.prototype.refreshFilters = function (id, row, col, sel) {
            if (sel) {
                this._wuDashSel[id] = {
                    row: row,
                    col: col
                };
            } else {
                delete this._wuDashSel[id];
            }
            this._wuWidgets.forEach(function (wuWidget) {
                wuWidget.filteredBy().forEach(function (filter) {
                    if (id === filter.source + __HPCC_VISUALIZATION) {
                        wuWidget.refreshData(this._wuDashSel);
                    }
                }, this);
            }, this);
        };

        //  ===================================================================
        function BundleDermatology() {
            Dermatology.call(this);
        }
        BundleDermatology.prototype = Object.create(Dermatology.prototype);
        BundleDermatology.prototype.constructor = BundleDermatology;
        BundleDermatology.prototype._class += " BundleDermatology";

        BundleDermatology.prototype.publish("espUrl", null, "string", "ESP Url");
        BundleDermatology.prototype.publish("espCache", null, "string", "ESP Cache");

        BundleDermatology.prototype.toggleProperties = function () {
            var retVal = Dermatology.prototype.toggleProperties.apply(this, arguments);
            if (!this._showProperties) {
                this.wuDashboard.submitPersist();
                this._downloadButton.disable(true);
            }
            return retVal;
        };

        BundleDermatology.prototype.reset = function () {
            var context = this;
            this.wuDashboard.resetPersist().then(function (response) {
                ESP.cache({});
                delete context._prevEspUrl;
                context._downloadButton.disable(false);
                context.render();
            });
        };

        BundleDermatology.prototype.download = function () {
            var cache = JSON.stringify(JSON.stringify(ESP.cache()));
            var context = this;
            d3.text(this.espUrl().replace(".html", ".css"), function (css) {
                d3.text(context.espUrl().replace(".html", ".js"), function (js) {
                    d3.text(context.espUrl(), function (html) {
                        Utility.downloadBlob("html", html
                            .replace(".showToolbar(true)", ".showToolbar(false)")
                            .replace(".espUrl(espUrl)", ".espUrl(\"" + context.espUrl() + "\")")
                            .replace(".espCache(\"\")", ".espCache(" + cache + ")")
                            .replace("<link href=\"./index.css\" rel=\"stylesheet\">", "<style>\n" + css + "</style>")
                            .replace("<script src=\"./index.js\">", "<script>")
                            .replace("<script>", "<script>\n" + js), "index.html");
                    });
                });
            });
        };

        BundleDermatology.prototype.enter = function () {
            Dermatology.prototype.enter.apply(this, arguments);

            var context = this;
            this._downloadButton = new Button()
                .id(this.id() + "_download")
                .value("Download")
                .on("click", function () {
                    context.download();
                })
                ;
            this._resetButton = new Button()
                .id(this.id() + "_reset")
                .value("Reset")
                .on("click", function () {
                    context.reset();
                })
                ;
            this._toolbar.widgets([this._resetButton, this._propsButton, this._downloadButton]);
        };

        BundleDermatology.prototype.update = function () {
            Dermatology.prototype.update.apply(this, arguments);
            if (this._prevEspUrl !== this.espUrl()) {
                this._prevEspUrl = this.espUrl();
                if (this.espCache()) {
                    ESP.cache(JSON.parse(this.espCache()));
                }

                var context = this;
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
        };

        callback(BundleDermatology);
    });
}