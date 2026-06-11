import { z } from "zod";

/**
 * Centralised, validated configuration. The process fails fast at startup if a
 * required variable is missing or malformed, so the rest of the code can treat
 * config as always-valid.
 */
const booleanish = z
  .string()
  .transform((v) => v.trim().toLowerCase())
  .pipe(z.enum(["true", "false"]))
  .transform((v) => v === "true");

const EnvSchema = z.object({
  PORT: z.coerce.number().int().positive().default(8080),
  LOG_LEVEL: z
    .enum(["fatal", "error", "warn", "info", "debug", "trace", "silent"])
    .default("info"),
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  CORS_ALLOWED_ORIGINS: z
    .string()
    .default("")
    .transform((v) =>
      v
        .split(",")
        .map((s) => s.trim())
        .filter(Boolean),
    ),

  // External REST API
  EXTERNAL_API_BASE_URL: z.string().url(),
  EXTERNAL_API_PATH: z.string().default("/"),
  EXTERNAL_API_KEY: z.string().optional(),
  INGEST_POLL_INTERVAL_MS: z.coerce.number().int().positive().default(2000),
  INGEST_POLL_ENABLED: booleanish.default("true"),

  // Eventstream (Event Hubs compatible custom-app endpoint)
  EVENTSTREAM_CONNECTION_STRING: z.string().min(1),
  EVENTSTREAM_BATCH_MAX_SIZE: z.coerce.number().int().positive().default(100),
  EVENTSTREAM_BATCH_MAX_WAIT_MS: z.coerce.number().int().positive().default(1000),

  // Eventhouse / KQL (optional)
  KUSTO_QUERY_URI: z.string().url().optional().or(z.literal("")),
  KUSTO_DATABASE: z.string().optional(),
  KUSTO_TABLE: z.string().default("LiveEvents"),
  AZURE_TENANT_ID: z.string().optional(),
  AZURE_CLIENT_ID: z.string().optional(),
  AZURE_CLIENT_SECRET: z.string().optional(),
});

export type AppConfig = z.infer<typeof EnvSchema> & {
  /** True when KQL read/write-back is fully configured. */
  kustoEnabled: boolean;
};

function load(): AppConfig {
  const parsed = EnvSchema.safeParse(process.env);
  if (!parsed.success) {
    const issues = parsed.error.issues
      .map((i) => `  • ${i.path.join(".") || "(root)"}: ${i.message}`)
      .join("\n");
    throw new Error(`Invalid environment configuration:\n${issues}`);
  }

  const env = parsed.data;
  const kustoEnabled = Boolean(
    env.KUSTO_QUERY_URI &&
      env.KUSTO_DATABASE &&
      env.AZURE_TENANT_ID &&
      env.AZURE_CLIENT_ID &&
      env.AZURE_CLIENT_SECRET,
  );

  return { ...env, kustoEnabled };
}

export const config = load();
