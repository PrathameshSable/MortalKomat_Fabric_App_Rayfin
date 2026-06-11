import query from "./matchup-matrix.dax?raw";

const connection = "kombatModel";

export function matchupMatrixQuery() {
    return {
        connection,
        query,
    };
}
