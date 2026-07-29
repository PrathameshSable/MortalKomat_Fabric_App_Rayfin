//-----------------------------------------------------------------------
// <copyright company="Microsoft Corporation">
//        Copyright (c) Microsoft Corporation.  All rights reserved.
//        Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>
//-----------------------------------------------------------------------

import { type ReactNode } from "react";

import { useAuth } from "@/hooks/auth.context";

interface AuthGateProps {
    children: ReactNode;
}

export function AuthGate({ children }: AuthGateProps) {
    const { isLoading, isAuthenticated, isEmbedded, apiUrl } = useAuth();

    if (isLoading) {
        return (
            <div className="flex min-h-screen items-center justify-center bg-background">
                <div className="text-sm text-muted-foreground">
                    Connecting to Fabric…
                </div>
            </div>
        );
    }

    // Embedded but unauthenticated means the postMessage handoff ran and
    // failed — the SDK swallows that error and returns a null session, so
    // without this branch a broken backend looks identical to opening the
    // app standalone. The usual cause is a stale `VITE_RAYFIN_API_URL`
    // baked into the bundle at build time, which goes dead when the
    // workspace moves to a new Fabric capacity. Fix: re-run `npx rayfin up`.
    if (!isAuthenticated && isEmbedded) {
        return (
            <div className="flex min-h-screen items-center justify-center bg-background p-4">
                <div className="w-full max-w-md text-center">
                    <h2 className="mb-2 text-lg font-semibold text-foreground">
                        Couldn't sign in to Fabric
                    </h2>
                    <p className="mb-4 text-sm text-muted-foreground">
                        The app is running inside Fabric, but the authentication
                        handoff with the Rayfin backend failed. The backend URL
                        below is baked in at build time — if it no longer resolves,
                        redeploy with <code className="font-mono">npx rayfin up</code>.
                    </p>
                    <pre className="mb-4 max-h-32 overflow-auto rounded border border-border bg-muted p-3 text-left text-xs break-all whitespace-pre-wrap text-muted-foreground">
                        {apiUrl || "VITE_RAYFIN_API_URL is not set"}
                    </pre>
                    <p className="text-xs text-muted-foreground">
                        See the browser console for the underlying
                        <span className="font-mono"> [FabricAuth:initEmbedded] </span>
                        warning.
                    </p>
                </div>
            </div>
        );
    }

    if (!isAuthenticated) {
        return (
            <div className="flex min-h-screen items-center justify-center bg-background p-4">
                <div className="w-full max-w-md text-center">
                    <h2 className="mb-2 text-lg font-semibold text-foreground">
                        Can't open this app outside Fabric
                    </h2>
                    <p className="mb-4 text-sm text-muted-foreground">
                        Opening apps connected to semantic models outside of the Fabric portal is not supported at this time.
                    </p>
                </div>
            </div>
        );
    };

    return <>{children}</>;
}