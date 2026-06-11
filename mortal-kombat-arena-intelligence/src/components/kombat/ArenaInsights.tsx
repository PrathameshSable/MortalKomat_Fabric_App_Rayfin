import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { arenaInsightsQuery } from "@/queries/kombat";

function formatNumber(value: unknown) {
    return Number(value ?? 0).toLocaleString();
}

function formatPercent(value: unknown) {
    return `${(Number(value ?? 0) * 100).toFixed(1)}%`;
}

export function ArenaInsights() {
    const { connection, query } = arenaInsightsQuery();

    const { data, isLoading, error } = useSemanticModelQuery({
        connection,
        query,
    });

    const result = data as any;

    if (isLoading) {
        return <div className="mk-loading">Loading arena insights...</div>;
    }

    if (error || result?.status === "error") {
        return <div className="mk-error">Unable to load arena insights.</div>;
    }

    if (!result || result.status !== "success") {
        return null;
    }

    const rows = result.table.rows as unknown[][];

    return (
        <section className="mk-panel">
            <div className="mk-section-header" style={{ marginTop: 0 }}>
                <span>Arena Intelligence</span>
                <h2>Battlefield Performance</h2>
            </div>

            <table className="mk-table">
                <thead>
                    <tr>
                        <th>Arena</th>
                        <th>Realm</th>
                        <th>Hazard</th>
                        <th>Matches</th>
                        <th>Win Rate</th>
                        <th>KOs</th>
                    </tr>
                </thead>
                <tbody>
                    {rows.slice(0, 8).map((row) => (
                        <tr key={String(row[0])}>
                            <td>{String(row[0])}</td>
                            <td>{String(row[1])}</td>
                            <td>{String(row[2])}</td>
                            <td>{formatNumber(row[4])}</td>
                            <td>{formatPercent(row[5])}</td>
                            <td>{formatNumber(row[6])}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </section>
    );
}
