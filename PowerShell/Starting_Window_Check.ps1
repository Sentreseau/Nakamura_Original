#チェック対象のWindow名を指定する
$searchwindow = "Nobody"

$activeflg = 0
$waitcnt = 0

while ($activeflg -ne 1){
    $psArray = [System.Diagnostics.Process]::GetProcesses()
    $processlist = foreach ($ps in $psArray){ 
	   [String]$ps.Handles + " : " + $ps.MainWindowTitle
    }
    foreach($line in $processlist) {
    	if ($line.Contains($searchwindow) -eq $true ){
    		$activeflg=1
    	}
    }
    if ($activeflg -ne 1){
        $waitcnt++
    }
    if ($waitcnt -eq 4){
        write-host 9
        exit 9
    }else{
        start-sleep -s 30
    }    
}