function search {
    param( 
    [Parameter(Position=0, Mandatory=$true)] [string]$text
    )
    Get-ChildItem -recurse | Select-String -pattern $text
}
#cd D:\wamp\vhosts\orama.localwamp.dev\public\app\js\modules
#search "controller\(" | Select Path, LineNumber, Line | Export-Csv D:\Trabajo\TodosControladores.csv
#cd D:\wamp\vhosts\orama.localwamp.dev\resources\views
#search "controller\(" | Select Path, LineNumber, Line | Export-Csv D:\Trabajo\ControladoresUsados.csv