import { useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { AppNavigation, type AppTab, type AppTheme } from "./AppNavigation";
import { HomeLanding } from "./HomeLanding";
import { DashboardTab } from "./DashboardTab";
import { FighterExplorer } from "./FighterExplorer";
import { CompareTab } from "./CompareTab";

export function MkAppShell() {
    const [activeTab, setActiveTab] = useState<AppTab>("home");
    const [activeTheme, setActiveTheme] = useState<AppTheme>("dark");

    const toggleTheme = () => {
        setActiveTheme((current) => (current === "dark" ? "light" : "dark"));
    };

    return (
        <main
            className={`mk-app ${activeTab === "home" ? "mk-app--home" : ""}`}
            data-theme={activeTheme}
        >
            <AppNavigation
                activeTab={activeTab}
                activeTheme={activeTheme}
                onChange={setActiveTab}
                onToggleTheme={toggleTheme}
            />

            <AnimatePresence mode="wait">
                <motion.div
                    key={activeTab}
                    className="mk-page-host"
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -6 }}
                    transition={{ duration: 0.28, ease: [0.22, 1, 0.36, 1] }}
                >
                    {activeTab === "home" ? <HomeLanding onNavigate={setActiveTab} /> : null}
                    {activeTab === "dashboard" ? <DashboardTab /> : null}
                    {activeTab === "roster" ? <FighterExplorer /> : null}
                    {activeTab === "compare" ? <CompareTab /> : null}
                </motion.div>
            </AnimatePresence>
        </main>
    );
}
