// Author: $t@$h
// This goes with this detection: https://github.com/STashakkori/MalwareDetection/tree/main/FaviconBeacon
// Also see this tested APT proof-of-concept: https://github.com/STashakkori/Favicon-Stegostealth
// When tamper is detected, run this functon below to patch:

// restoreGolden — Manually restores the golden known-good favicon
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

  // Expose public API, no auto-run
  return { restore };
})();

// You can run it like so:
//   FaviconRestorer.restore();
