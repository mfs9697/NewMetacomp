# Update all fields (TOC, SEQ, REF, PAGE) of the generated report in Microsoft Word, save the .docx
# and export a PDF for visual verification.  usage: render_pdf.ps1 -Docx <in.docx> -Out <out.docx> -Pdf <out.pdf>
param([Parameter(Mandatory=$true)][string]$Docx,
      [Parameter(Mandatory=$true)][string]$Out,
      [Parameter(Mandatory=$true)][string]$Pdf)
$ErrorActionPreference = 'Stop'
$Docx = (Resolve-Path $Docx).Path
$Out = [IO.Path]::GetFullPath($Out)
$Pdf = [IO.Path]::GetFullPath($Pdf)
Copy-Item -LiteralPath $Docx -Destination $Out -Force
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
    $doc = $word.Documents.Open($Out, $false, $false)
    $doc.Fields.Update() | Out-Null
    foreach ($toc in $doc.TablesOfContents) { $toc.Update() }
    $doc.Fields.Update() | Out-Null
    foreach ($sec in $doc.Sections) {
        foreach ($f in $sec.Footers) { $f.Range.Fields.Update() | Out-Null }
    }
    $pages = $doc.ComputeStatistics(2)
    $doc.Save()
    $doc.ExportAsFixedFormat($Pdf, 17, $false, 0, 0, 0, 0, 0, $true, $true, 1, $true, $true, $false)
    $doc.Close([ref]0)
    Write-Output "pages=$pages"
} finally {
    $word.Quit([ref]0)
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($word)
}
