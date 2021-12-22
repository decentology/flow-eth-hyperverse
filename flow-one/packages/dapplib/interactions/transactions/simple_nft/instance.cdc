import SimpleNFT from "../../../contracts/Project/SimpleNFT.cdc"
import HyperverseAuth from "../../../contracts/Hyperverse/HyperverseAuth.cdc"

transaction() {

    prepare(signer: AuthAccount) {
        SimpleNFT.createTenant(newTenant: signer)
    }

    execute {
        
        log("Create a new instance of a SimpleNFT Tenant.")
    }
}
