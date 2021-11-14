import SimpleNFTMarketplace from "../../../contracts/Project/SimpleNFTMarketplace.cdc"
import SimpleNFT from "../../../contracts/Project/SimpleNFT.cdc"

// Needs to be called every time a user comes into a new tenant of this contract
transaction(tenantOwner: Address, ids: [UInt64], price: UFix64, simpleNFTTenantOwner: Address) {

    let TenantID: String
    let SaleCollection: &SimpleNFTMarketplace.SaleCollection

    prepare(signer: AuthAccount) {
        self.TenantID = tenantOwner.toString()
                        .concat(".")
                        .concat(SimpleNFTMarketplace.getType().identifier)

        let Package = signer.borrow<&SimpleNFTMarketplace.Package>(from: SimpleNFTMarketplace.PackageStoragePath)
                        ?? panic("Could not borrow the signer's Package.")

        self.SaleCollection = Package.borrowSaleCollection(tenantID: self.TenantID)
    }

    execute {
        let simpleNFTTenantID = simpleNFTTenantOwner.toString()
                        .concat(".")
                        .concat(SimpleNFT.getType().identifier)
                        
        self.SaleCollection.listForSale(simpleNFTTenantID: simpleNFTTenantID, ids: ids, price: price)
        log("Listed all the NFTs for Sale.")
    }
}

