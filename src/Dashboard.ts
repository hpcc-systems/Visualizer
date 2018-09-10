import { Column } from "@hpcc-js/chart";
import { Widget } from "@hpcc-js/common";
import { Result } from "@hpcc-js/comms";
import { Table } from "@hpcc-js/dgrid";
import { Grid } from "@hpcc-js/layout";

export class VisualizerGrid extends Grid {
}
VisualizerGrid.prototype._class += " visualizer_VisualizerGrid";

export interface VisualizerGrid {
    maxRowCount(): number;
    maxRowCount(_: number): this;
}

VisualizerGrid.prototype.publish("maxRowCount", 10000, "number");

export class Dashboard extends VisualizerGrid {

    _filter: { [fieldid: string]: string } = {};
    _table = new Table();

    update(domNode, element) {
        super.update(domNode, element);
    }

    render(callback?: (w: Widget) => void): this {
        if (this._renderCount === 0) {
            const gridColCount = this.data().length;
            this.data().forEach((profileResult, idx) => {
                const fieldID = profileResult[0];
                const column = new Column()
                    .columns(["Field ID", "Row Count"])
                    .data(profileResult[2].map(vrow => [vrow.value, vrow.rowcount]))
                    .on("click", (row, col, sel) => {
                        if (sel) {
                            this._filter[fieldID] = row["Field ID"];
                        } else {
                            delete this._filter[fieldID];
                        }
                        this.refreshFilter();
                    })
                    ;
                this.setContent(0, idx, column, `${profileResult[0]} (${profileResult[1]})`
                );
            });
            this.setContent(gridColCount ? 1 : 0, 0, this._table, "", 2, gridColCount);
            this.refreshFilter();
        }
        return super.render.apply(this, arguments);
    }

    refreshFilter() {
        const result = Result.attach({ baseUrl: this.baseUrl() }, this.logicalFile(), undefined as any);
        result.fetchRows(0, this.maxRowCount(), false, this._filter).then(rows => {
            const columns: string[] = [];
            const columnIdx = {};
            const data = rows.map((row, rowIdx) => {
                const retVal: any[][] = [];
                if (rowIdx === 0) {
                    Object.keys(row).forEach((key, idx) => {
                        columns.push(key);
                        columnIdx[key] = idx;
                    });
                }
                Object.keys(row).forEach((key) => {
                    retVal[columnIdx[key]] = row[key];
                });
                return retVal;
            });
            this._table
                .columns(columns)
                .data(data)
                .render()
                ;
        });
    }

    click(row, col, sel) {
    }
}
Dashboard.prototype._class += " visualizer_Dashboard";

export interface Dashboard {
    baseUrl(): string;
    baseUrl(_: string): this;
    logicalFile(): string;
    logicalFile(_: string): this;
}

Dashboard.prototype.publish("baseUrl", null, "string");
Dashboard.prototype.publish("logicalFile", null, "string");
