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
  "/Users/ace/my_first_project/lib/features",
  "/Users/ace/my_first_project/test",
];

dirs.forEach((dir) => {
  walkDir(dir, (filePath) => {
    if (
      filePath.endsWith(".dart") &&
      !filePath.includes("safety") &&
      !filePath.includes("date_plan")
    ) {
      let content = fs.readFileSync(filePath, "utf8");

      let newContent = content
        .replace(/\bfinal plan = /g, "final tier = ")
        .replace(/\bplan,$/gm, "tier,")
        .replace(/\bthis\.plan\b/g, "this.tier")
        .replace(/plan: plan/g, "tier: tier");

      if (content !== newContent) {
        fs.writeFileSync(filePath, newContent, "utf8");
        console.log(`Updated ${filePath}`);
      }
    }
  });
});
