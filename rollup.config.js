import alias from 'rollup-plugin-alias';
import commonjs from 'rollup-plugin-commonjs';
import nodeResolve from 'rollup-plugin-node-resolve';
import postcss from "rollup-plugin-postcss";

const pkg = require("./package.json");

function externals(id) {
    return !!pkg.devDependencies[id];
}

function globals(id) {
    if (id.indexOf("@hpcc-js") === 0) {
        return id;
    }
    return undefined;
}

export default {
    input: "lib-es6/index",
    external: externals,
    output: {
        file: pkg.main,
        format: "amd",
        sourcemap: true,
        globals: globals,
        name: pkg.name
    },
    plugins: [
        alias({
        }),
        nodeResolve({
            preferBuiltins: true
        }),
        commonjs({
        }),
        postcss({
            extensions: [".css"]
        })
    ]
};
