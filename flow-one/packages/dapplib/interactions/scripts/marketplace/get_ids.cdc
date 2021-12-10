import Marketplace from "../../../contracts/Project/Marketplace.cdc"

pub fun main(account: Address, tenantOwner: Address): [UInt64] {
    let accountCollection = getAccount(account).getCapability(Marketplace.SaleCollectionPublicPath)
                                .borrow<&Marketplace.SaleCollection{Marketplace.SalePublic}>()
                                ?? panic("Could not borrow the Marketplace.SaleCollection.")
    
    return accountCollection.getIDs(tenantOwner)
}