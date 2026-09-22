import fs from "node:fs/promises";

const config = {
  supabaseUrl:
    process.env.NEXT_PUBLIC_SUPABASE_URL ||
    process.env.PUBLIC_SUPABASE_URL ||
    process.env.SUPABASE_URL ||
    "",
  supabaseAnonKey:
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
    process.env.PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
    process.env.PUBLIC_SUPABASE_ANON_KEY ||
    process.env.SUPABASE_ANON_KEY ||
    "",
  adminEmail: "maojingling25@gmail.com",
};

if (!config.supabaseUrl || !config.supabaseAnonKey) {
  throw new Error(
    "Missing public Supabase configuration. Set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY.",
  );
}

await fs.writeFile(
  "public-config.js",
  `window.SITE_CONFIG = ${JSON.stringify(config, null, 2)};\n`,
  "utf8",
);
