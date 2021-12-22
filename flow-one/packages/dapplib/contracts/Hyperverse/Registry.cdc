import HyperverseModule from "./HyperverseModule.cdc"
import HyperverseAuth from "./HyperverseAuth.cdc"

pub contract Registry {
    // proposer -> module metadata
    access(contract) var proposedContracts: {Address: {String: HyperverseModule.Metadata}}
    // contract identifier -> module metadata
    access(contract) var contracts: {String: HyperverseModule.Metadata}

    pub fun retrieveContract(identifier: String): HyperverseModule.Metadata {
        return self.contracts[identifier]!
    }

    pub struct Contract {
        pub let name: String
        pub let address: Address
        pub var metadata: HyperverseModule.Metadata
        init(_name: String, _address: Address, _metadata: HyperverseModule.Metadata) {
            self.name = _name
            self.address = _address
            self.metadata = _metadata
        }
    }

    pub fun registerContract(proposer: &HyperverseAuth.Auth, metadata: HyperverseModule.Metadata) {
        Registry.proposedContracts[proposer.owner!.address] = {metadata.identifier: metadata}
    }

    pub resource Headmaster {
        pub fun verifyContract(proposer: Address, identifier: String) {
            let proposersSubmissions = Registry.proposedContracts[proposer]!
            Registry.contracts.insert(key: identifier, proposersSubmissions[identifier]!)
        }
    }

    init() {
        self.proposedContracts = {}
        self.contracts = {}

        self.account.save(<- create Headmaster(), to: /storage/HyperverseHeadmaster)
    }
} 