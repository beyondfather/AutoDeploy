#/bin/bash

while [[ $# -gt 1 ]]
do
key="$1"
number=4
mode="noops"

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
    --event)
    event=true
    ;;
    -e)
    evn="$evn -e $2 "
    shift
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
echo -e "\033[36m [remove old vp container] \033[0m"

for  kill in `docker ps -a |grep 'vp'|awk '{print $1}'` ; do
    
    docker rm -f $kill;
done
for  kill in `docker ps -a |grep 'dev'|awk '{print $1}'` ; do
    
    docker rm -f $kill;
done

echo -e "\033[36m [remove old image] \033[0m"
docker rmi hyperledger/fabric-peer:latest
docker rmi hyperledger/fabric-baseimage:latest
docker images |awk '{print $1}'|grep 'dev'|xargs docker rmi


echo -e "\033[36m [run temp container] \033[0m"
containerID=`docker run -idt $Aimage`
echo $containerID


echo -e "\033[36m [copy folder] \033[0m"
if [[ $chaincodefolder == "" ]] ; then
    docker cp ./mychaincode $containerID:/opt/gopath/src/github.com/mychaincode;
else
    docker cp ./$chaincodefolder $containerID:/opt/gopath/src/github.com/mychaincode;
fi



echo -e "\033[36m [commit temp container] \033[0m"
newimageID=`docker commit $containerID|cut -d : -f 2`
echo $newimageID


echo -e "\033[36m [remove temp container] \033[0m"
docker rm -f $containerID


echo -e "\033[36m [tag to new image] \033[0m"
docker tag $newimageID hyperledger/fabric-peer:latest
docker tag $newimageID hyperledger/fabric-baseimage:latest



if [[ $mode == "noops" ]] ; then

    echo -e "\033[36m [run hyperledger/fabric-peer:latest] \033[0m"
    containerID=`docker run -idt -p 7050:7050 -p 7051:7051 --name=vp0 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e CORE_VM_ENDPOINT=unix:///var/run/docker.sock \
    -e CORE_LOGGING_LEVEL=debug  $evn \
    hyperledger/fabric-peer:latest`
    echo "The new image ID :" $containerID



    echo -e "\033[36m [run peer node] \033[0m"
    peerIP=`docker exec -it $containerID ifconfig |grep Bcast | awk '{print $2}' | sed 's/addr://'|sed 's/\./\\./g'`
    ( docker exec -t $containerID /bin/bash -c "export CORE_PEER_ADDRESS="$peerIP":7051 && peer node start" >log-vp0 ) &
    echo -e "\033[33m [*]\033[0m if you whan \033[33mwatch\033[0m log ,please open new tty run \033[33m\`cat log-vp0\`\033[0m ";

elif [[ $mode == "pbft" ]] ; then
    count=0
    
    echo -e "\033[36m [run hyperledger/fabric-peer:latest] \033[0m"
    containerID=`docker run -idt -p $(( count * 1000 + 7050 )):7050 -p $(( count * 1000 + 7051 )):7051 \
        --name=vp$count \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -e CORE_VM_ENDPOINT=unix:///var/run/docker.sock \
        -e CORE_LOGGING_LEVEL=debug \
        -e CORE_PEER_ID=vp0 \
        -e CORE_PEER_NETWORKID=dev \
        -e CORE_PEER_VALIDATOR_CONSENSUS_PLUGIN=pbft \
        -e CORE_PEER_ADDRESSAUTODETECT=true \
        -e CORE_PBFT_GENERAL_N=$(( number )) \
        -e CORE_PBFT_GENERAL_MODE=batch \
        -e CORE_PBFT_GENERAL_TIMEOUT_REQUEST=10s $evn \
        hyperledger/fabric-peer:latest`
    echo "The new image vp$count ID :" $containerID
    peerIP=`docker exec -it $containerID ifconfig |grep Bcast | awk '{print $2}' | sed 's/addr://'|sed 's/\./\\./g'`
    ( docker exec -t $containerID /bin/bash -c "export CORE_PEER_ADDRESS="$peerIP":7051 && peer node start" >log-vp0 ) &
    echo -e "\033[33m [*]\033[0m if you whan \033[33mwatch\033[0m log ,please open new tty run \033[33m\`cat log-vp$count\`\033[0m ";
    number=`expr $number - 1 `
    while [[ $count -lt $number ]]; do
        count=`expr $count + 1 `

        vp=`docker run -idt -p $(( count * 1000 + 7050 )):7050 -p $(( count * 1000 + 7051 )):7051 \
            --name=vp$count \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -e CORE_VM_ENDPOINT=unix:///var/run/docker.sock \
            -e CORE_LOGGING_LEVEL=debug \
            -e CORE_PEER_ID=vp$count \
            -e CORE_PEER_NETWORKID=dev \
            -e CORE_PEER_VALIDATOR_CONSENSUS_PLUGIN=pbft \
            -e CORE_PEER_ADDRESSAUTODETECT=true \
            -e CORE_PBFT_GENERAL_N=$(( number + 1 )) \
            -e CORE_PBFT_GENERAL_MODE=batch \
            -e CORE_PBFT_GENERAL_TIMEOUT_REQUEST=10s \
            -e CORE_PEER_DISCOVERY_ROOTNODE=$peerIP:7051 $evn \
            hyperledger/fabric-peer:latest`
        echo "The new image vp$count ID :" $vp
        vpSelfIP=`docker exec -it $vp ifconfig |grep Bcast | awk '{print $2}' | sed 's/addr://'|sed 's/\./\\./g'`
        ( docker exec -t $vp /bin/bash -c "export CORE_PEER_ADDRESS="$vpSelfIP":7051 && peer node start" >`echo log-vp$count` ) &
        echo -e "\033[33m [*]\033[0m if you whan \033[33mwatch\033[0m log ,please open new tty run \033[33m\`cat log-vp$count\`\033[0m ";
    done
    sleep $(($count * 3))
