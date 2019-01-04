import { Line, Scatter, XYAxis } from "@hpcc-js/chart";

export class ScatterLine extends XYAxis {

    _scatter = new Scatter();
    _line = new Line()
        .interpolate("catmullRom")
        .pointShape("circle")
        .pointSize(1)
        ;

    constructor() {
        super();
        this
            .xAxisGuideLines_default(true)
            .yAxisGuideLines_default(true)
            .layers([this._scatter, this._line])
            ;
    }
    update(domNode, element) {
        this._scatter
            .paletteID(this.paletteID())
            .columns([this.columns()[1]])
            ;
        this._line
            .paletteID(this.paletteID())
            .columns([this.columns()[2]])
            ;
        super.update(domNode, element);
    }
}
ScatterLine.prototype._class += " visualizer_ScatterLine";

export interface ScatterLine {
    paletteID(): string;
    paletteID(_: string): this;
}

ScatterLine.prototype.publish("paletteID", "default", "string");
ScatterLine.prototype.publishProxy("line_interpolate", "_line", "interpolate");
ScatterLine.prototype.publishProxy("line_pointShape", "_line", "pointShape");
ScatterLine.prototype.publishProxy("line_pointSize", "_line", "pointSize");
