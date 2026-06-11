import query from "./fighter-grid.dax?raw";

const connection = "kombatModel";

export function fighterGridQuery() {
    return {
        connection,
        query,
    };
}
