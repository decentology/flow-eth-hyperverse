import IHyperverseComposable from "../Hyperverse/IHyperverseComposable.cdc"
import HyperverseModule from "../Hyperverse/HyperverseModule.cdc"
import HyperverseAuth from "../Hyperverse/HyperverseAuth.cdc"
import Registry from "../Hyperverse/Registry.cdc"

pub contract HelloWorld: IHyperverseComposable {

    /**************************************** TENANT ****************************************/

    pub var metadata: HyperverseModule.Metadata

    pub event TenantCreated(tenant: Address)
    access(contract) var tenants: @{Address: IHyperverseComposable.Tenant}
    access(contract) fun getTenant(_ tenant: Address): &Tenant? {
        if self.tenantExists(tenant) {
            let ref = &self.tenants[tenant] as auth &IHyperverseComposable.Tenant
            return ref as! &Tenant  
        }
        return nil
    }
    pub fun tenantExists(_ tenant: Address): Bool {
        return self.tenants[tenant] != nil
    }
    
    pub resource Tenant {
        pub var tenant: Address
        pub let greeting: String

        init(_ tenant: Address) {
            self.tenant = tenant

            self.greeting = "Hello, World! :D"
        }
    }

    pub fun createTenant(newTenant: AuthAccount) {
        let tenant = newTenant.address
        self.tenants[tenant] <-! create Tenant(tenant)
        emit TenantCreated(tenant: tenant)
    }

    /**************************************** FUNCTIONALITY ****************************************/

    pub event HelloWorldInitialized()

    pub fun getGreeting(_ tenant: Address): String {
        return self.getTenant(tenant)!.greeting
    }

    init() {
        self.tenants <- {}

        self.metadata = HyperverseModule.Metadata(
                            _identifier: self.getType().identifier,
                            _contractAddress: self.account.address,
                            _title: "HelloWorld", 
                            _authors: [HyperverseModule.Author(_address: 0x26a365de6d6237cd, _externalLink: "https://www.decentology.com/")], 
                            _version: "0.0.1", 
                            _publishedAt: getCurrentBlock().timestamp,
                            _externalLink: ""
                        )

        Registry.registerContract(
            proposer: self.account.borrow<&HyperverseAuth.Auth>(from: HyperverseAuth.AuthStoragePath)!, 
            metadata: self.metadata
        )

        emit HelloWorldInitialized()
    }
}