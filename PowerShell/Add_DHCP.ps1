##初期設定変数
# ログパス指定
$LogFilename = Get-Date -Format "yyyyMMdd"
$LogDir = "C:\temp\Script\log"

# DHCP設定ファイル指定
$MACIPFILE = "C:\temp\scripttemp\vm\VM_IPMAC_list.csv"

# スコープIDを指定
$Scope1 = '10.0.1.0'
$Scope2 = '172.16.1.0'

# 乱数を生成
$RANDOM = Get-Random 1000

# Unicodeにファイルを変換するためのファイル名を変数に格納する
# ファイル名が被らないように乱数を利用
$MACIPFILE_UNI = "$MACIPFILE.$RANDOM"

# ファイルの存在確認
if(Test-Path $MACIPFILE) {
    Write-Host "$MACIPFILE の存在が確認できました。"
} else {
    Write-Host "$MACIPFILE の存在が確認できませんでした。"
    Write-Host "処理を中断します。"
exit 1
}

# 文字コードをUnicodeへ変換(SJISだと文字化けする)
Get-Content $MACIPFILE | Out-File $MACIPFILE_UNI -Encoding UNICODE

# CSV インポート
$dhcps= Import-CSV -path $MACIPFILE_UNI


# DHCP予約ルーチン
function DHCPReserve{

    # 情報系LAN用DHCP予約
    Add-DhcpServerv4Reservation -ScopeId $Scope1 -IPAddress $Scope1ip -ClientId $Scope1mac -name $vmname

    # Scope2系LAN用DHCP予約
    Add-DhcpServerv4Reservation -ScopeId $Scope2 -IPAddress $Scope2ip -ClientId $Scope2mac -name $vmname

}

# 処理開始ログ出力
$Logfilepath = $LogDir + "\" + $LogFilename + "DHCP予約.log" 
$logdate = $null
$logdata = $null
$logdate = Get-Date -format "yyyy/MM/dd hh:mm:ss"
$logdata = $logdate + " DHCP予約を開始します。予約登録数は" + $dhcps.count + "個です。"
Write-output $logdata | out-file $Logfilepath Default -append

# 標準出力情報ファイル格納場所取得
$stdlogdir = $logdir + "\dhcp_std"
mkdir $stdlogdir

# 処理カウント初期化
[int]$i=0

# DHCP予約ループ処理開始
foreach ($dhcp in $dhcps) {
    # 必要な情報を変数へ格納
    # CSVの第一カラムをキーとして各値を取得
    $i++
    $vmname = $dhcp.VMName
    $Scope1ip = $dhcp.Scope1ip
    $Scope1mac = $dhcp.Scope1mac
    $Scope2ip = $dhcp.Scope2ip
    $Scope2mac = $dhcp.Scope2mac

    # ログ出力 
    $logdate = $null
    $logdata = $null
    $logdate = Get-Date -format "yyyy/MM/dd hh:mm:ss"
    $logdata = $logdate + " " + $VMName + "のDHCP予約を作成します。"
    Write-output $logdata | out-file $Logfilepath Default -append

    # 標準出力ログ生成開始
    $StdLogfilePath = $null
    $StdLogfilePath = $stdlogdir + "\" + $VMName + "_std.log" 
    Start-Transcript $StdLogfilePath

    # DHCP予約メインルーチン呼び出し
    DHCPReserve

    # 標準出力ログ生成停止
    Stop-Transcript

    # ログ出力 
    $logdate = $null
    $logdata = $null
    $logdate = Get-Date -format "yyyy/MM/dd hh:mm:ss"
    $logdata = $logdate + " " + $VMName + "のDHCP予約が完了しました。"
    Write-output $logdata | out-file $Logfilepath Default -append

}


# 処理開始ログ出力
$logdate = $null
$logdata = $null
$logdate = Get-Date -format "yyyy/MM/dd hh:mm:ss"
$logdata = $logdate + " DHCP予約が完了しました。予約完了数は" + $i + "個です。"
Write-output $logdata | out-file $Logfilepath Default -append

# Unicodeに変換したファイルを削除
Remove-Item $MACIPFILE_UNI