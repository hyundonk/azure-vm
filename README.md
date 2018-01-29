## Azure Virtual Machine 생성 

1. PowerShell을 이용하여 VM 생성

     | 파일    | 실행파일 | Notes |
     | -------- | -----------------  | ---- |
     | Windows 2016 datacenter VM 생성 |`powershell/create_winvm.ps1`      | 
     | Linux Ubuntu VM 생성     | `powershell/create_linuxvm.ps1`              | ssh 인증은 인증키를 사용        |

    Linux Ubuntu VM 생성 script 실행 예제  
     ``./create_linuxvm.ps1 username=azureuser publicKeyPath="C:\Users\Azure\.ssh\id_rsa.pub" ``

