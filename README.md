# 📁 create-default-gpo

A pair of PowerShell scripts to **selectively export** and **safely import** Active Directory Group Policy Objects (GPOs), complete with interactive prompts, friendly output, and error handling.

---

## 🔧 Prerequisites

- Run PowerShell as **Administrator**
- Must be joined to the domain and have **Domain Admin** rights
- Requires the `GroupPolicy` module (available by default on domain controllers or RSAT-installed systems)

---

## 📤 Exporting GPOs

Use the `Export-GPOs.ps1` script to interactively choose which GPOs to export.

```powershell
.\Export-GPOs.ps1
```

### What it does:

- Prompts for each GPO: `[Y/n]` to include or skip
- Backs up selected GPOs into a timestamped folder like `Exported-GPOs-2025-06-12`
- Each GPO is backed up with full metadata, including `backup.xml`

### Sample output:

```
Include GPO: Global - LucidLink? [Y/n]: y
Include GPO: Default Domain Policy? [Y/n]: n
...
Exported: Global - LucidLink
```

At the end, the script shows the final backup folder path.

---

## 📥 Importing GPOs

Use the `Import-GPOs.ps1` script to restore GPOs from an export folder.

```powershell
.\Import-GPOs.ps1 "C:\Path\To\Exported-GPOs"
```

### What it does:

- Reads each GPO backup folder and extracts the original DisplayName from `backup.xml`
- Prompts for each GPO: `[Y/n]` to import
- Re-creates or overwrites each GPO by name

### Sample output:

```
Import GPO: 'Global - LucidLink'? [Y/n]: y
GPO already exists: Global - LucidLink — overwriting.
Imported: Global - LucidLink
```

Backups missing a valid `DisplayName` are skipped with a warning.

---

## 📂 Folder Structure Example

After exporting, your folder might look like this:

```
Exported-GPOs-2025-06-12\
├── {GUID1}\
│   └── backup.xml
├── {GUID2}\
│   └── backup.xml
...
```

The script uses `backup.xml` to determine the GPO’s DisplayName. The folder name (GUID) is never used as a fallback.

---
