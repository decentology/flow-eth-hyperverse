import SimpleNFT from "../../../contracts/Project/SimpleNFT.cdc"

// We could technically pass in the tenantID right away, but it makes
// sense to do it through an address.

pub fun main(account: Address, tenantOwner: Address, id: UInt64): {String: String} {

    let nftCollection = getAccount(account).getCapability(/public/SimpleNFTCollection)
                            .borrow<&SimpleNFT.Collection{SimpleNFT.CollectionPublic}>()
                            ?? panic("Could not borrow the account's SimpleNFTCollection")

    return nftCollection.getMetadata(tenantOwner, id: id)
}