##初期設定変数
# ログパス指定
$LogFilename = Get-Date -Format "yyyyMMdd"
$LogDir = "C:\temp\Script\log"

# vCenter Serverコネクション情報
$Connect1StServer = "X.X.X.X"
$ConnectUser = "XXXXXXXXXX"
$ConnectPassword = "XXXXXXXXXX"
# 量産化定義ファイルパス指定
$FILE = "C:\temp\scripttemp\vm\VM_Creation_info.csv"

# 量産化定義ファイル（MacAddress追加版）出力パス指定 
$MACFILE = "C:\temp\scripttemp\vm\VM_Creation_info_Mac.csv"

#
#--------------------- 

#PowerCLIコードを扱える様にするためのスナップインを追加。
Add-PSSnapin VMware.VimAutomation.Core


# 乱数を生成
$RANDOM = Get-Random 1000

# Unicodeにファイルを変換するためのファイル名を変数に格納する
# ファイル名が被らないように乱数を利用
$FILE_UNI = "$FILE.$RANDOM"

# ファイルの存在確認
if(Test-Path $FILE) {
    Write-Host "$FILE の存在が確認できました。"
} else {
    Write-Host "$FILE の存在が確認できませんでした。"
    Write-Host "処理を中断します。"
exit 1
}

# 文字コードをUnicodeへ変換(SJISだと文字化けする)
Get-Content $FILE | Out-File $FILE_UNI -Encoding UNICODE

# vCenterサーバへ接続
Connect-VIServer -Server $Connect1StServer -User $ConnectUser -Password $ConnectPassword

# CSV インポート
$vms = Import-CSV $FILE_UNI


function system2MachineMake{
    $TemplateName = Get-Template $Template
    New-VM -Name $VMName -Template $TemplateName -VMHost $vSphereHost -Datastore $Datastore

    #system1用NIC作成
    New-NetworkAdapter -VM $VMName -NetworkName "system1" -type Vmxnet3 -StartConnected

    #system2用NIC作成
    New-NetworkAdapter -VM $VMName -NetworkName "system2" -type Vmxnet3 -StartConnected

}

# 処理開始ログ出力
$Logfilepath = $LogDir + "\" + $LogFilename + "VM量産.log" 
$logdate = $null
$logdata = $null
$logdate = Get-Date -format "yyyy/MM/dd hh:mm:ss"
$logdata = $logdate + " VM量産処理を開始します。作成マシン数は" + $vms.count + "台です。"
Write-output $logdata | out-file $Logfilepath Default -append


# 標準出力情報ファイル格納場所取得
$stdlogdir = $logdir + "\vm_std"
mkdir $stdlogdir

# MACAddress出力定義
$mac_obj_ary = @()

# 処理カウント初期化
[int]$i=0

# 仮想マシンの作成ループ処理開始
foreach ($vm in $vms) {
    # 必要な情報を変数へ格納
    # CSVの第一カラムをキーとして各値を取得
    $i++
    $VMName = $vm.VMName
    $Template = $vm.Template
    $vSphereHost = Get-VMHost $vm.vSphereHost
    $Datastore = Get-Datastore $vm.Datastore 
    
    # MacAddress結合用のため、その他の情報も吸出し
    $devicecollection = $vm.devicecollection
    $system1ip = $vm.system1ip
    $system2ip = $vm.system2ip


    # ログ出力 
    $logdate = $null
    $logdata = $null
    $logdate = Get-Date -format "yyyy/MM/dd hh:mm:ss"
    $logdata = $logdate + " " + $VMName + "を作成します。"
    Write-output $logdata | out-file $Logfilepath Default -append
    
    # 標準出力ログ生成開始
    $StdLogfilePath = $null
    $StdLogfilePath = $stdlogdir + "\" + $VMName + "_std.log" 
    Start-Transcript $StdLogfilePath

    # 仮想マシン作成メインルーチン呼び出し
    system2MachineMake

    # 標準出力ログ生成停止
    Stop-Transcript

    # MacAddress抽出処理
    # VMのMacAddressフォーマットとDHCP・system2のMacAddressフォーマットが異なるため変換（":" → "-"）
    $system1nicMac = get-vm -name $vmname | Get-NetworkAdapter | where {$_.NetworkName -match "system1"} | select MacAddress
    $system1nicMacRP =  $system1nicMac.MacAddress -replace ":","-"
    $system2nicMac = get-vm -name $vmname | Get-NetworkAdapter | where {$_.NetworkName -match "system2"} | select MacAddress
    $system2nicMacRP = $system2nicMac.MacAddress -replace ":","-"

    # MacAddress追加版量産定義ファイル生成用配列作成
    $macobj1 = New-Object PSCustomObject
    $macobj1 | Add-Member -MemberType NoteProperty -Name "VMName" -Value $VMName
    $macobj1 | Add-Member -MemberType NoteProperty -Name "Template" -Value $Template
    $macobj1 | Add-Member -MemberType NoteProperty -Name "vSphereHost" -Value $vSphereHost   
    $macobj1 | Add-Member -MemberType NoteProperty -Name "Datastore" -Value $Datastore   
    $macobj1 | Add-Member -MemberType NoteProperty -Name "devicecollection" -Value $devicecollection   
    $macobj1 | Add-Member -MemberType NoteProperty -Name "system1ip" -Value $system1ip   
    $macobj1 | Add-Member -MemberType NoteProperty -Name "system2ip" -Value $system2ip  
    $macobj1 | Add-Member -MemberType NoteProperty -Name "system1mac" -Value $system1nicMacRP
    $macobj1 | Add-Member -MemberType NoteProperty -Name "system2mac" -Value $system2nicMacRP
    $mac_obj_ary += $macobj1


    # ログ出力 
    $logdate = $null
    $logdata = $null
    $logdate = Get-Date -format "yyyy/MM/dd hh:mm:ss"
    $logdata = $logdate + " " + $VMName + "の作成が完了しました。"
    Write-output $logdata | out-file $Logfilepath Default -append

}

# MacAddress追加版量産定義ファイル生成
$mac_obj_ary | select * | Export-Csv $MACFILE -Encoding default -NoTypeInformation

# すべてのvCenterサーバから切断
Disconnect-VIServer -Server * -Confirm:$false

# 処理終了ログ出力
$Logfilepath = $LogDir + "\" + $LogFilename + "VM量産.log" 
$logdate = $null
$logdata = $null
$logdate = Get-Date -format "yyyy/MM/dd hh:mm:ss"
$logdata = $logdate + " VM量産処理が完了しました。作成完了マシン数は" + $i + "台です。"
Write-output $logdata | out-file $Logfilepath Default -append

# Unicodeに変換したファイルを削除
Remove-Item $FILE_UNI