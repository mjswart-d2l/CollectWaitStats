Get-Content "WaitStats\[0-9]*.sql" | Set-Content "WaitStats\CreateObjects.sql"
Get-Content "LatchStats\[0-9]*.sql" | Set-Content "LatchStats\CreateObjects.sql"
Get-Content "SpinStats\[0-9]*.sql" | Set-Content "SpinStats\CreateObjects.sql"