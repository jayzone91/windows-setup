@{
    # Dieses Passwort ist absichtlich kein Secret. Es dient ausschließlich
    # als lokales Transportpasswort für Raycasts .rayconfig-Format.
    ExportPassword = '12345678'

    # Raycast erlaubt ein frei wählbares Backup-Verzeichnis. Der Pfad wird
    # nicht aus Windows-SpecialFolders geraten, sondern explizit konfiguriert.
    # Umgebungsvariablen werden beim Lauf expandiert.
    BackupPath = '%USERPROFILE%\Documents'
}
