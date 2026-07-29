//-----------------------------------------------------------------------
// <copyright company="Microsoft Corporation">
//        Copyright (c) Microsoft Corporation.  All rights reserved.
//        Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>
//-----------------------------------------------------------------------

import { createContext, useContext } from "react";
import type { OpaqueSession } from "@microsoft/rayfin-auth";

export interface AuthContextValue {
    /** The current Rayfin session, or `null` if not authenticated. */
    session: OpaqueSession | null;
    /** Convenience accessor for `session?.isAuthenticated ?? false`. */
    isAuthenticated: boolean;
    /** True while the embedded auth handoff is in flight. */
    isLoading: boolean;
    /** Last error from the embedded auth flow, if any. */
    error: Error | null;
    /**
     * True when running inside a Fabric extension iframe. Combined with
     * `isAuthenticated`, this distinguishes "opened standalone" (expected,
     * unsupported) from "embedded but the handoff failed" (a real fault).
     */
    isEmbedded: boolean;
    /** Rayfin backend base URL, shown in the handoff-failure diagnostics. */
    apiUrl: string;
}

export const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function useAuth(): AuthContextValue {
    const context = useContext(AuthContext);
    if (context === undefined) {
        throw new Error("useAuth must be used within an AuthProvider");
    }
    return context;
}
