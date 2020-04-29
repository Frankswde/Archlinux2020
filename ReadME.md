# Archlinux install Script

## ※ 個人紀錄 
| Item|   Date |issue|
| :--: | :-|  :-
|redo|  2020/4/17 |+ 無法BOOT|
|update|  2020/4/21 | + 更新流程圖|
|update|  2020/4/29 | + 更新到GIT上|

## ※ 安裝流程圖
```flow
st=>start: 按照需求設置
op1=>operation: Check internet :>#Check-internet
op2=>operation: Verify the boot mode 
op3=>operation: Execute script
co1=>condition: 是否用Script快速安裝
sub1=>subroutine: 手動輸入指令
sub2=>subroutine: 下載Script

e=>end: 安裝完成

st->op1->op2->co1
co1(no)->sub1->e

co1(yes)->sub2->op3->e

```
## § 執行Lins Script 前須完成的設定
- 目的：安裝前需檢查的事項
- 過程：確認網路連線→確認開機引導(GRUB/UEFI)→下載script後按情況修改
**由於安裝系統用鍵盤打指令太慢，就用SSH連線後下載script來加速安裝**
### Check internet
```
ifconfig
ping -c 3 www.google.com
passwd
vim  /etc/ssh/sshd_config
systemctl start sshd
ps -e | grep sshd
```
>- sshd要將port 22的註解拿掉
>- 使用ssh連線要有passwd
### Verify the boot mode
```
ls /sys/firmware/efi/efivars
```
>- 看當前主機是用何種方式開機 UEFI /BIOS
>>- 如果沒有以下資料夾，那就是用 BIOS 開機，反之是用 UEFI 開機
## § Lins Script 原始碼



## ※ Script 簡易使用法
- Download script
```
wget raw.githubusercontent.com/Frankswde/Archlinux2020/master/Arch_install.sh
```
- Usage
  - 要先給 script執行權限
  - 執行script前要根據需求更改disk partition大小
  - 執行script中需要填寫域名、用戶名及密碼等
  - 執行script結束後即可正常使用
  - 桌面環境可在重啟後按需要安裝