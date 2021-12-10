import Marketplace from "../../../contracts/Project/Marketplace.cdc"
import SimpleNFT from "../../../contracts/Project/SimpleNFT.cdc"
import FlowToken from "../../../contracts/Flow/FlowToken.cdc"
import HNonFungibleToken from "../../../contracts/Hyperverse/HNonFungibleToken.cdc"

// Needs to be called every time a user comes into a new tenant of this contract
transaction(tenantOwner: Address, id: UInt64, seller: Address) {

    let SaleCollection: &Marketplace.SaleCollection{Marketplace.SalePublic}
    let RecipientCollection: &{HNonFungibleToken.CollectionPublic}
    let FlowToken: @FlowToken.Vault

    prepare(signer: AuthAccount) {
        self.SaleCollection = getAccount(seller).getCapability(Marketplace.SaleCollectionPublicPath)
                                .borrow<&Marketplace.SaleCollection{Marketplace.SalePublic}>()
                                ?? panic("Could not borrow the seller's Marketplace.SaleCollection")
        
        self.RecipientCollection = getAccount(signer.address).getCapability(SimpleNFT.CollectionPublicPath)
                                        .borrow<&{HNonFungibleToken.CollectionPublic}>()
                                        ?? panic("Could not borrow the signer's SimpleNFT.Collection")

        let FTVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
        self.FlowToken <- FTVault.withdraw(amount: self.SaleCollection.idPrice(tenantOwner, id: id)!) as! @FlowToken.Vault
    }

    execute {
        self.SaleCollection.purchase(tenantOwner, id: id, recipient: self.RecipientCollection, buyTokens: <- self.FlowToken)
        log("Listed all the NFTs for Sale.")
    }
}