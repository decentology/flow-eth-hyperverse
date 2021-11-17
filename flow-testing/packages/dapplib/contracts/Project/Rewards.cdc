import IHyperverseComposable from "../Hyperverse/IHyperverseComposable.cdc"
import HyperverseModule from "../Hyperverse/HyperverseModule.cdc"
import SimpleNFT from "./SimpleNFT.cdc"
import HyperverseAuth from "../Hyperverse/HyperverseAuth.cdc"
import Registry from "../Hyperverse/Registry.cdc"

pub contract Rewards: IHyperverseComposable {

    /**************************************** TENANT ****************************************/

    pub event TenantCreated(id: String)
    pub fun clientTenantID(account: Address): String {
        return account.toString().concat(".").concat(self.getType().identifier)
    }
    access(contract) var tenants: @{String: IHyperverseComposable.Tenant}
    pub fun getTenant(account: Address): &Tenant{IHyperverseComposable.ITenant, IState} {
        let ref = &self.tenants[self.clientTenantID(account: account)] as auth &IHyperverseComposable.Tenant
        return ref as! &Tenant
    }
    access(contract) var aliases: {String: String}
    pub fun addAlias(auth: &HyperverseAuth.Auth, new: String) {
        let original = auth.owner!.address.toString()
                        .concat(".")
                        .concat(self.getType().identifier)

        self.aliases[new] = original
    }

    pub resource interface IState {
       access(contract) var recipients: {Address: Bool}
       access(contract) fun addRecipient(recipient: Address)
       pub let numForReward: Int
    }
    
    pub resource Tenant: IHyperverseComposable.ITenant, IState {
        pub let tenantID: String
        pub var holder: Address

        pub var recipients: {Address: Bool}
        pub fun addRecipient(recipient: Address) {
            self.recipients[recipient] = true
        }
        pub let numForReward: Int

        init(_tenantID: String, _holder: Address, _numForReward: Int) {
            self.tenantID = _tenantID
            self.holder = _holder
            self.recipients = {}
            self.numForReward = _numForReward
        }
    }

    // Modules
    // String : the identifier of the contract
    // UInt64 : The incremented # (from 0) for that account. For example, you want your
    // 2nd Tenant from SimpleNFT, it'd be `1`.
    pub fun instance(auth: &HyperverseAuth.Auth, numForReward: Int) {
        let tenant = auth.owner!.address
        var STenantID: String = self.clientTenantID(account: tenant)
        
        /* Dependencies */
        if SimpleNFT.getTenant(account: tenant) == nil {
            SimpleNFT.instance(auth: auth)                   
        }

        self.tenants[STenantID] <-! create Tenant(_tenantID: STenantID, _holder: tenant, _numForReward: numForReward)
        self.addAlias(auth: auth, new: STenantID)

        emit TenantCreated(id: STenantID)
    }

    /**************************************** PACKAGE ****************************************/

    pub let PackageStoragePath: StoragePath
    pub let PackagePrivatePath: PrivatePath
    pub let PackagePublicPath: PublicPath

    pub resource interface PackagePublic {
       pub fun SimpleNFTPackagePublic(): &SimpleNFT.Package{SimpleNFT.PackagePublic}

       access(contract) fun getMinterInContract(tenant: Address): &SimpleNFT.NFTMinter
    }

    // We don't need aliases in this Package
    pub resource Package: PackagePublic {
        pub let dependencies: {String: Capability<auth &IHyperverseComposable.Package>}
        pub fun SimpleNFTPackagePublic(): &SimpleNFT.Package{SimpleNFT.PackagePublic} {
            let package = self.dependencies[SimpleNFT.getType().identifier]!.borrow()!
            let ref: &SimpleNFT.Package = package as! &SimpleNFT.Package
            return ref
        }

        access(contract) fun getMinterInContract(tenant: Address): &SimpleNFT.NFTMinter {
            let package = self.dependencies[SimpleNFT.getType().identifier]!.borrow()!
            let ref: &SimpleNFT.Package = package as! &SimpleNFT.Package
            return ref.borrowMinter(tenant: tenant)
        }

        init(_auth: &HyperverseAuth.Auth) {
            self.dependencies = {}
            self.dependencies[SimpleNFT.getType().identifier] = _auth.getPackage(packageName: SimpleNFT.getType().identifier)
        }
    }

    pub fun getPackage(auth: &HyperverseAuth.Auth): @Package {
        return <- create Package(_auth: auth)
    }

    /**************************************** FUNCTIONALITY ****************************************/

    pub event RewardsInitialized()

    pub fun giveReward(tenant: Address, minterPackage: &Package{PackagePublic}, recipientPackage: &Package{PackagePublic}) {
        let state = self.getTenant(account: tenant)
        if state.recipients[recipientPackage.owner!.address] == true {
            panic("This recipient has already received a reward!")
        }
        // Proof that we need alias at the contract level so we can do that here wait nvm LUL
        let nftCollection = recipientPackage.SimpleNFTPackagePublic().borrowCollectionPublic(tenant: tenant)
        let ids = nftCollection.getIDs()
        if ids.length >= state.numForReward {
            let nftMinter = minterPackage.getMinterInContract(tenant: tenant)
            nftCollection.deposit(token: <- nftMinter.mintNFT(metadata: {"name": "Super Legendary Reward"}))
            state.addRecipient(recipient: recipientPackage.owner!.address)
        } else {
            panic("Sorry! This account needs more NFTs to get a Reward!")
        }
    }
    
    init() {
        self.tenants <- {}
        self.aliases = {}

        self.PackageStoragePath = /storage/RewardsPackage
        self.PackagePrivatePath = /private/RewardsPackage
        self.PackagePublicPath = /public/RewardsPackage

        Registry.registerContract(
            proposer: self.account.borrow<&HyperverseAuth.Auth>(from: HyperverseAuth.AuthStoragePath)!, 
            metadata: HyperverseModule.ModuleMetadata(
                _identifier: self.getType().identifier,
                _contractAddress: self.account.address,
                _title: "Rewards", 
                _authors: [HyperverseModule.Author(_address: 0x26a365de6d6237cd, _externalURI: "https://www.decentology.com/")], 
                _version: "0.0.1", 
                _publishedAt: getCurrentBlock().timestamp,
                _externalURI: "",
                _secondaryModules: [{(Address(0x26a365de6d6237cd)): "SimpleNFT"}]
            )
        )

        emit RewardsInitialized()
    }
}