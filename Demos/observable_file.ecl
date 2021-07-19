EXPORT observable_file := '# Observerable MD\n' + 
'_Observable MD, is an extended version of [Markdown](https://www.markdownguide.org/getting-started/) which includes an interpreted version of the [Observable Runtime](https://github.com/observablehq/runtime).\n' + 
'This allows the author to create detailed and interactive documents and is compatible with all the examples located at [Observable HQ](https://observablehq.com/explore)._\n' + 
'\n' + 
'## Variables\n' + 
'_This document is initialised with the following variables_\n' + 
'* **wuid**:  The current workunit ID (${wuid}).\n' + 
'* **outputs**:  An array of the current workunit ouputs meta information (**name**, **count**, **value**, **logicalFile**).\n' + 
'* **NAMED_OUTPUT**:  For each output the content can be accessed by simply referencing its name.\n' + 
'---\n' + 
'## Meta Information\n' + 
'This ${wuid} has the following outputs:  \n' + 
'```\n' + 
'Inputs.table(outputs);\n' + 
'```\n' + 
'---\n' + 
'## my_data\n' + 
'Viewing the contents of an output in tabular form is just a matter of feeding it into `Input.table(my_data)`:\n' + 
'```\n' + 
'Inputs.table(my_data);\n' + 
'```\n' + 
'\n' + 
'_(See [Observable Inputs.table](https://observablehq.com/@observablehq/inputs) for more information)_\n' + 
'\n' + 
'---\n' + 
'## Plotting order_quantity v profit\n' + 
'Viewing the contents of an output in a chart can be achieved by using the builtin Plot library:\n' + 
'```\n' + 
'Swatches({color: d3.scaleOrdinal(my_data.map(d => d.order_priority).sort(), d3.schemeTableau10)});\n' + 
'Plot.dot(my_data, {x: "order_quantity", y:"profit", stroke: "order_priority"}).plot()\n' + 
'```\n' + 
'_(See [Observable Plot](https://observablehq.com/@observablehq/plot) for more information)_\n' + 
'\n' + 
'```\n' + 
'// # Dependencies\n' + 
'import {swatches as Swatches} from "@d3/color-legend";\n' + 
'```\n' + 
'\n' + 
'';
