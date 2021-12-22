import IHyperverseComposable from "../Hyperverse/IHyperverseComposable.cdc"
import HyperverseModule from "../Hyperverse/HyperverseModule.cdc"
import HyperverseAuth from "../Hyperverse/HyperverseAuth.cdc"
import HFungibleToken from "../Hyperverse/HFungibleToken.cdc"
import Registry from "../Hyperverse/Registry.cdc"

pub contract SimpleToken: IHyperverseComposable, HFungibleToken {

    /**************************************** FUNCTIONALITY ****************************************/

    pub event TokensInitialized(tenant: Address, initialSupply: UFix64)
    pub event TokensWithdrawn(tenant: Address, amount: UFix64, from: Address?)
    pub event TokensDeposited(tenant: Address, amount: UFix64, to: Address?)

    pub resource interface VaultPublic {
        pub fun deposit(from: @HFungibleToken.VaultTransferrable)
        pub fun balance(_ tenant: Address): UFix64
    }

    pub struct VaultData {
        pub(set) var balance: UFix64 
        init(_balance: UFix64) { self.balance = _balance }
    }

    pub let VaultStoragePath: StoragePath
    pub let VaultPublicPath: PublicPath
    pub resource Vault: HFungibleToken.Receiver, HFungibleToken.Provider, HFungibleToken.Balance, VaultPublic {
        access(contract) var datas: {Address: HFungibleToken.VaultData}
        access(contract) fun getData(_ tenant: Address): &HFungibleToken.VaultData {
            if self.datas[tenant] == nil { self.datas[tenant] = VaultData(_balance: 0.0) }
            return &self.datas[tenant] as &HFungibleToken.VaultData 
        }

        pub fun withdraw(_ tenant: Address, amount: UFix64): @HFungibleToken.VaultTransferrable {
            let data = self.getData(tenant)
            data.balance = data.balance - amount
            emit TokensWithdrawn(tenant: tenant, amount: amount, from: self.owner?.address)

            return <- create VaultTransferrable(tenant, _balance: amount)
        }

        pub fun deposit(from: @HFungibleToken.VaultTransferrable) {
            let vault <- from as! @VaultTransferrable
            let data = self.getData(vault.tenant)
            data.balance = data.balance + vault.balance
            emit TokensDeposited(tenant: vault.tenant, amount: vault.balance, to: self.owner?.address)

            vault.clear()
            destroy vault
        }

        pub fun balance(_ tenant: Address): UFix64 { 
            return self.getData(tenant).balance 
        }

        init() { 
            self.datas = {}
        }

        destroy() {
            for tenant in self.datas.keys {
                let state = SimpleToken.getTenant(tenant)!
                state.totalSupply = state.totalSupply - self.balance(tenant)
            }
        }
    }

    pub resource VaultTransferrable {
        pub var balance: UFix64 
        pub let tenant: Address
        access(contract) fun clear() {self.balance = 0.0}
        init(_ tenant: Address, _balance: UFix64) {
            self.balance = _balance
            self.tenant = tenant
        }
        destroy() {
            let state = SimpleToken.getTenant(self.tenant)!
            state.totalSupply = state.totalSupply - self.balance
        }
    }

    pub fun createEmptyVault(): @Vault { 
        return <- create Vault() 
    }

    pub let MinterStoragePath: StoragePath
    pub resource Minter {
        pub let tenant: Address
        pub fun mintTokens(amount: UFix64): @VaultTransferrable {
            pre {
                amount > 0.0: "Amount minted must be greater than zero."
            }
            let state = SimpleToken.getTenant(self.tenant)!
            state.totalSupply = state.totalSupply + amount

            return <- create VaultTransferrable(self.tenant, _balance: amount)
        }
        init(_ tenant: Address) { 
            self.tenant = tenant
        }
    }

    pub fun getTotalSupply(tenant: Address): UFix64 { 
        return self.getTenant(tenant)!.totalSupply 
    }

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
        pub(set) var totalSupply: UFix64

        init(_ tenant: Address) {
            self.tenant = tenant
            self.totalSupply = 0.0
        }
    }

    pub fun createTenant(newTenant: AuthAccount) {
        let tenant = newTenant.address
        self.tenants[tenant] <-! create Tenant(tenant)
        emit TenantCreated(tenant: tenant)
        emit TokensInitialized(tenant: tenant, initialSupply: 0.0)

        newTenant.save(<- create Minter(tenant), to: self.MinterStoragePath)
    }

    init() {
        self.tenants <- {}
        self.metadata = HyperverseModule.Metadata(
                            _identifier: self.getType().identifier,
                            _contractAddress: self.account.address,
                            _title: "SimpleToken", 
                            _authors: [HyperverseModule.Author(_address: 0x26a365de6d6237cd, _externalLink: "https://www.decentology.com/")], 
                            _version: "0.0.1", 
                            _publishedAt: getCurrentBlock().timestamp,
                            _externalLink: ""
                        )

        self.VaultStoragePath = /storage/SimpleTokenVault
        self.VaultPublicPath = /public/SimpleTokenVault
        self.MinterStoragePath = /storage/SimpleTokenMinter

        Registry.registerContract(
            proposer: self.account.borrow<&HyperverseAuth.Auth>(from: HyperverseAuth.AuthStoragePath)!, 
            metadata: self.metadata
        )
    }
}