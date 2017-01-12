#/bin/bash


while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -f)
    settingfile="$2"
    shift # past argument
    ;;
    -l)
    xlang="$2"
    shift # past argument
    ;;
    -m)
    mode="$2"
    shift # past argument
    ;;
    -i)
    image="$2"
    shift # past argument
    ;;
    -n)
    number="$2"
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

if [[ -f $settingfile ]] ; then

    image=`cat $settingfile |grep image::|awk -F"::" '{print $2}'`
    chaincodefolder=`cat $settingfile |grep chaincodefolder::|awk -F"::" '{print $2}'`

    if [ $lang == ""] ; then
        lang=`cat $settingfile |grep lang::|awk -F"::" '{print $2}'`
    fi

fi

if [[ $image == "" ]] ; then
    read -p "image from : " Aimage;
else
    Aimage=$image;
fi
echo "remove old vp container"
quiet=`docker rm -f vp0`
quiet=`docker ps -a |awk '{print $2}'|grep 'dev'|xargs docker rm -f`

echo "remove old image"
quiet=`docker rmi hyperledger/fabric-peer:latest`
quiet=`docker rmi hyperledger/fabric-baseimage:latest`
quiet=`docker images |awk '{print $1}'|grep 'dev'|xargs docker rmi`

echo "run temp container"
containerID=`docker run -idt $Aimage`

echo "copy folder"
if [[ $chaincodefolder == "" ]] ; then
    docker cp ./mychaincode $containerID:/opt/gopath/src/github.com/mychaincode;
else
    docker cp ./$chaincodefolder $containerID:/opt/gopath/src/github.com/mychaincode;
fi

echo "commit temp container"
newimageID=`docker commit $containerID|cut -d : -f 2`

echo "remove temp container"
quiet=`docker rm -f $containerID`

echo "tag to new image"
quiet=`docker tag $newimageID hyperledger/fabric-peer:latest`
quiet=`docker tag $newimageID hyperledger/fabric-baseimage:latest`



echo "run hyperledger/fabric-peer:latest"
containerID=`docker run -idt -p 7050:7050 -p 7051:7051 --name=vp0 \
-v /var/run/docker.sock:/var/run/docker.sock \
-e CORE_VM_ENDPOINT=unix:///var/run/docker.sock \
hyperledger/fabric-peer:latest`
echo "the new image ID :" $containerID

#CORE_PEER_ADDRESS="$peerIP":7051 
echo "run peer node"
peerIP=`docker exec -it $containerID ifconfig |grep Bcast | awk '{print $2}' | sed 's/addr://'|sed 's/\./\\./g'`
docker exec  $containerID /bin/bash -c "export CORE_PEER_ADDRESS="$peerIP":7051 && peer node start" &

read 

export IFS="[|]"
count=0;
for var in `cat $settingfile` ; do
    count=`expr $count + 1 `
    if (( $count % 2 == 1 )) ; then continue ; fi

    if [[ `echo $var |grep deploydirectory::` != "" ]] ; then
        deploydirectory=`echo $var |grep deploydirectory::|awk -F"::" '{print $2}'`;
        echo "deploydirectory : "$deploydirectory
    else
        read -p "In ./mychaincode,which directory to deploy ? :" deploydirectory;
    fi

    
    lang=`echo $var |grep lang::|awk -F"::" '{print $2}'`;
    
    if [[ $lang == "" ]] ; then
        read -p "what do you use lang (golang) : " lang
    else
        echo "lang : "$lang
    fi


    function=`echo $var |grep deployfunction::|awk -F"::" '{print $2}'`;
    
    if [[ $function == "" ]] ; then
        read -p "what do you use function : " function
    else
        echo "function : "$function
    fi


    args=`echo $var |grep deployargs::|awk -F"::" '{print $2}'`;
    
    if [[ $args == "" ]] ; then
        read -p "what do you use args : " args
    else
        echo "args : "$args
    fi
    


    if [ "${lang}" == "java" ] ; then
        #JAVA lang run here
        docker exec -it $containerID /bin/bash -c "peer chaincode deploy \\
        -l java \\
        -p ../../mychaincode/$deploydirectory \\
        -c '{\"Function\":\""$function"\",\"Args\":["$args"]}'";
    else
        #GO lang run here
        docker exec -it $containerID peer chaincode deploy  \
        -p github.com/mychaincode/$deploydirectory \
        -c '{"Function":"'$function'", "Args": ['$args']}';
    fi
    echo -e "\n";
done

while ((1))
do
    read -p "In ./mychaincode,which directory to deploy ? :" deploydirectory
    
    if [ "${deploydirectory}" == "" ] ;then continue ; fi
    if [ $xlang == "" ]
        read -p "what do you use lang (golang) : " lang;
    else
        lang=$xlang;
    fi

    read -p "deploy parameter \"Function\" : " function
    read -p "deploy parameter \"Args\" : " args
    if [ "${lang}" == "java" ] ; then
        #JAVA lang run here
        docker exec -it $containerID /bin/bash -c "peer chaincode deploy \\
        -l java \\
        -p ../../mychaincode/$deploydirectory \\
        -c '{\"Function\":\""$function"\",\"Args\":["$args"]}'";
    else
        #GO lang run here
        docker exec -it $containerID peer chaincode deploy  \
        -p github.com/mychaincode/$deploydirectory \
        -c '{"Function":"'$function'", "Args": ['$args']}';
    fi
done
