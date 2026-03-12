const fs = require("fs");
const path = require("path");

function walkDir(dir, callback) {
  if (!fs.existsSync(dir)) return;
  fs.readdirSync(dir).forEach((f) => {
    let dirPath = path.join(dir, f);
    let isDirectory = fs.statSync(dirPath).isDirectory();
    isDirectory ? walkDir(dirPath, callback) : callback(dirPath);
  });
}

const dirs = [
  "/Users/ace/my_first_project/lib",
  "/Users/ace/my_first_project/test",
];

dirs.forEach((dir) => {
  walkDir(dir, (filePath) => {
    if (filePath.endsWith(".dart")) {
      let content = fs.readFileSync(filePath, "utf8");
      let newContent = content
        .replace(/\bplan:\s/g, "tier: ")
        .replace(/\bplanId\b/g, "tierId")
        .replace(/\bplans\b/g, "tiers")
        .replace(/\bplans:/g, "tiers:")
        .replace(/\bthis\.plan\b/g, "this.tier")
        .replace(/\bplan\./g, "tier.")
        .replace(/\bplan;/g, "tier;")
        .replace(/\bplanStreamController\b/g, "tierStreamController");

      // Specifically for user_dto.dart switch case non-exhaustive
      if (filePath.includes("user_dto.dart")) {
        if (
          newContent.includes("switch (tier)") &&
          !newContent.includes("case SubscriptionTier.platinum:")
        ) {
          newContent = newContent.replace(
            "case SubscriptionTier.free:",
            "case SubscriptionTier.platinum:\n        return 'platinum';\n      case SubscriptionTier.free:",
          );
        }
      }

      if (content !== newContent) {
        fs.writeFileSync(filePath, newContent, "utf8");
        console.log(`Updated ${filePath}`);
      }
    }
  });
});
