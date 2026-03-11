$free = 150995648512
$total = 999468097536
$used = $total - $free
$totalGB = $total/1GB
$usedGB = $used/1GB
$freeGB = $free/1GB
$usagePercent = ($used/$total)*100

Write-Output "C盘使用情况:"
Write-Output ("总空间: {0:N2} GB" -f $totalGB)
Write-Output ("已用空间: {0:N2} GB" -f $usedGB)
Write-Output ("可用空间: {0:N2} GB" -f $freeGB)
Write-Output ("使用率: {0:N1}%" -f $usagePercent)