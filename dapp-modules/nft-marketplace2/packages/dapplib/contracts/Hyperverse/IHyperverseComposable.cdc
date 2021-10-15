/**

## The Decentology Smart Contract Composability standard on Flow

## `IHyperverseComposable` contract interface

The interface that all multitenant/composable smart contracts should conform to.
If a user wants to deploy a new composable contract, their contract would need
to implement this contract interface.

Their contract would have to follow all the rules and naming
that the interface specifies.

## `totalTenants` UInt64

The number of Tenants that have been created.

## `clientTenants` dictionary

A dictionary that maps the Address of a client to the amount of Tenants it has
created through calling `instance`.

## `ITenant` resource interface

Defines a publically viewable interface to read the id of a Tenant resource

## `Tenant` resource

The core resource type that represents an Tenant in the smart contract.

## `instance` function

A function that all clients can call to receive an Tenant resource. The client
passes in their Address so clientTenants can get updated.

## `getTenants` function

A function that returns clientTenants

*/

pub contract interface IHyperverseComposable {

    pub var totalTenants: UInt64

    pub let TenantCollectionStoragePath: StoragePath
    pub let TenantCollectionPublicPath: PublicPath

    // Maps an address (of the customer/DappContract) to the amount
    // of tenants they have for a specific HyperverseContract.
    access(contract) var clientTenants: {Address: UInt64}

    pub resource interface ITenantID {
        pub let id: UInt64
    }

    pub resource Tenant: ITenantID {
        pub let id: UInt64
    }

    pub resource interface ITenantCollectionPublic {
        pub fun deposit(tenant: @Tenant)

        pub fun getTenantIDs(): [UInt64]
    }

    pub resource TenantCollection: ITenantCollectionPublic {
        // dictionary of Tenant conforming tenants
        pub var ownedTenants: @{UInt64: Tenant}

        // deposit takes a Tenant and adds it to the ownedTenants dictionary
        // and adds the tenantID to the key
        pub fun deposit(tenant: @Tenant)

        pub fun getTenantIDs(): [UInt64]

        pub fun borrowTenant(tenantID: UInt64): &Tenant
    }

    // instance
    // instance returns an Tenant resource.
    //
    pub fun instance(): @Tenant

    // getTenants
    // getTenants returns clientTenants.
    //
    pub fun getTenants(): {Address: UInt64}
}
