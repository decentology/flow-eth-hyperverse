import Tribes from "../../../contracts/Project/Tribes.cdc"

transaction(tenantOwner: Address, tribeName: String) {

    let TribesIdentity: &Tribes.Identity

    prepare(signer: AuthAccount) {
        self.TribesIdentity = signer.borrow<&Tribes.Identity>(from: Tribes.IdentityStoragePath)
                                ?? panic("Could not borrow the Tribes.Identity")
    }

    execute {
        self.TribesIdentity.joinTribe(tenantOwner, tribeName: tribeName)
        log("This signer joined a Tribe.")
    }
}

