#Requires -RunAsAdministrator

# Проверка прав администратора
function Test-IsAdmin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Перезапуск с правами администратора
if (-not (Test-IsAdmin)) {
    Write-Host "Скрипт не запущен с правами администратора. Перезапускаем с повышенными правами..."
    $scriptPath = $MyInvocation.MyCommand.Definition
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit
}

# Основная логика скрипта
try {
    # Запрос имени компьютера
    $pc_name = Read-Host "Введите имя компьютера для перезагрузки"

    # Проверка ввода
    if ([string]::IsNullOrWhiteSpace($pc_name)) {
        Write-Host "Имя компьютера не может быть пустым!" -ForegroundColor Red
        exit
    }

    Write-Host "`nПроверка доступности компьютера $pc_name..." -ForegroundColor Cyan
    
    # Двойной пинг
    $ping_result = Test-Connection -ComputerName $pc_name -Count 2 -Quiet
    
    if (-not $ping_result) {
        Write-Host "`nКомпьютер $pc_name недоступен!" -ForegroundColor Red
        Write-Host "Причина:"
        Write-Host "   - Компьютер выключен или не в сети" -ForegroundColor Yellow
        Write-Host "   - Неправильное имя" -ForegroundColor Yellow
        Write-Host "   - Проблемы с сетевым подключением`n" -ForegroundColor Yellow
        exit
    }

    Write-Host "Компьютер $pc_name доступен в сети.`n" -ForegroundColor Green
    
    # Подтверждение перезагрузки
    $confirmation = Read-Host "Вы уверены, что хотите перезагрузить компьютер $pc_name? (Y/N)"
    
    if ($confirmation -ne 'Y') {
        Write-Host "Отмена операции..." -ForegroundColor Yellow
        exit
    }

    # Выполнение команды перезагрузки
    Write-Host "`nИнициирую перезагрузку $pc_name..." -ForegroundColor Cyan
    shutdown /r /m \\$pc_name /t 0 /c "Администратор инициировал перезагрузку"
    
    # Проверка результата
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Команда успешно отправлена! Компьютер $pc_name перезагружается." -ForegroundColor Green
    }
    else {
        Write-Host "Ошибка выполнения команды! Код ошибки: $LASTEXITCODE" -ForegroundColor Red
        Write-Host "Возможные причины:"
        Write-Host "   - Недостаточно прав" -ForegroundColor Yellow
        Write-Host "   - Проблемы с RPC службой на целевом ПК" -ForegroundColor Yellow
        Write-Host "   - Блокировка брандмауэром`n" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Произошла критическая ошибка: $_" -ForegroundColor Red
}