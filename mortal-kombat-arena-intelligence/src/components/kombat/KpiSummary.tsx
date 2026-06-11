import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { kpiSummaryQuery } from "@/queries/kombat";

function formatNumber(value: unknown) {
    return Number(value ?? 0).toLocaleString();
}

function formatPercent(value: unknown) {
    return `${(Number(value ?? 0) * 100).toFixed(1)}%`;
}

export function KpiSummary() {
    const { connection, query } = kpiSummaryQuery();

    const { data, isLoading, error } = useSemanticModelQuery({
        connection,
        query,
    });

    if (isLoading) {
        return <div className="mk-loading">Loading Kombat KPIs...</div>;
    }

    const result = data as any;

    if (error || result?.status === "error") {
        return <div className="mk-error">Unable to load KPIs.</div>;
    }

    if (!result || result.status !== "success") {
        return null;
    }

    const row = result.table.rows[0] ?? [];

    const cards = [
        { label: "Total Matches", value: formatNumber(row[0]), icon: "⚔" },
        { label: "Total XP", value: formatNumber(row[5]), icon: "✦" },
        { label: "Total Score", value: formatNumber(row[7]), icon: "♛" },
        { label: "KOs", value: formatNumber(row[9]), icon: "☠" },
        { label: "Win Rate", value: formatPercent(row[4]), icon: "◈" },
        { label: "Fatalities", value: formatNumber(row[11]), icon: "🔥" },
    ];

    return (
        <section className="mk-kpi-grid">
            {cards.map((card) => (
                <div className="mk-kpi-card mk-kpi-card-premium" key={card.label}>
                    <div className="mk-kpi-icon">{card.icon}</div>
                    <span>{card.label}</span>
                    <strong>{card.value}</strong>
                </div>
            ))}
        </section>
    );
}
