import { useEffect, useMemo, useRef, useState } from "react";

type FighterPickerProps = {
    label: string;
    value: string;
    options: string[];
    onChange: (value: string) => void;
};

export function FighterPicker({ label, value, options, onChange }: FighterPickerProps) {
    const [isOpen, setIsOpen] = useState(false);
    const [search, setSearch] = useState("");
    const rootRef = useRef<HTMLDivElement | null>(null);

    const filteredOptions = useMemo(() => {
        const searchText = search.trim().toLowerCase();

        if (!searchText) {
            return options;
        }

        return options.filter((option) => option.toLowerCase().includes(searchText));
    }, [options, search]);

    useEffect(() => {
        function handlePointerDown(event: PointerEvent) {
            if (!rootRef.current) {
                return;
            }

            if (!rootRef.current.contains(event.target as Node)) {
                setIsOpen(false);
            }
        }

        window.addEventListener("pointerdown", handlePointerDown);

        return () => {
            window.removeEventListener("pointerdown", handlePointerDown);
        };
    }, []);

    return (
        <div className="mk-fighter-picker" ref={rootRef}>
            <label>{label}</label>

            <button
                type="button"
                className="mk-fighter-picker__button"
                onClick={() => setIsOpen((current) => !current)}
            >
                <span>{value || "Select fighter"}</span>
                <strong>⌄</strong>
            </button>

            {isOpen ? (
                <div className="mk-fighter-picker__menu">
                    <input
                        value={search}
                        onChange={(event) => setSearch(event.target.value)}
                        placeholder="Search fighter..."
                        autoFocus
                    />

                    <div className="mk-fighter-picker__list">
                        {filteredOptions.map((option) => (
                            <button
                                key={option}
                                type="button"
                                className={option === value ? "is-selected" : ""}
                                onClick={() => {
                                    onChange(option);
                                    setIsOpen(false);
                                    setSearch("");
                                }}
                            >
                                {option}
                            </button>
                        ))}
                    </div>
                </div>
            ) : null}
        </div>
    );
}
