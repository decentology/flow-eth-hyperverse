import Tribes from "../../../contracts/Project/Tribes.cdc"

// We could technically pass in the tenantID right away, but it makes
// sense to do it through an address.

pub fun main(tenantOwner: Address): [String] {
    return Tribes.getAllTribes(tenantOwner).keys
}