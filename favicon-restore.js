// Author: $t@$h
//
// This goes with this detection: https://github.com/STashakkori/MalwareDetection/tree/main/FaviconBeacon
//
// Can also mitigate caching while keeping the favicon stealthy and this also effectively patches against steg:
//   https://github.com/STashakkori/Obfuscators/blob/main/favicon-mutator.js
//
// Also see this tested APT proof-of-concept: https://github.com/STashakkori/Favicon-Stegostealth
// When tamper is detected, run this functon below to patch:

// Manually restores the golden known-good favicon
const FaviconRestorer = (() => {
  // Fetches an image from the given URL, bypassing cache, and returns an HTMLImageElement
  const fetchImage = async (url) => {
    try {
      const res = await fetch(url, { cache: "no-store" }); // Force bypass cache
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const blob = await res.blob();
      if (!blob.type.startsWith("image")) throw new Error("Not an image");

      return await new Promise((resolve, reject) => {
        const img = new Image();
        img.crossOrigin = "anonymous";
        img.onload = () => resolve(img);
        img.onerror = reject;
        img.src = URL.createObjectURL(blob); // Convert blob to local object URL
      });
    } catch (e) {
      console.warn("[FaviconRestorer] Failed to fetch image:", url);
      return null;
    }
  };

  // Replaces all current <link rel="icon"> elements with a new one from the canvas
  const updateFavicon = (canvas) => {
    if (!canvas || !canvas.width || !canvas.height) return;

    canvas.toBlob(blob => {
      if (!blob) return;

      const blobURL = URL.createObjectURL(blob); // Create object URL for favicon blob

      // Remove all current favicons
      document.querySelectorAll("link[rel*='icon']").forEach(e => e.remove());

      // Inject new favicon link
      const link = document.createElement("link");
      link.rel = "icon";
      link.type = "image/png";
      link.href = blobURL;
      document.head.appendChild(link);

      // Ensure <link rel="mask-icon"> exists (Safari-specific override guard)
      let mask = document.querySelector('link[rel="mask-icon"]');
      if (!mask) {
        mask = document.createElement("link");
        mask.rel = "mask-icon";
        document.head.appendChild(mask);
      }
      mask.href = "data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg'/>";

      // Ensure <meta name="theme-color"> is present
      let theme = document.querySelector('meta[name="theme-color"]');
      if (!theme) {
        theme = document.createElement("meta");
        theme.name = "theme-color";
        document.head.appendChild(theme);
      }
      theme.content = "#000000";

      console.log("[FaviconRestorer] Favicon restored.");
    }, "image/png");
  };

  // Manually restores favicon from /favicon.png and applies it via canvas
  const restore = async () => {
    const img = await fetchImage("/favicon.png");
    if (!img) return;

    const canvas = document.createElement("canvas");
    canvas.width = img.width;
    canvas.height = img.height;

    const ctx = canvas.getContext("2d");
    ctx.drawImage(img, 0, 0);

    updateFavicon(canvas);
  };

  // Expose public API
  return { restore };
})();

// You can run it like so:
//   FaviconRestorer.restore();

/* Timing is important (blob needs to be available), so include after DOM load:
  <script>
    window.addEventListener("DOMContentLoaded", () => {
      if (window.FaviconBeacon) {
        FaviconBeacon.arm();
        FaviconBeacon.startWatch();
      } else {
        console.error("FaviconBeacon is still undefined");
      }
    });
  </script>
*/

// Tested and works:
/*
  [FaviconBeacon] Watchdog started
  favicon-hamming.js:38 [FaviconBeacon] First 16 pixels: (64) [0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255]
  favicon-hamming.js:117 [FaviconBeacon] Current hash: 1754775552
  favicon-hamming.js:122 [FaviconBeacon] Baseline hash recorded: 1754775552
  favicon-hamming.js:38 [FaviconBeacon] First 16 pixels: (64) [0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255]
  favicon-hamming.js:117 [FaviconBeacon] Current hash: 1754775552
  favicon-hamming.js:128 [FaviconBeacon] Favicon verified.
  favicon-hamming.js:38 [FaviconBeacon] First 16 pixels: (64) [0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255]
  favicon-hamming.js:117 [FaviconBeacon] Current hash: 1754775552
  favicon-hamming.js:128 [FaviconBeacon] Favicon verified.
  document.querySelector("link[rel~='icon']").href = "/favicon4.png";
  '/favicon4.png'
  favicon-hamming.js:38 [FaviconBeacon] First 16 pixels: (64) [0, 128, 0, 254, 0, 128, 0, 254, 0, 128, 0, 254, 0, 128, 0, 254, 0, 128, 0, 254, 0, 128, 0, 254, 0, 128, 0, 254, 0, 128, 0, 254, 0, 128, 0, 254, 0, 128, 0, 255, 0, 128, 0, 254, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 254]
  favicon-hamming.js:117 [FaviconBeacon] Current hash: 148765988
  favicon-hamming.js:125  [FaviconBeacon] Favicon hash mismatch! Possible APT/tampering.
  checkFaviconIntegrity @ favicon-hamming.js:125
  await in checkFaviconIntegrity
  (anonymous) @ favicon-hamming.js:154
  setInterval
  startWatch @ favicon-hamming.js:153
  (anonymous) @ mitigation-test:15
  favicon-hamming.js:155  [FaviconBeacon] ALERT: Favicon tampering detected.
  (anonymous) @ favicon-hamming.js:155
  setInterval
  startWatch @ favicon-hamming.js:153
  (anonymous) @ mitigation-test:15
  [NEW] Explain Console errors by using Copilot in Edge: click
           
           to explain an error. 
          Learn more
          Don't show again
  FaviconRestorer.restore();
  Promise {<pending>}
  favicon-restore.js:66 [FaviconRestorer] Favicon restored.
  favicon-hamming.js:38 [FaviconBeacon] First 16 pixels: (64) [0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255, 0, 128, 0, 255]
  favicon-hamming.js:117 [FaviconBeacon] Current hash: 1754775552
  favicon-hamming.js:128 [FaviconBeacon] Favicon verified.
*/
