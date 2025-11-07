import fs from "node:fs";
import https from "node:https";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const BANG_URL = "https://raw.githubusercontent.com/kagisearch/bangs/refs/heads/main/data/bangs.json";
const BANG_FILE_PATH = path.join(__dirname, "..", "Shared (Extension)", "Resources", "kagi-bangs.json");

/**
 * Fetch data from Kagi
 */
function fetchBangData() {
  return new Promise((resolve, reject) => {
    console.log("Fetching bang data from Kagi...");

    https
      .get(BANG_URL, (res) => {
        let data = "";

        res.on("data", (chunk) => {
          data += chunk;
        });

        res.on("end", () => {
          try {
            // Parse the JSON array from the response
            const bangData = JSON.parse(data);
            console.log(`Fetched ${bangData.length} bangs from Kagi`);
            resolve(bangData);
          } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            reject(new Error(`Failed to parse JSON: ${errorMessage}`));
          }
        });
      })
      .on("error", (error) => {
        reject(new Error(`HTTP request failed: ${error.message}`));
      });
  });
}

/**
 * Convert Kagi bang format to our format
 * Kagi format: {"c":"Reference","d":"en.wikipedia.org","r":0,"s":"Wikipedia","sc":"Encyclopedia","t":"w","u":"https://en.wikipedia.org/wiki/{{{s}}}","ts":["wiki","wikipedia"]}
 * Our format: {t: "w", s: "Wikipedia", u: "https://en.wikipedia.org/wiki/{{{s}}}", d: "en.wikipedia.org", ts: ["wiki","wikipedia"]}
 */
function convertBangFormat(bangs) {
  console.log("Converting bang format...");

  return bangs.map((bang) => ({
    t: bang.t, // trigger
    s: bang.s, // name/description
    u: bang.u.replace("{{{s}}}", "%s"), // url template, replace the {{{s}}} from kagi with our %s placeholder
    d: bang.d, // domain
    ts: bang.ts ?? [], // additional triggers (optional)
    cat: bang.c,
    subCat: bang.sc,
  }));
}

/**
 * Main function
 */
async function main() {
  try {
    console.log("Starting bang list update...");

    // Fetch data from Kagi
    const bangs = await fetchBangData();

    // Convert to our format
    const convertedBangs = convertBangFormat(bangs);

    await Bun.write(BANG_FILE_PATH, JSON.stringify(convertedBangs, null, 2))

    console.log(`✅ Successfully updated bang list with ${convertedBangs.length} entries`);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error("❌ Error updating bang list:", errorMessage);
    process.exit(1);
  }
}

// Run the script
main();
