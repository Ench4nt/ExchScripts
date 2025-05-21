param (
    [string]$SourceServer = (hostname),
    [string]$ExportPath = ".\ReceiveConnectorsExport.xml",
    [string]$ConnectorName  # Optional: Export only a specific connector
)

Add-PSSnapin *exch*

Write-Host "$SourceServer\$ConnectorName"
if ($ConnectorName) {
    $connectors = Get-ReceiveConnector -Identity "$SourceServer\$ConnectorName"
    if (-not $connectors -or $connectors.Count -eq 0){
        Write-Error "Connector '$ConnectorName' not found on $SourceServer."
        exit
    }
} else {
    $connectors = Get-ReceiveConnector -Server $SourceServer
}

$connectorConfigs = foreach ($conn in $connectors) {
    [PSCustomObject]@{
        Name                             = $conn.Name
        Bindings                         = $conn.Bindings
        RemoteIPRanges                   = $conn.RemoteIPRanges
        AuthMechanism                    = $conn.AuthMechanism
        PermissionGroups                 = $conn.PermissionGroups
        TransportRole                    = $conn.TransportRole
        MaxMessageSize                   = $conn.MaxMessageSize
        ProtocolLoggingLevel             = $conn.ProtocolLoggingLevel
        Enabled                          = $conn.Enabled
        RequireTLS                       = $conn.RequireTLS
        TarpitInterval                   = $conn.TarpitInterval
        Banner                           = $conn.Banner
        Fqdn                             = $conn.Fqdn
        AdvertiseClientSettings          = $conn.AdvertiseClientSettings
        ConnectionTimeout                = $conn.ConnectionTimeout
        MessageRateLimit                 = $conn.MessageRateLimit
        MaxInboundConnection             = $conn.MaxInboundConnection
        MaxInboundConnectionPerSource    = $conn.MaxInboundConnectionPerSource
        MaxInboundConnectionPercentagePerSource = $conn.MaxInboundConnectionPercentagePerSource
        MaxRecipientsPerMessage          = $conn.MaxRecipientsPerMessage
        MaxHeaderSize                    = $conn.MaxHeaderSize
        MaxHopCount                      = $conn.MaxHopCount
        MaxLocalHopCount                 = $conn.MaxLocalHopCount
        SizeEnabled                      = $conn.SizeEnabled
        EnableAuthGSSAPI                 = $conn.EnableAuthGSSAPI
        Comment                          = $conn.Comment
    }
}

$connectorConfigs | Export-Clixml -Path $ExportPath
Write-Host "Exported $(if ($ConnectorName) { "connector '$ConnectorName'" } else { "all connectors" }) from $SourceServer to $ExportPath"
