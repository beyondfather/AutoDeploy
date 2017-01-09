
package main

import (
	"errors"
	"fmt"

	"github.com/hyperledger/fabric/core/chaincode/shim"
)

// SimpleChaincode example simple Chaincode implementation
type SimpleChaincode struct {
}

func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface, function string, args []string) ([]byte, error) {
	var err error
	err = stub.PutState("Hello", []byte("World"))
	if err != nil {
		return nil, err
	}

	return nil, nil
}

// Transaction makes payment of X units from A to B
func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface, function string, args []string) ([]byte, error) {

	var err error

	N := args[0]
	Nval := args[1]
	err = stub.PutState(N, []byte(Nval))
	if err != nil {
		return nil, err
	}

	return nil, nil

}

// Deletes an entity from state
func (t *SimpleChaincode) delete(stub shim.ChaincodeStubInterface, args []string) ([]byte, error) {
	var err error
	N := args[0]

	err = stub.DelState(N)
	if err != nil {
		return nil, errors.New("刪除失敗")
	}

	return nil, nil
}

// Query callback representing the query of a chaincode
func (t *SimpleChaincode) Query(stub shim.ChaincodeStubInterface, function string, args []string) ([]byte, error) {
	var err error
	N := args[0]

	Nvalbytes, err := stub.GetState(N)
	if err != nil {
		jsonResp := "{\"錯誤\":\"取得  N  失敗\"}"
		return nil, errors.New(jsonResp)
	}


	jsonResp := "{\"Name\":\"" + N + "\",\"Amount\":\"" + string(Nvalbytes) + "\"}"
	fmt.Printf("Query Response:%s\n", jsonResp)
	return Nvalbytes, nil
}

func main() {

	err := shim.Start(new(SimpleChaincode))
	if err != nil {
		fmt.Printf("Error starting Simple chaincode: %s", err)
	}
}
