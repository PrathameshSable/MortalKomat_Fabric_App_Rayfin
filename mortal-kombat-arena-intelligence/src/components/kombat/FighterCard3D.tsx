import { useState } from "react";
import type { CSSProperties } from "react";
import type { FighterRow } from "./types";
import { FighterShowcaseVisual } from "./FighterShowcaseVisual";

type FighterCard3DProps = {
    fighter: FighterRow;
    isSelected?: boolean;
    onSelect: () => void;
};

export function FighterCard3D({ fighter, isSelected = false, onSelect }: FighterCard3DProps) {
    const [isHovering, setIsHovering] = useState(false);

    const style = {
        "--fighter-primary": fighter.primaryColor || "#ff5a1f",
        "--fighter-secondary": fighter.secondaryColor || "#120705",
    } as CSSProperties;

    return (
        <button
            type="button"
            className={`mk-fighter-card${isSelected ? " is-selected" : ""}${isHovering ? " is-hovering" : ""}`}
            onClick={onSelect}
            onMouseEnter={() => setIsHovering(true)}
            onMouseLeave={() => setIsHovering(false)}
            style={style}
            aria-label={`View profile for ${fighter.fighterName}`}
        >
            <div className="mk-fighter-card__glow" />
            <div className="mk-fighter-card__flame-ring" />

            <div className="mk-fighter-card__meta">
                <span className="mk-pill">{fighter.rosterGroup}</span>
                <strong className="mk-pill">{fighter.element}</strong>
            </div>

            <div className="mk-fighter-card__image-wrap">
                <FighterShowcaseVisual
                    fighterName={fighter.fighterName}
                    imagePath={fighter.fullBodyImagePath}
                    isActive={isHovering || isSelected}
                    className="mk-fighter-card__image"
                    mode="card"
                />
            </div>

            <div className="mk-fighter-card__content">
                <span className="mk-fighter-card__realm">{fighter.realm}</span>
                <h3>{fighter.fighterName}</h3>
                <p>
                    {fighter.combatStyle} · {fighter.difficulty}
                </p>

                <div className="mk-fighter-card__stats">
                    <div>
                        <span>XP</span>
                        <strong>{fighter.totalXP.toLocaleString()}</strong>
                    </div>
                    <div>
                        <span>KOs</span>
                        <strong>{fighter.totalKOs.toLocaleString()}</strong>
                    </div>
                    <div>
                        <span>Win</span>
                        <strong>{(fighter.winRate * 100).toFixed(1)}%</strong>
                    </div>
                    <div>
                        <span>Score</span>
                        <strong>{fighter.totalScore.toLocaleString()}</strong>
                    </div>
                </div>

                <div className="mk-fighter-card__footer">
                    <span>{fighter.matchesPlayed.toLocaleString()} matches</span>
                    <span>{isSelected ? "Selected" : isHovering ? "Cycle render" : "View profile"}</span>
                </div>
            </div>
        </button>
    );
}
