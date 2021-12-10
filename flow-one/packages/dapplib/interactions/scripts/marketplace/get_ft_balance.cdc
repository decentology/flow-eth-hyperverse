import FlowToken from "../../../contracts/Flow/FlowToken.cdc"
import FungibleToken from "../../../contracts/Flow/FungibleToken.cdc"

pub fun main(account: Address): UFix64 {
    let vault = getAccount(account).getCapability(/public/flowTokenBalance)
                                .borrow<&FlowToken.Vault{FungibleToken.Balance}>()
                                ?? panic("Could not borrow the FlowToken Vault.")
    
    return vault.balance
}