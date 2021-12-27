import HyperverseModule from "../Hyperverse/HyperverseModule.cdc"
import IHyperverseComposable from "../Hyperverse/IHyperverseComposable.cdc"

pub contract EmeraldAuthBot: IHyperverseComposable {

    /**************************************** FUNCTIONALITY ****************************************/

    pub let HeadmasterStoragePath: StoragePath

    pub event AddedGuild(_ tenant: Address, guildID: String)

    pub struct GuildInfo {
        pub var guildID: String
        pub var tokenType: String
        pub var contractName: String
        pub var contractAddress: Address
        pub var number: Int
        pub var path: String 
        pub var role: String
        pub var mintURL: String

        init(_guildID: String, _tokenType: String, _contractName: String, _contractAddress: Address, _number: Int, _path: String, _role: String, _mintURL: String) {
            self.guildID = _guildID
            self.tokenType = _tokenType
            self.contractName = _contractName
            self.contractAddress = _contractAddress
            self.number = _number
            self.path = _path
            self.role = _role
            self.mintURL = _mintURL
        }
    }

    pub resource Headmaster {
        pub let tenant: Address
        pub fun addGuild(guildID: String, tokenType: String, contractName: String, contractAddress: Address, number: Int, path: String, role: String, mintURL: String) {
            let state = EmeraldAuthBot.getTenant(self.tenant)!
            state.guilds[guildID] = GuildInfo(_guildID: guildID, _tokenType: tokenType, _contractName: contractName, _contractAddress: contractAddress, _number: number, _path: path, _role: role, _mintURL: mintURL)
            emit AddedGuild(self.tenant, guildID: guildID)
        }
        init(_ tenant: Address) { self.tenant = tenant }
    }

    pub fun getGuildInfo(_ tenant: Address, guildID: String): GuildInfo? {
        if let state = self.getTenant(tenant) {
            return state.guilds[guildID]
        } else {
            return nil
        }
    }

    pub fun getMintURL(_ tenant: Address, guildID: String): String? {
        if let state = self.getTenant(tenant) {
            return state.guilds[guildID]?.mintURL
        } else {
            return nil
        }
    }

    pub fun getGuildIDs(_ tenant: Address): [String] {
        if let state = self.getTenant(tenant) {
            return state.guilds.keys
        } else {
            return []
        }
    }

    /**************************************** METADATA & TENANT ****************************************/

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
        access(contract) var guilds: {String: GuildInfo}
        
        init(_ tenant: Address) {
            self.tenant = tenant
            self.guilds = {}
        }
    }

    pub fun createTenant(newTenant: AuthAccount) {
        let tenant = newTenant.address
        self.tenants[tenant] <-! create Tenant(tenant)
        emit TenantCreated(tenant: tenant)

        newTenant.save(<- create Headmaster(tenant), to: self.HeadmasterStoragePath)
    }

    init() {
        self.HeadmasterStoragePath = /storage/EmeraldAuthBotHeadmaster
        self.tenants <- {}

        self.metadata = HyperverseModule.Metadata(
                            _identifier: self.getType().identifier,
                            _contractAddress: self.account.address,
                            _title: "EmeraldAuthBot",
                            _authors: [HyperverseModule.Author(_address: 0x6c0d53c676256e8c, _externalURI: "https://twitter.com/jacobmtucker")],
                            _version: "0.0.1",
                            _publishedAt: getCurrentBlock().timestamp,
                            externalURI: "https://emerald-city.netlify.app/"
                        )
    }
}