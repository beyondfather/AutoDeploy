
package main

import (
	"errors"
	"fmt"
	"strconv"

	"github.com/hyperledger/fabric/core/chaincode/shim"
)

// SimpleChaincode example simple Chaincode implementation
type SimpleChaincode struct {
}

func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface, function string, args []string) ([]byte, error) {
	var err error
	err = stub.PutState("nothing", []byte(""))
	if err != nil {
		return nil, err
	}

	return nil, nil
}

// Transaction makes payment of X units from A to B
func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface, function string, args []string) ([]byte, error) {

	var N string    // Entities
	var Nval int // Asset holdings
	var err error

	N = args[0]
	Nval, err = strconv.Atoi(args[1])
	if err != nil {
		return nil, errors.New(N + " to int 轉換錯誤")
	}

	fmt.Printf("Nval = %d\n", Nval)

	err = stub.PutState(N, []byte(strconv.Itoa(Nval)))
	if err != nil {
		return nil, err
	}

	return nil, nil

}

// Deletes an entity from state
func (t *SimpleChaincode) delete(stub shim.ChaincodeStubInterface, args []string) ([]byte, error) {

	N := args[0]

	// Delete the key from the state in ledger
	err := stub.DelState(N)
	if err != nil {
		return nil, errors.New("刪除失敗")
	}

	return nil, nil
}

// Query callback representing the query of a chaincode
func (t *SimpleChaincode) Query(stub shim.ChaincodeStubInterface, function string, args []string) ([]byte, error) {
	if function != "query" {
		return nil, errors.New("function 非Query \"query\"")
	}
	var N string // Entities
	var err error


	N = args[0]

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
