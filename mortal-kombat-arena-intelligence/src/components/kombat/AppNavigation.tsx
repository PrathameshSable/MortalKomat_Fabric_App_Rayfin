export type AppTab = "home" | "dashboard" | "roster" | "compare";
export type AppTheme = "dark" | "light";

type AppNavigationProps = {
    activeTab: AppTab;
    activeTheme: AppTheme;
    onChange: (tab: AppTab) => void;
    onToggleTheme: () => void;
};

const navItems: Array<{ id: AppTab; label: string; description: string }> = [
    { id: "home", label: "Home", description: "Enter the arena" },
    { id: "dashboard", label: "Command Center", description: "Executive KPIs" },
    { id: "roster", label: "Roster", description: "Choose your fighter" },
    { id: "compare", label: "Compare", description: "Fighter vs fighter" },
];

export function AppNavigation({
    activeTab,
    activeTheme,
    onChange,
    onToggleTheme,
}: AppNavigationProps) {
    return (
        <header className="mk-top-nav">
            <button type="button" className="mk-nav-brand" onClick={() => onChange("home")}>
                <img
                    src="/assets/branding/mk-logo.png"
                    alt="Mortal Kombat"
                    className="mk-brand-logo"
                    onError={(event) => {
                        event.currentTarget.style.display = "none";
                    }}
                />

                <span className="mk-brand-text">
                    <strong>Arena Intelligence</strong>
                    <em>Microsoft Fabric + Rayfin</em>
                </span>
            </button>

            <nav className="mk-nav-tabs" aria-label="App navigation">
                {navItems.map((item) => (
                    <button
                        key={item.id}
                        type="button"
                        className={activeTab === item.id ? "is-active" : ""}
                        onClick={() => onChange(item.id)}
                    >
                        <strong>{item.label}</strong>
                        <span>{item.description}</span>
                    </button>
                ))}
            </nav>

            <button type="button" className="mk-theme-toggle" onClick={onToggleTheme}>
                {activeTheme === "dark" ? "Light Mode" : "Dark Mode"}
            </button>
        </header>
    );
}
