<#
  .SYNOPSIS
  Example report of replication heath in Active Directory.

  .DESCRIPTION
  Script use repadmin util for get of replication data. It also creates a table in HTML format
  and send report by email.

  .INPUTS
  None

  .OUTPUTS
  None

  .LINK
  https://docs.microsoft.com/en-us/troubleshoot/windows-server/identity/diagnose-replication-failures

  .NOTES
  Author: Dorofeev Roman
  Date: 2019.10.31
#>

# Style for table
$css = @"
    <style>
        h1, h5, th { text-align: center; font-family: Segoe UI; }
        table { margin: auto; font-family: Segoe UI; border: thin ridge grey; }
        th { background: #798499; color: #fff; max-width: 400px; padding: 5px 10px; }
        td { font-size: 11px; padding: 5px 20px; color: #000; }
        tr { background: #b8d1f3; }
        tr:nth-child(even) { background: #dae5f4; }
        tr:nth-child(odd) { background: #b8d1f3; }
        div { color: #fa5757; }
    </style>
"@

# Body of email
$html = '<html><head>' + $css + '</head><body>'

# SMTP parameters
$smtp = '<SMTP_SERVER>'
$to = '<ADDRESS_RECIPIENT>'
$from = '<ADDRESS_SENDER>'
$subject = 'AD / Replication status'
$encoding = [System.Text.Encoding]::UTF8

# Table
$table = '<table><colgroup><col/><col/><col/><col/><col/><col/><col/><col/><col/><col/><col/></colgroup>'
$header_table = '<tr><th>Destination DSA Site</th><th>Destination DSA</th><th>Naming Context</th><th>Source DSA Site</th>'+`
                '<th>Source DSA</th><th>Transport Type</th><th>Number of Failures</th><th>Last Failure Time</th>'+`
                '<th>Last Success Time</th><th>Last Failure Status</th></tr>'
$body_table = ''
$errors_count = 0


# Replication report in CSV
$csv = repadmin /showrepl * /csv | ConvertFrom-Csv

foreach ($item in $csv) {
    
    $body_table += '<tr><td>'+ $item.'Destination DSA Site' +'</td><td>'+ $item.'Destination DSA' +'</td><td>'+ `
                   $item.'Naming Context' +'</td><td>'+ $item.'Source DSA Site' + '</td><td>'+ ` 
                   $item.'Source DSA' +'</td><td>'+ $item.'Transport Type' +'</td><td>'+ `
                   $item.'Number of Failures' +'</td><td>'+ $item.'Last Failure Time' +'</td><td>'+ ` 
                   $item.'Last Success Time' +'</td>'

    if ( $item.'Last Failure Status' -ne '0' ) {
        $body_table += '<td style="background: #fa5757;">' + $item.'Last Failure Status' + '</td></tr>'
        $errors_count++ 
    } else {
        $body_table += '<td>'+ $item.'Last Failure Status' +'</td></tr>'
    } 
}

$html += "Total replication errors: $errors_count"
$html += '<br><br>'

$html += ($table + $header_table)
$html += $body_table
$html += '</table></body></html>'

# Send email
Send-MailMessage -SmtpServer $smtp -To $to -From $from -Subject $subject -Body $html -BodyAsHtml -Encoding $encoding
