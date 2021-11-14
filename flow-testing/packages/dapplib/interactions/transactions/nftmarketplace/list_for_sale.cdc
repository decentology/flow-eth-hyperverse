import NFTMarketplace from "../../../contracts/Project/NFTMarketplace.cdc"

// Needs to be called every time a user comes into a new tenant of this contract
transaction(tenantOwner: Address, ids: [UInt64], price: UFix64) {

    let TenantID: String
    let SaleCollection: &NFTMarketplace.SaleCollection

    prepare(signer: AuthAccount) {
        self.TenantID = tenantOwner.toString()
                        .concat(".")
                        .concat(NFTMarketplace.getType().identifier)

        let Package = signer.borrow<&NFTMarketplace.Package>(from: NFTMarketplace.PackageStoragePath)
                        ?? panic("Could not borrow the signer's Package.")

        self.SaleCollection = Package.borrowSaleCollection(tenantID: self.TenantID)
    }

    execute {
        self.SaleCollection.listForSale(ids: ids, price: price)
        log("Listed all the NFTs for Sale.")
    }
}

