import { useEffect, useRef, useState } from "react";

/**
 * "Ask Skyfield" — a chat overlay backed by a Microsoft Copilot Studio agent that
 * has a **Fabric data agent** connected to it (grounded on the same Eventhouse /
 * `flightsModel` data the globe uses). See COPILOT_DATA_AGENT_SETUP.md.
 *
 * We embed the Bot Framework Web Chat canvas from the CDN (so we don't bloat the
 * bundle), fetch a Direct Line token from the agent's token endpoint, and theme
 * the canvas to match the app. Set VITE_COPILOT_TOKEN_ENDPOINT to enable it.
 */

declare global {
  interface Window {
    WebChat?: {
      createDirectLine: (opts: { token?: string; secret?: string }) => unknown;
      renderWebChat: (props: Record<string, unknown>, element: HTMLElement) => void;
    };
  }
}

const WEBCHAT_CDN = "https://cdn.botframework.com/botframework-webchat/latest/webchat.js";
const TOKEN_ENDPOINT = import.meta.env.VITE_COPILOT_TOKEN_ENDPOINT;

// Web Chat style options tuned to Skyfield's dark glassmorphism theme.
const STYLE_OPTIONS = {
  backgroundColor: "transparent",
  bubbleBackground: "rgba(12, 26, 46, 0.85)",
  bubbleTextColor: "#e8f1ff",
  bubbleBorderColor: "rgba(90, 150, 220, 0.25)",
  bubbleBorderRadius: 12,
  bubbleFromUserBackground: "rgba(58, 160, 255, 0.18)",
  bubbleFromUserTextColor: "#e8f1ff",
  bubbleFromUserBorderColor: "rgba(58, 160, 255, 0.5)",
  bubbleFromUserBorderRadius: 12,
  sendBoxBackground: "rgba(255, 255, 255, 0.06)",
  sendBoxTextColor: "#e8f1ff",
  sendBoxPlaceholderColor: "#8aa3c4",
  sendBoxBorderTop: "1px solid rgba(90, 150, 220, 0.25)",
  accent: "#3aa0ff",
  primaryFont: '"Saira", "Segoe UI", system-ui, sans-serif',
  botAvatarInitials: "SK",
  userAvatarInitials: "You",
  botAvatarBackgroundColor: "rgba(58, 160, 255, 0.18)",
  hideUploadButton: true,
  timestampColor: "#8aa3c4",
};

let webChatLoader: Promise<void> | null = null;
function loadWebChat(): Promise<void> {
  if (window.WebChat) return Promise.resolve();
  if (!webChatLoader) {
    webChatLoader = new Promise<void>((resolve, reject) => {
      const s = document.createElement("script");
      s.src = WEBCHAT_CDN;
      s.async = true;
      s.onload = () => resolve();
      s.onerror = () => {
        webChatLoader = null;
        reject(new Error("Failed to load the Web Chat script (CDN blocked?)"));
      };
      document.head.appendChild(s);
    });
  }
  return webChatLoader;
}

type Status = "idle" | "loading" | "ready" | "error" | "unconfigured";

export function ChatOverlay() {
  const [open, setOpen] = useState(false);
  const [status, setStatus] = useState<Status>("idle");
  const [error, setError] = useState<string | null>(null);
  const hostRef = useRef<HTMLDivElement>(null);
  const startedRef = useRef(false);

  // Lazily boot Web Chat the first time the panel is opened.
  useEffect(() => {
    if (!open || startedRef.current) return;
    if (!TOKEN_ENDPOINT) {
      setStatus("unconfigured");
      return;
    }
    startedRef.current = true;
    setStatus("loading");
    (async () => {
      try {
        await loadWebChat();
        const res = await fetch(TOKEN_ENDPOINT);
        if (!res.ok) throw new Error(`Token endpoint returned ${res.status}`);
        const data = (await res.json()) as { token?: string };
        if (!data.token) throw new Error("No token in the endpoint response");
        if (!hostRef.current || !window.WebChat) return;
        const directLine = window.WebChat.createDirectLine({ token: data.token });
        window.WebChat.renderWebChat(
          { directLine, styleOptions: STYLE_OPTIONS, locale: "en-US" },
          hostRef.current,
        );
        setStatus("ready");
      } catch (e) {
        setError(e instanceof Error ? e.message : String(e));
        setStatus("error");
        startedRef.current = false; // allow a retry on next open
      }
    })();
  }, [open]);

  return (
    <>
      <button
        className={`chat-fab${open ? " chat-fab--open" : ""}`}
        onClick={() => setOpen((v) => !v)}
        title={open ? "Close assistant" : "Ask Skyfield"}
        aria-label="Ask Skyfield"
      >
        {open ? "✕" : "✦"}
      </button>

      {/* Kept mounted (hidden via CSS) so the conversation survives close/reopen. */}
      <div className={`chat-panel${open ? " chat-panel--open" : ""}`}>
        <div className="chat-head">
          <span className="chat-title">
            <span className="chat-dot" /> Ask Skyfield
          </span>
          <button className="chat-close" onClick={() => setOpen(false)} aria-label="Close">
            ✕
          </button>
        </div>

        {status === "unconfigured" && (
          <div className="chat-msg">
            <p>The assistant isn't wired up yet.</p>
            <p className="hint">
              Set <code>VITE_COPILOT_TOKEN_ENDPOINT</code> to your Copilot Studio agent's
              token endpoint, then reload. The agent should have a <b>Fabric data agent</b>{" "}
              connected — see <code>COPILOT_DATA_AGENT_SETUP.md</code>.
            </p>
          </div>
        )}
        {status === "loading" && (
          <div className="chat-msg">
            <p className="hint">Connecting to the agent…</p>
          </div>
        )}
        {status === "error" && (
          <div className="chat-msg">
            <p>Couldn't reach the assistant.</p>
            <p className="hint">{error}</p>
          </div>
        )}

        <div
          ref={hostRef}
          className="chat-host"
          style={{ display: status === "ready" ? "block" : "none" }}
        />

        <div className="chat-foot">
          Grounded on live Fabric flight data · ask “busiest country?”, “how many airborne?”
        </div>
      </div>
    </>
  );
}
