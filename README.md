# GPO Export & Import Automation (PowerShell + LGPO)

This repository includes two PowerShell scripts for backing up and restoring Group Policy Objects (GPOs) in a Windows Active Directory domain environment.

These scripts support:
- Full GPO export (domain policies + local policy settings)
- Clean re-import into a domain
- Automated handling of local security policies via `LGPO.exe`

---

## 📄 Scripts Included

### `Export-GPOs.ps1`
Exports all GPOs from the domain to a folder next to the script. It also calls `LGPO.exe` to capture local policy settings.

### `Import-GPOs.ps1`
Imports GPOs from a specified folder back into the domain. This includes both domain policy settings and local security settings (via `LGPO.exe`).

---

## ⚙ Requirements

- **PowerShell 5.1+**
- **Domain Admin privileges**
- **Group Policy Management Console (GPMC)** installed
- `LGPO.exe` (must be placed in the same directory as the scripts)

### Download `LGPO.exe`
You can get it from the Konsistent repository: https://repository.konsistent.co/repository/packages/Utilities/LGPO/LGPO.exe
