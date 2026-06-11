import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { fighterProfileQuery } from "@/queries/kombat";
import type { FighterRow } from "./types";
import { FighterShowcaseVisual } from "./FighterShowcaseVisual";

type FighterProfilePanelProps = {
    fighter: FighterRow;
    onClose: () => void;
};

function formatNumber(value: unknown) {
    return Number(value ?? 0).toLocaleString();
}

function formatPercent(value: unknown) {
    return `${(Number(value ?? 0) * 100).toFixed(1)}%`;
}

export function FighterProfilePanel({ fighter, onClose }: FighterProfilePanelProps) {
    const { connection, query } = fighterProfileQuery(fighter.fighterName);

    const { data, isLoading, error } = useSemanticModelQuery({
        connection,
        query,
    });

    const result = data as any;
    const row = result?.status === "success" ? result.table.rows[0] ?? [] : [];

    return (
        <section className="mk-panel mk-profile-panel">
            <div className="mk-profile-toolbar">
                <div>
                    <span className="mk-eyebrow">Selected Fighter</span>
                    <h2>{fighter.fighterName}</h2>
                    <p>
                        {fighter.realm} · {fighter.element} · {fighter.combatStyle} · Rank #
                        {fighter.rank}
                    </p>
                </div>

                <button type="button" className="mk-profile-close" onClick={onClose}>
                    Close profile
                </button>
            </div>

            <div className="mk-profile-grid">
                <div className="mk-profile-image">
                    <FighterShowcaseVisual
                        fighterName={fighter.fighterName}
                        imagePath={fighter.fullBodyImagePath}
                        isActive
                        className="mk-profile-image__img"
                        fallbackClassName="mk-profile-image__fallback"
                        mode="profile"
                    />
                </div>

                <div>
                    {isLoading ? (
                        <div className="mk-loading">Loading fighter profile...</div>
                    ) : error || result?.status === "error" ? (
                        <div className="mk-error">Unable to load fighter profile.</div>
                    ) : (
                        <div className="mk-mini-grid">
                            <div className="mk-mini-stat">
                                <span>Matches</span>
                                <strong>{formatNumber(row[0])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Wins</span>
                                <strong>{formatNumber(row[1])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Losses</span>
                                <strong>{formatNumber(row[2])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Win Rate</span>
                                <strong>{formatPercent(row[3])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Total XP</span>
                                <strong>{formatNumber(row[4])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Score</span>
                                <strong>{formatNumber(row[6])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>KOs</span>
                                <strong>{formatNumber(row[8])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Fatalities</span>
                                <strong>{formatNumber(row[10])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Brutalities</span>
                                <strong>{formatNumber(row[11])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Damage Eff.</span>
                                <strong>{Number(row[13] ?? 0).toFixed(2)}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Max Combo</span>
                                <strong>{formatNumber(row[14])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Score Rank</span>
                                <strong>#{formatNumber(row[17])}</strong>
                            </div>
                        </div>
                    )}
                </div>
            </div>

            <div className="mk-profile-hint">
                Hover fighter cards to cycle available render images. Select another card to switch profile.
            </div>
        </section>
    );
}
