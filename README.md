把 自己的 hyperledger/fabric-peer:latest tag 成別的名字 如

docker tag hyperledger/fabric-peer:latest myfabric/lab:labtest

以上步驟只要做一次就好

然後把 要部署的chaincode資料夾 丟進mychaincode 資料夾

再來執行 ./inputchaincode.sh

輸入 myfabric/lab:labtest 或 ID (你tag的 images )

輸入chaincode的資料夾名稱 如 chaincode_example02

輸入Function 名稱 如 init

輸入Args 如 "a","150","b","240" (緊湊無空白 含雙引號 一次打完)

之後每次chaincode 有異動 執行 ./inputchaincode.sh 就好

一切都會重新部署

///////////////////

增加 參數

-f 載入設定檔 (setting.txt)

-l chaincode語言

-i 來源image 

-m 選擇mode pbft,noops

-e 設定環境屬性

-n pbft節點數量

預計目標

自由選擇 pbft,noops, *--peer-chaincodedev

自由選擇 幾個節點 和 *非驗證節點

*選擇 membersvrc 使用

如 ./inputchaincode.sh -f setting.txt -n pbft 
