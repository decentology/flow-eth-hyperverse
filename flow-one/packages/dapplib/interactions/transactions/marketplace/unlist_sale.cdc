import Marketplace from "../../../contracts/Project/Marketplace.cdc"

// Needs to be called every time a user comes into a new tenant of this contract
transaction(tenantOwner: Address, id: UInt64) {

    let SaleCollection: &Marketplace.SaleCollection

    prepare(signer: AuthAccount) {
        self.SaleCollection = signer.borrow<&Marketplace.SaleCollection>(from: Marketplace.SaleCollectionStoragePath)
                        ?? panic("Could not borrow the signer's Marketplace.SaleCollection")
    }

    execute {
        self.SaleCollection.unlistSale(tenantOwner, id: id)
        log("Unlisted the NFT with the id from Sale.")
    }
}