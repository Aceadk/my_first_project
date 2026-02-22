import os
import glob

audit_todos_dir = "audit/todos"
docs_dir = "docs"

# Get all markdown files in audit/todos
audit_files = glob.glob(f"{audit_todos_dir}/*.md")

for audit_file in audit_files:
    filename = os.path.basename(audit_file)
    docs_file = os.path.join(docs_dir, filename)
    
    with open(audit_file, 'r', encoding='utf-8') as af:
        audit_content = af.read()
        
    if os.path.exists(docs_file):
        # Merge: Append content from audit to docs
        with open(docs_file, 'r', encoding='utf-8') as df:
            docs_content = df.read()
            
        print(f"Merging {filename}...")
        
        # Simple merge: Docs content first, then Audit content separated by a clear rule
        merged_content = docs_content + "\n\n---\n\n## (Auto-Merged from V2 Audit Directive)\n\n" + audit_content
        
        with open(docs_file, 'w', encoding='utf-8') as df:
            df.write(merged_content)
    else:
        # Move: Just copy the file from audit to docs
        print(f"Moving {filename} to docs/...")
        with open(docs_file, 'w', encoding='utf-8') as df:
            df.write(audit_content)
            
print("Moving reports...")
if not os.path.exists(f"{docs_dir}/reports"):
    os.makedirs(f"{docs_dir}/reports", exist_ok=True)
for report in glob.glob("audit/reports/*.md"):
    report_name = os.path.basename(report)
    with open(report, 'r', encoding='utf-8') as rf:
        content = rf.read()
    with open(os.path.join(docs_dir, "reports", report_name), 'w', encoding='utf-8') as wf:
        wf.write(content)

print("Consolidation complete.")
