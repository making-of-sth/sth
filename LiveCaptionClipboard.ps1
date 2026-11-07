Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

function Get-LiveCaptionText {
    $process = Get-Process -Name LiveCaptions -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $process) { throw '라이브 캡션을 켜주세요.' }
    $condition = [System.Windows.Automation.PropertyCondition]::new(
        [System.Windows.Automation.AutomationElement]::ProcessIdProperty, $process.Id)
    $window = [System.Windows.Automation.AutomationElement]::RootElement.FindFirst(
        [System.Windows.Automation.TreeScope]::Children, $condition)
    if ($null -eq $window) { throw '라이브 캡션 창을 찾지 못했습니다.' }
    foreach ($id in @('CaptionsTextBlock', 'CaptionsScrollViewer')) {
        $elementCondition = [System.Windows.Automation.PropertyCondition]::new(
            [System.Windows.Automation.AutomationElement]::AutomationIdProperty, $id)
        $element = $window.FindFirst(
            [System.Windows.Automation.TreeScope]::Descendants, $elementCondition)
        if ($null -eq $element) { continue }
        $pattern = $null
        if ($element.TryGetCurrentPattern(
            [System.Windows.Automation.TextPattern]::Pattern, [ref]$pattern)) {
            $text = $pattern.DocumentRange.GetText(-1)
            if (-not [string]::IsNullOrWhiteSpace($text)) { return $text }
        }
        $pattern = $null
        if ($element.TryGetCurrentPattern(
            [System.Windows.Automation.ValuePattern]::Pattern, [ref]$pattern)) {
            $text = $pattern.Current.Value
            if (-not [string]::IsNullOrWhiteSpace($text)) { return $text }
        }
    }
    throw '실제 자막 문장을 읽지 못했습니다.'
}

$lastCopied = $null
$lastError = $null
Write-Host '최신 자막의 마지막 줄을 자동 복사합니다.'
Write-Host '원하는 곳에서 직접 붙여넣으세요. 이 창은 최소화해도 됩니다.'
Write-Host '종료: 이 창에서 Ctrl+C 또는 창 닫기'
while ($true) {
    try {
        $caption = Get-LiveCaptionText
        $latestLine = $caption -split '\r\n|\n|\r' |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Select-Object -Last 1
        if (-not [string]::IsNullOrWhiteSpace($latestLine) -and $latestLine -cne $lastCopied) {
            Set-Clipboard -Value $latestLine -ErrorAction Stop
            $lastCopied = $latestLine
            Write-Host "복사: $latestLine"
        }
        $lastError = $null
    }
    catch {
        $message = $_.Exception.Message
        if ($message -ne $lastError) {
            Write-Host "확인 필요: $message" -ForegroundColor Yellow
            $lastError = $message
        }
    }
    Start-Sleep -Milliseconds 200
}
