import "../components/page-panel.js";
import "../components/page-body.js";
import "../components/action-card.js";
import "../components/account-widget.js";
import "../components/text-widget.js";
import "../components/number-widget.js";
import "../components/switch-widget.js";
import "../components/array-widget.js"
import "../components/dictionary-widget.js"

import DappLib from "@decentology/dappstarter-dapplib";
import { LitElement, html, customElement, property } from "lit-element";

@customElement('rewards-harness')
export default class RewardsHarness extends LitElement {
  @property()
  title;
  @property()
  category;
  @property()
  description;

  createRenderRoot() {
    return this;
  }

  constructor(args) {
    super(args);
  }

  render() {
    let content = html`
      <page-body title="${this.title}" category="${this.category}" description="${this.description}">
      
        <action-card title="Rewards - Instance" description="Create your own Tenant" action="RewardsInstance" method="post"
          fields="signer numForReward">
          <account-widget field="signer" label="Signer">
          </account-widget>
          <text-widget field="numForReward" label="Number of NFTs for Reward" placeholder="3">
          </text-widget>
        </action-card>
      
        <action-card title="Rewards - Give Reward" description="Give Reward" action="RewardsGiveReward" method="post"
          fields="tenantOwner signer">
          <account-widget field="tenantOwner" label="Tenant Owner">
          </account-widget>
          <account-widget field="signer" label="Signer">
          </account-widget>
        </action-card>
      
        <action-card title="Rewards - Get NFT IDs" description="Get an account's NFT IDs" action="SimpleNFTGetNFTIDs"
          method="get" fields="account tenantOwner">
          <account-widget field="tenantOwner" label="Tenant Owner">
          </account-widget>
          <account-widget field="account" label="Account">
          </account-widget>
        </action-card>
      
      </page-body>
      <page-panel id="resultPanel"></page-panel>
    `;

    return content;
  }
}
