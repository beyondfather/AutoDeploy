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