elif [[ $mode == "--peer-chaincodedev" ]]; then
    echo -e "\033[31m [error] \033[0m Not finish " >& 2
    exit;
else
    echo -e "\033[31m [error] \033[0m Can't find mode " >& 2
    exit;

fi









sleep 5
###########################################################################
read -p $'If all peers are realy, please keydown \033[33m [Enter] \033[0m to continue : '

export IFS="[|]"
count=0;
for var in `cat $settingfile` ; do
    count=`expr $count + 1 `
    if (( $count % 2 == 1 )) ; then continue ; fi

    if [[ `echo $var |grep deploydirectory::` != "" ]] ; then
        deploydirectory=`echo $var |grep deploydirectory::|awk -F"::" '{print $2}'`;
        echo "deploydirectory : "$deploydirectory
    else
        while read -p "In ./mychaincode,which directory to deploy ? :" deploydirectory;do if [[ $deploydirectory != "" ]] ; then break; fi done
    fi

    
    lang=`echo $var |grep lang::|awk -F"::" '{print $2}'`;
    
    if [[ $lang == "" ]] ; then
        
        while read -p "what do you use lang (golang) : " lang ;do if [[ $lang != "" ]] ; then break; fi done
    else
        echo "lang : "$lang
    fi


    function=`echo $var |grep deployfunction::|awk -F"::" '{print $2}'`;
    
    if [[ $function == "" ]] ; then
        
        while read -p "what do you use function : " function ;do if [[ $function != "" ]] ; then break; fi done
    else
        echo "function : "$function
    fi


    args=`echo $var |grep deployargs::|awk -F"::" '{print $2}'`;
    
    if [[ $args == "" ]] ; then
        
        while read -p "what do you use args : " args ;do if [[ $args != "" ]] ; then break; fi done
    else
        echo "args : "$args
    fi
    


    if [[ "${lang}" == "java" ]] ; then
        #JAVA lang run here
        docker exec -it $containerID /bin/bash -c "peer chaincode deploy \\
        -l java \\
        -p ../../mychaincode/$deploydirectory \\
        -c '{\"Function\":\""$function"\",\"Args\":["$args"]}'";
        echo -e "\n";
    else
        #GO lang run here
        docker exec -it $containerID peer chaincode deploy  \
        -p github.com/mychaincode/$deploydirectory \
        -c '{"Function":"'$function'", "Args": ['$args']}';
        echo -e "\n";
    fi
    echo -e "\n";
done

while ((1))
do
    
    while read -p "In ./mychaincode,which directory to deploy ? :" deploydirectory ;do if [[ $deploydirectory != "" ]] ; then break; fi done
    if [[ $xlang == "" ]] ; then
        while read -p "what do you use lang (golang) : " lang  ;do if [[ $lang != "" ]] ; then break; fi done
    else
        lang=$xlang ;
    fi

    while read -p "deploy parameter \"Function\" : " function  ;do if [[ $function != "" ]] ; then break; fi done
    while read -p "deploy parameter \"Args\" : " args  ;do if [[ $args != "" ]] ; then break; fi done
    
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
