import SimpleNFT from "../../../contracts/Project/SimpleNFT.cdc"

pub fun main(account: Address): String {
    return SimpleNFT.clientTenantID(account: account)
}