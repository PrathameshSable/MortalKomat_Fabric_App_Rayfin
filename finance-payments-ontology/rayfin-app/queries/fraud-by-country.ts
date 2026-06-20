import query from "./fraud-by-country.dax?raw";

const connection = "bankModel";

export function fraudByCountryQuery() {
    return { connection, query };
}
