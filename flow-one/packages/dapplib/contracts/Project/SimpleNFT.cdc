import IHyperverseComposable from "../Hyperverse/IHyperverseComposable.cdc"
import HyperverseModule from "../Hyperverse/HyperverseModule.cdc"
import HyperverseAuth from "../Hyperverse/HyperverseAuth.cdc"
import HNonFungibleToken from "../Hyperverse/HNonFungibleToken.cdc"
import Registry from "../Hyperverse/Registry.cdc"

pub contract SimpleNFT: HNonFungibleToken, IHyperverseComposable {

    /**************************************** FUNCTIONALITY ****************************************/

    pub event ContractInitialized()
    pub event Withdraw(tenant: Address, id: UInt64, from: Address?)
    pub event Deposit(tenant: Address, id: UInt64, to: Address?)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath
    pub let AdminStoragePath: StoragePath

    pub resource NFT {
        pub let tenant: Address
        pub let id: UInt64
        pub var metadata: {String: String}
    
        init(_ tenant: Address, _metadata: {String: String}) {
            self.id = self.uuid
            self.tenant = tenant
            self.metadata = _metadata

            let state = SimpleNFT.getTenant(tenant)!
            state.totalSupply = state.totalSupply + 1
        }
    }

    pub resource interface CollectionPublic {
        pub fun deposit(token: @HNonFungibleToken.NFT)
        pub fun getIDs(_ tenant: Address): [UInt64]
        pub fun getMetadata(_ tenant: Address, id: UInt64): {String: String}
    }

    pub resource CollectionData {
        pub(set) var ownedNFTs: @{UInt64: HNonFungibleToken.NFT}
        init() { 
            self.ownedNFTs <- {} 
        }
        destroy() { 
            destroy self.ownedNFTs 
        }
    }

    pub resource Collection: HNonFungibleToken.Receiver, HNonFungibleToken.Provider, HNonFungibleToken.CollectionPublic, CollectionPublic {
        access(contract) var datas: @{Address: HNonFungibleToken.CollectionData}
        access(contract) fun getData(_ tenant: Address): &HNonFungibleToken.CollectionData {
            if self.datas[tenant] == nil { self.datas[tenant] <-! create CollectionData() }
            return &self.datas[tenant] as &HNonFungibleToken.CollectionData 
        }

        pub fun deposit(token: @HNonFungibleToken.NFT) {
            let token <- token as! @NFT
            let id: UInt64 = token.id

            let data = self.getData(token.tenant)
            emit Deposit(tenant: token.tenant, id: id, to: self.owner?.address)
            let oldToken <- data.ownedNFTs[id] <- token
            destroy oldToken
        }

        pub fun withdraw(_ tenant: Address, withdrawID: UInt64): @HNonFungibleToken.NFT {
            let data = self.getData(tenant)
            let token <- data.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            emit Withdraw(tenant: tenant, id: token.id, from: self.owner?.address)
            return <-token
        }

        pub fun getIDs(_ tenant: Address): [UInt64] {
            let data = self.getData(tenant)
            return data.ownedNFTs.keys
        }

        pub fun borrowNFT(_ tenant: Address, id: UInt64): &HNonFungibleToken.NFT {
            let data = self.getData(tenant)
            return &data.ownedNFTs[id] as &HNonFungibleToken.NFT
        }

        pub fun getMetadata(_ tenant: Address, id: UInt64): {String: String} {
            let data = self.getData(tenant)
            let ref = &data.ownedNFTs[id] as auth &HNonFungibleToken.NFT
            let wholeNFT = ref as! &NFT
            return wholeNFT.metadata
        }

        destroy() {
            destroy self.datas
        }

        init () {
            self.datas <- {}
        }
    }

    pub fun createEmptyCollection(): @Collection { 
        return <- create Collection() 
    }

    pub resource Minter {
        pub let tenant: Address
        pub fun mintNFT(_ tenant: Address, metadata: {String: String}): @NFT {
            return <- create NFT(tenant, _metadata: metadata)
        }
        init(_ tenant: Address) { 
            self.tenant = tenant
        }
    }

    /**************************************** TENANT ****************************************/

    pub var metadata: HyperverseModule.Metadata

    pub event TenantCreated(tenant: Address)
    access(contract) var tenants: @{Address: IHyperverseComposable.Tenant}
    access(contract) fun getTenant(_ tenant: Address): &Tenant? {
        if self.tenantExists(tenant) {
            let ref = &self.tenants[tenant] as auth &IHyperverseComposable.Tenant
            return ref as! &Tenant  
        }
        return nil
    }
    pub fun tenantExists(_ tenant: Address): Bool {
        return self.tenants[tenant] != nil
    }

    pub resource Tenant {
        pub var tenant: Address
        pub(set) var totalSupply: UInt64
        
        init(_ tenant: Address) {
            self.totalSupply = 0
            self.tenant = tenant
        }
    }

    pub fun createTenant(newTenant: AuthAccount) {
        let tenant = newTenant.address
        self.tenants[tenant] <-! create Tenant(tenant)
        emit TenantCreated(tenant: tenant)

        newTenant.save(<- create Minter(tenant), to: self.MinterStoragePath)
    }

    init() {
        self.tenants <- {}
        self.metadata = HyperverseModule.Metadata(
                            _identifier: self.getType().identifier,
                            _contractAddress: self.account.address,
                            _title: "SimpleNFT", 
                            _authors: [HyperverseModule.Author(_address: 0x26a365de6d6237cd, _externalURI: "https://www.decentology.com/")], 
                            _version: "0.0.1", 
                            _publishedAt: getCurrentBlock().timestamp,
                            _externalURI: ""
                        )

        self.CollectionStoragePath = /storage/SimpleNFTCollection
        self.CollectionPublicPath = /public/SimpleNFTCollection
        self.MinterStoragePath = /storage/SimpleNFTMinter
        self.AdminStoragePath = /storage/SimpleNFTAdmin

        Registry.registerContract(
            proposer: self.account.borrow<&HyperverseAuth.Auth>(from: HyperverseAuth.AuthStoragePath)!, 
            metadata: self.metadata
        )

         emit ContractInitialized()
    }
}