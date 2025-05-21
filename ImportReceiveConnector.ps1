param (
    [string]$TargetServer = $env:COMPUTERNAME,
    [string]$ImportPath = ".\ReceiveConnectorsExport.xml"
)

if (!(Test-Path $ImportPath)) {
    throw "Import file not found: $ImportPath"
}

$connectorConfigs = Import-Clixml -Path $ImportPath

foreach ($conn in $connectorConfigs) {
    Write-Host "`nProcessing connector '$($conn.Name)'..."

    # Convert bindings
    $bindings = $conn.Bindings | ForEach-Object {
        [Microsoft.Exchange.Data.IPBinding]::Parse($_.ToString())
    }

    # Convert remote IPs
    $remoteIPs = $conn.RemoteIPRanges | ForEach-Object {
        [Microsoft.Exchange.Data.IPRange]::Parse($_.ToString())
    }

    # EnhancedTimeSpans
    $tarpitInterval = [Microsoft.Exchange.Data.EnhancedTimeSpan]::Parse($conn.TarpitInterval.ToString())
    $connectionTimeout = [Microsoft.Exchange.Data.EnhancedTimeSpan]::Parse($conn.ConnectionTimeout.ToString())

    # ByteQuantifiedSizes
    $maxMessageSize = [Microsoft.Exchange.Data.ByteQuantifiedSize]::Parse($conn.MaxMessageSize.ToString())
    $maxHeaderSize = [Microsoft.Exchange.Data.ByteQuantifiedSize]::Parse($conn.MaxHeaderSize.ToString())

    # Unlimited<int>
    $maxInboundConnection = [Microsoft.Exchange.Data.Unlimited[int]]::Parse($conn.MaxInboundConnection.ToString())
    $maxInboundConnectionPerSource = [Microsoft.Exchange.Data.Unlimited[int]]::Parse($conn.MaxInboundConnectionPerSource.ToString())
    $maxInboundConnectionPercentagePerSource = [Microsoft.Exchange.Data.Unlimited[int]]::Parse($conn.MaxInboundConnectionPercentagePerSource.ToString())
    $maxRecipientsPerMessage = [Microsoft.Exchange.Data.Unlimited[int]]::Parse($conn.MaxRecipientsPerMessage.ToString())

    # FQDN
    $fqdn = [Microsoft.Exchange.Data.Fqdn]::Parse($conn.Fqdn.ToString())

    # Create the new connector
    New-ReceiveConnector -Name $conn.Name `
        -Server $TargetServer `
        -Bindings $bindings `
        -RemoteIPRanges $remoteIPs `
        -AuthMechanism $conn.AuthMechanism `
        -PermissionGroups $conn.PermissionGroups `
        -TransportRole $conn.TransportRole `
        -Fqdn $fqdn `
        -MaxMessageSize $maxMessageSize `
        -ProtocolLoggingLevel $conn.ProtocolLoggingLevel `
        -RequireTLS $conn.RequireTLS `
        -TarpitInterval $tarpitInterval `
        -Banner $conn.Banner `
        -Enabled $conn.Enabled

    # Apply remaining advanced settings
    Set-ReceiveConnector -Identity "$TargetServer\$($conn.Name)" `
        -AdvertiseClientSettings $conn.AdvertiseClientSettings `
        -ConnectionTimeout $connectionTimeout `
        -MessageRateLimit $conn.MessageRateLimit `
        -MaxInboundConnection $maxInboundConnection `
        -MaxInboundConnectionPerSource $maxInboundConnectionPerSource `
        -MaxInboundConnectionPercentagePerSource $maxInboundConnectionPercentagePerSource `
        -MaxRecipientsPerMessage $maxRecipientsPerMessage `
        -MaxHeaderSize $maxHeaderSize `
        -MaxHopCount $conn.MaxHopCount `
        -MaxLocalHopCount $conn.MaxLocalHopCount `
        -SizeEnabled $conn.SizeEnabled `
        -EnableAuthGSSAPI $conn.EnableAuthGSSAPI `
        -Comment $conn.Comment

    Write-Host "Connector '$($conn.Name)' created and configured."
}
