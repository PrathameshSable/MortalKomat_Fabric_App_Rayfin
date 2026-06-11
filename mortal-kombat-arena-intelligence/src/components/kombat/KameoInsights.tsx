import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { kameoInsightsQuery } from "@/queries/kombat";

function formatNumber(value: unknown) {
    return Number(value ?? 0).toLocaleString();
}

function formatPercent(value: unknown) {
    return `${(Number(value ?? 0) * 100).toFixed(1)}%`;
}

export function KameoInsights() {
    const { connection, query } = kameoInsightsQuery();

    const { data, isLoading, error } = useSemanticModelQuery({
        connection,
        query,
    });

    const result = data as any;

    if (isLoading) {
        return <div className="mk-loading">Loading Kameo insights...</div>;
    }

    if (error || result?.status === "error") {
        return <div className="mk-error">Unable to load Kameo insights.</div>;
    }

    if (!result || result.status !== "success") {
        return null;
    }

    const rows = result.table.rows as unknown[][];

    return (
        <section className="mk-panel">
            <div className="mk-section-header" style={{ marginTop: 0 }}>
                <span>Kameo Intelligence</span>
                <h2>Best Assist Fighters</h2>
            </div>

            <table className="mk-table">
                <thead>
                    <tr>
                        <th>Kameo</th>
                        <th>Group</th>
                        <th>Element</th>
                        <th>Assist</th>
                        <th>Matches</th>
                        <th>Win Rate</th>
                    </tr>
                </thead>
                <tbody>
                    {rows.slice(0, 10).map((row) => (
                        <tr key={String(row[0])}>
                            <td>{String(row[0])}</td>
                            <td>{String(row[1])}</td>
                            <td>{String(row[2])}</td>
                            <td>{String(row[3])}</td>
                            <td>{formatNumber(row[5])}</td>
                            <td>{formatPercent(row[7])}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </section>
    );
}
