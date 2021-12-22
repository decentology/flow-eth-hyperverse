import IHyperverseComposable from "../Hyperverse/IHyperverseComposable.cdc"
import HyperverseModule from "../Hyperverse/HyperverseModule.cdc"
import HNonFungibleToken from "../Hyperverse/HNonFungibleToken.cdc"
import FlowToken from "../Flow/FlowToken.cdc"
import FungibleToken from "../Flow/FungibleToken.cdc"
import HyperverseAuth from "../Hyperverse/HyperverseAuth.cdc"
import Registry from "../Hyperverse/Registry.cdc"

pub contract Marketplace: IHyperverseComposable {

    /**************************************** FUNCTIONALITY ****************************************/

    pub event MarketplaceInitialized()
    pub event ForSale(id: UInt64, price: UFix64)
    pub event NFTPurchased(id: UInt64, price: UFix64)
    pub event SaleWithdrawn(id: UInt64)

    pub resource interface SalePublic {
        pub fun purchase(_ tenant: Address, id: UInt64, recipient: &{HNonFungibleToken.CollectionPublic}, buyTokens: @FlowToken.Vault)
        pub fun idPrice(_ tenant: Address, id: UInt64): UFix64?
        pub fun getIDs(_ tenant: Address): [UInt64]
    }

    pub struct SaleCollectionData {
        pub(set) var forSale: {UInt64: UFix64}
        pub(set) var NFTCollection: Capability<&HNonFungibleToken.Collection>
        init(_NFTCollection: Capability<&HNonFungibleToken.Collection>) { 
            self.forSale = {} 
            self.NFTCollection = _NFTCollection
        }
    }

    pub let SaleCollectionStoragePath: StoragePath
    pub let SaleCollectionPublicPath: PublicPath
    pub resource SaleCollection: SalePublic {
        access(contract) var datas: {Address: SaleCollectionData}
        access(contract) fun getData(_ tenant: Address): &SaleCollectionData {
            return &self.datas[tenant]! as &SaleCollectionData 
        }
        access(self) let FlowTokenVault: Capability<&FlowToken.Vault{FungibleToken.Receiver}>

        pub fun unlistSale(_ tenant: Address, id: UInt64) {
            let data = self.getData(tenant)
            data.forSale.remove(key: id)

            emit SaleWithdrawn(id: id)
        }

        pub fun listForSale(_ tenant: Address, ids: [UInt64], price: UFix64) {
            pre {
                price > 0.0:
                    "Cannot list a NFT for 0.0"
            }
            let data = self.getData(tenant)
            let nftCollection = data.NFTCollection.borrow()!
    
            var ownedNFTs = nftCollection.getIDs(tenant)
            for id in ids {
                if (ownedNFTs.contains(id)) {
                    data.forSale.insert(key: id, price)

                    emit ForSale(id: id, price: price)
                }
            }
        }

        pub fun purchase(_ tenant: Address, id: UInt64, recipient: &{HNonFungibleToken.CollectionPublic}, buyTokens: @FlowToken.Vault) {
            pre {
                self.getData(tenant).forSale[id] != nil:
                    "No NFT matching this id for sale!"
                buyTokens.balance >= (self.getData(tenant).forSale[id]!):
                    "Not enough tokens to buy the NFT!"
            }
            let data = self.getData(tenant)
            let price = data.forSale[id]!
            let vaultRef = self.FlowTokenVault.borrow()!
            vaultRef.deposit(from: <-buyTokens)

            let nftCollection = data.NFTCollection.borrow()!
            recipient.deposit(token: <-nftCollection.withdraw(tenant, withdrawID: id))
            self.unlistSale(tenant, id: id)
            emit NFTPurchased(id: id, price: price)
        }

        pub fun idPrice(_ tenant: Address, id: UInt64): UFix64? {
            let data = self.getData(tenant)
            return data.forSale[id]
        }

        pub fun getIDs(_ tenant: Address): [UInt64] {
            let data = self.getData(tenant)
            return data.forSale.keys
        }

        pub fun addNFTCollection(_ tenant: Address, collection: Capability<&HNonFungibleToken.Collection>) {
            self.datas[tenant] = SaleCollectionData(_NFTCollection: collection)
        }

        init (_ftVault: Capability<&FlowToken.Vault{FungibleToken.Receiver}>) {
            self.datas = {}
            self.FlowTokenVault = _ftVault
        }
    }

    pub fun createSaleCollection(ftVault: Capability<&FlowToken.Vault{FungibleToken.Receiver}>): @SaleCollection {
        return <- create SaleCollection(_ftVault: ftVault)
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

        init(_ tenant: Address) {
            self.tenant = tenant
        }
    }

    pub fun createTenant(newTenant: AuthAccount) {
        let tenant = newTenant.address
        self.tenants[tenant] <-! create Tenant(tenant)
        emit TenantCreated(tenant: tenant)
    }

    init() {
        self.tenants <- {}
        self.metadata = HyperverseModule.Metadata(
                            _identifier: self.getType().identifier,
                            _contractAddress: self.account.address,
                            _title: "Marketplace", 
                            _authors: [HyperverseModule.Author(_address: 0x26a365de6d6237cd, _externalLink: "https://www.decentology.com/")], 
                            _version: "0.0.1", 
                            _publishedAt: getCurrentBlock().timestamp,
                            _externalLink: ""
                        )

        self.SaleCollectionStoragePath = /storage/MarketplaceSaleCollection
        self.SaleCollectionPublicPath = /public/MarketplaceSaleCollection

        Registry.registerContract(
            proposer: self.account.borrow<&HyperverseAuth.Auth>(from: HyperverseAuth.AuthStoragePath)!, 
            metadata: self.metadata
        )

        emit MarketplaceInitialized()
    }
}