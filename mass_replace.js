const fs = require("fs");
const path = require("path");

function walkDir(dir, callback) {
  fs.readdirSync(dir).forEach((f) => {
    let dirPath = path.join(dir, f);
    let isDirectory = fs.statSync(dirPath).isDirectory();
    isDirectory ? walkDir(dirPath, callback) : callback(dirPath);
  });
}

function processDartFiles() {
  const dirs = [
    "/Users/ace/my_first_project/lib",
    "/Users/ace/my_first_project/test",
  ];

  dirs.forEach((dir) => {
    walkDir(dir, (filePath) => {
      if (filePath.endsWith(".dart")) {
        let content = fs.readFileSync(filePath, "utf8");
        let newContent = content
          // Global
          .replace(/SubscriptionPlan/g, "SubscriptionTier")
          // Specific mappings for plan parameters to tier parameters
          .replace(/\bplan:\s*(SubscriptionTier\.\w+)/g, "tier: $1")
          .replace(/this\.plan/g, "this.tier")
          .replace(/required this\.plan/g, "required this.tier")
          .replace(
            /required SubscriptionTier plan/g,
            "required SubscriptionTier tier",
          )
          .replace(/SubscriptionStatus\(plan:/g, "SubscriptionStatus(tier:")
          .replace(
            /SubscriptionStatus\(\{required this\.plan/g,
            "SubscriptionStatus({required this.tier",
          )
          .replace(
            /final SubscriptionTier plan/g,
            "final SubscriptionTier tier",
          );

        // Fix references to state.plan
        newContent = newContent.replace(/\.plan\b/g, ".tier");

        // Specific block replacements if needed
        // e.g. state.plan == SubscriptionTier.plus -> state.tier == SubscriptionTier.plus

        if (content !== newContent) {
          fs.writeFileSync(filePath, newContent, "utf8");
          console.log(`Updated ${filePath}`);
        }
      }
    });
  });
}

processDartFiles();
