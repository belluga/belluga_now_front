(Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object {
    $_.InterfaceAlias -notmatch 'vEthernet|Loopback|Virtual|WSL' -and
    $_.IPAddress -notlike '169.254.*'
  } |
  Sort-Object InterfaceMetric |
  Select-Object -First 1 -ExpandProperty IPAddress)
