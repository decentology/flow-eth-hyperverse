import IHyperverseComposable from "../Hyperverse/IHyperverseComposable.cdc"
import HyperverseModule from "../Hyperverse/HyperverseModule.cdc"
import SimpleNFT from "./SimpleNFT.cdc"
import SimpleToken from "./SimpleToken.cdc"
import HyperverseAuth from "../Hyperverse/HyperverseAuth.cdc"
import Registry from "../Hyperverse/Registry.cdc"
import HFungibleToken from "../Hyperverse/HFungibleToken.cdc"

pub contract NFTMarketplace: IHyperverseComposable {

    /**************************************** TENANT ****************************************/

    pub event TenantCreated(id: String)
    pub fun clientTenantID(account: Address): String {
        return account.toString().concat(".").concat(self.getType().identifier)
    }
    access(contract) var tenants: @{String: IHyperverseComposable.Tenant}
    pub fun tenantExists(account: Address): Bool {
        return self.tenants[self.clientTenantID(account: account)] != nil
    }
    pub fun getTenant(account: Address): &Tenant {
        let ref = &self.tenants[self.clientTenantID(account: account)] as auth &IHyperverseComposable.Tenant
        return ref as! &Tenant
    }
    
    pub resource Tenant: IHyperverseComposable.ITenant {
        pub let tenantID: String
        pub var holder: Address

        init(_tenantID: String, _holder: Address) {
            self.tenantID = _tenantID
            self.holder = _holder
        }
    }

    pub fun instance(auth: &HyperverseAuth.Auth) {
        let tenant = auth.owner!.address
        var STenantID: String = self.clientTenantID(account: tenant)
        
        /* Dependencies */
        if !SimpleToken.tenantExists(account: tenant) {
            SimpleToken.instance(auth: auth, initialSupply: 0.0)               
        }

        if !SimpleNFT.tenantExists(account: tenant) {
            SimpleNFT.instance(auth: auth)                   
        }

        self.tenants[STenantID] <-! create Tenant(_tenantID: STenantID, _holder: tenant)
        
        emit TenantCreated(id: STenantID)
    }

    /**************************************** PACKAGE ****************************************/

    pub let PackageStoragePath: StoragePath
    pub let PackagePrivatePath: PrivatePath
    pub let PackagePublicPath: PublicPath
   
    pub resource interface PackagePublic {
       pub fun borrowSaleCollectionPublic(tenant: Address): &SaleCollection{SalePublic}
    }
    
    pub resource Package: PackagePublic {
        // pub let SimpleNFTPackage: Capability<&SimpleNFT.Package>
        // pub let SimpleTokenPackage: Capability<&SimpleToken.Package>
        pub let auth: Capability<&HyperverseAuth.Auth>

        pub var salecollections: @{Address: SaleCollection}

        pub fun borrowSaleCollection(tenant: Address): &SaleCollection {
            if self.salecollections[tenant] == nil {
                self.salecollections[tenant] <-! create SaleCollection(tenant, _auth: self.auth)
            }
            return &self.salecollections[tenant] as &SaleCollection
        }
        pub fun borrowSaleCollectionPublic(tenant: Address): &SaleCollection{SalePublic} {
            return self.borrowSaleCollection(tenant: tenant)
        }

        init(
            _auth: Capability<&HyperverseAuth.Auth>
            ) 
        {
            // self.SimpleNFTPackage = _SimpleNFTPackage
            // self.SimpleTokenPackage = _SimpleTokenPackage
            self.salecollections <- {} 
            self.auth = _auth
        }

        destroy() {
            destroy self.salecollections
        }
    }

    pub fun getPackage(auth: Capability<&HyperverseAuth.Auth>): @Package {
        // pre {
        //     SimpleNFTPackage.borrow() != nil: "This is not a correct SimpleNFT.Package! Or you don't have one yet."
        // }
        return <- create Package(_auth: auth)
    }

    /**************************************** FUNCTIONALITY ****************************************/

    pub event NFTMarketplaceInitialized()

    pub event ForSale(id: UInt64, price: UFix64)

    pub event NFTPurchased(id: UInt64, price: UFix64)

    pub event SaleWithdrawn(id: UInt64)

    pub resource interface SalePublic {
        pub fun purchase(id: UInt64, recipient: &SimpleNFT.Collection{SimpleNFT.CollectionPublic}, buyTokens: @HFungibleToken.Vault)
        pub fun idPrice(id: UInt64): UFix64?
        pub fun getIDs(): [UInt64]
    }

    pub resource SaleCollection: SalePublic {
        pub let tenant: Address
        pub var forSale: {UInt64: UFix64}
        access(self) let SimpleTokenPackage: Capability<&SimpleToken.Package>
        access(self) let SimpleNFTPackage: Capability<&SimpleNFT.Package>

        init (_ tenant: Address, _auth: Capability<&HyperverseAuth.Auth>) {
            self.tenant = tenant
            self.forSale = {}
            self.SimpleTokenPackage = _auth.borrow()!.getPackage(packageName: SimpleToken.getType().identifier) as! Capability<&SimpleToken.Package>
            self.SimpleNFTPackage = _auth.borrow()!.getPackage(packageName: SimpleNFT.getType().identifier) as! Capability<&SimpleNFT.Package>
            
        }

        pub fun unlistSale(id: UInt64) {
            self.forSale[id] = nil

            emit SaleWithdrawn(id: id)
        }

        pub fun listForSale(ids: [UInt64], price: UFix64) {
            pre {
                price > 0.0:
                    "Cannot list a NFT for 0.0"
            }
            var ownedNFTs = self.SimpleNFTPackage.borrow()!.borrowCollection(tenant: self.tenant).getIDs()
            for id in ids {
                if (ownedNFTs.contains(id)) {
                    self.forSale[id] = price

                    emit ForSale(id: id, price: price)
                }
            }
        }

        pub fun purchase(id: UInt64, recipient: &SimpleNFT.Collection{SimpleNFT.CollectionPublic}, buyTokens: @HFungibleToken.Vault) {
            pre {
                buyTokens.isInstance(Type<@SimpleToken.Vault>()):
                    "Not a SimpleToken Vault"
                self.forSale[id] != nil:
                    "No NFT matching this id for sale!"
                buyTokens.balance >= (self.forSale[id]!):
                    "Not enough tokens to buy the NFT!"
            }

            let price = self.forSale[id]!
            let vaultRef = self.SimpleTokenPackage.borrow()!.borrowVaultPublic(tenant: self.tenant)
            vaultRef.deposit(from: <-buyTokens)
            let token <- self.SimpleNFTPackage.borrow()!.borrowCollection(tenant: self.tenant).withdraw(withdrawID: id)
            recipient.deposit(token: <-token)
            self.unlistSale(id: id)
            emit NFTPurchased(id: id, price: price)
        }

        pub fun idPrice(id: UInt64): UFix64? {
            return self.forSale[id]
        }

        pub fun getIDs(): [UInt64] {
            return self.forSale.keys
        }
    }

    init() {
        self.tenants <- {}

        self.PackageStoragePath = /storage/NFTMarketplacePackage
        self.PackagePrivatePath = /private/NFTMarketplacePackage
        self.PackagePublicPath = /public/NFTMarketplacePackage

        Registry.registerContract(
            proposer: self.account.borrow<&HyperverseAuth.Auth>(from: HyperverseAuth.AuthStoragePath)!, 
            metadata: HyperverseModule.ModuleMetadata(
                _identifier: self.getType().identifier,
                _contractAddress: self.account.address,
                _title: "NFT Marketplace", 
                _authors: [HyperverseModule.Author(_address: 0x26a365de6d6237cd, _externalLink: "https://www.decentology.com/")], 
                _version: "0.0.1", 
                _publishedAt: getCurrentBlock().timestamp,
                _externalLink: "",
                _secondaryModules: [{Address(0x26a365de6d6237cd): "SimpleNFT", 0x26a365de6d6237cd: "SimpleToken"}]
            )
        )

        emit NFTMarketplaceInitialized()
    }
}