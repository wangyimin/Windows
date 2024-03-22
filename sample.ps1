
$triggers = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services" |
    ?{ $_.GetSubkeyNames().Contains("TriggerInfo") } |
    %{ $_.Name.Split("\")[-1] }

$startMode = @{ Manual = "手動"; Disabled = "無効"; Auto = "自動"; Unknown = "不明" }
$startOption = @{ 01 = " (トリガー開始)"; 10 = " (遅延開始)"; 11 = " (遅延開始、トリガー開始)" }

$serviceData = Get-CimInstance -ClassName Win32_Service | select @(
    @{ n = "表示名";              e = { $_.DisplayName } }
    @{ n = "サービス名";          e = { $_.Name } }
    @{ n = "スタートアップの種類"; e = { $startMode[$_.StartMode] + $startOption[10 * ($_.StartMode -eq "Auto" -and $_.DelayedAutoStart) + $triggers.Contains($_.Name)] } }
    @{ n = "状態";                e = { if($_.State -eq "Running") { "実行" } else { "停止" } } }
)
$serviceData

Function ListFirewallRuleInbound($names){
    if (!($names -is [Array])){
        throw "Invalad parameter"
    }
    
    $fw = @()
    Get-Netfirewallrule -Enabled True -Direction "Inbound" | ? DisplayName -in $names | foreach {
        $el = [PSCustomObject]@{
            "app" = $_ | NetFirewallApplicationFilter | select "Program" | % {$_.Program};
            "localaddr" = '@(' + (($_ | Get-NetfirewallAddressFilter | select "LocalAddress" | % {'"{0}"' -f $_.LocalAddress}) -join ',') + ')';
            "remoteaddr" = $_ | Get-NetfirewallAddressFilter | select "RemoteAddress"| % {$_.RemoteAddress};
            "localport" = $_ | Get-NetFirewallPortFilter | select "LocalPort" | % {$_.LocalPort};
            "remoteport" = $_ | Get-NetFirewallPortFilter | select "RemotePort"| % {$_.RemotePort};
        };
        $fw += $el;
    }

    return $fw;
}

$f = $function:ListFirewallRuleInbound
& $f @("Apache HTTP Server") | ft
#ListFirewallRuleInbound(@("code.exe"))

$prop = @{
  "Name" = $_.DisplayName;
}
$psobj = New-Object -TypeName psobject -Property $prop
$lst += $psobj

$lst | Sort-Object Name -Unique | Format-Table -Property Name
$lst | Select Name -Unique | Sort-Object Name | Export-Csv -Path ... -Encoding Default


$acl = Get-Acl <folder or file>
$ar = New-Object System.Security.AccessControl.FileSystemAccessRule("<domain>\<user>","FullControl","ContainerInherit,ObjectInherit",""None","Allow")
$acl.AddAccessRule($ar) 
Set-Acl <folder or file> $acl
