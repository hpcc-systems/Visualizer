const pkg = require("../package.json");
const fs = require("fs");

let paths = [];
let debugPaths = [];
for (const key in pkg.dependencies) {
    const depPkg = require(`../node_modules/${key}/package.json`);
    const version = (pkg.dependencies[key]).split("^").join("").split("~").join("");
    const main = (depPkg.unpkg || depPkg.main).split(".js").join("");
    const hpccMain = main.split(".min").join("");
    paths.push(`    "${key}": "https://cdn.jsdelivr.net/npm/${key}@${version}/${main}"`);
    if (key.indexOf("@hpcc-js") >= 0) {
        const hpccFolder = key.replace("@hpcc-js", "hpcc-js/packages");
        debugPaths.push(`    "${key}": "../../${hpccFolder}/${hpccMain}"`);
    } else {
        debugPaths.push(`    "${key}": "../node_modules/${key}/${main}"`);
    }
}

fs.writeFile('./res/paths.js', `\
var paths = {
${paths.join(",\n")}
};

var debugPaths = {
${debugPaths.join(",\n")}
};
`, function (err) {
    if (err) return console.log(err);
});
