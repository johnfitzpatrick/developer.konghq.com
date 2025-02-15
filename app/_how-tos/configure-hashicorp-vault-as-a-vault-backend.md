---
title: Configure Hashicorp Vault as a vault backend
content_type: how_to
related_resources:
  - text: Rotate secrets in Hashicorp Vault with {{site.base_gateway}}
    url: /how-to/rotate-secrets-in-hashicorp-vault/
  - text: Secrets management
    url: /gateway/secrets-management/

products:
    - gateway

tier: enterprise

works_on:
    - on-prem

min_version:
  gateway: '3.4'

entities: 
  - vault

tags:
    - security
    - secrets-management

tldr:
    q: How can I access HashiCorp Vaults secrets in {{site.base_gateway}}? 
    a: |
      [Install and run HashiCorp Vault](https://developer.hashicorp.com/vault/tutorials/get-started/install-binary#install-vault) in dev mode or self-managed. [Write a secret to the Vault](https://developer.hashicorp.com/vault/tutorials/secrets-management/versioned-kv?variants=vault-deploy%3Aselfhosted#write-secrets) like `vault kv put secret/customer/acme name="ACME Inc."`. Save your HashiCorp Vault token, host, port, protocol, and KV secrets engine version and use them to configure a {{site.base_gateway}} [Vault entity](/gateway/entities/vault/). Use `{vault://hashicorp-vault/customer/acme/name}` to reference the secret in any referenceable field.

tools:
    - deck

prereqs:
  inline: 
    - title: HashiCorp Vault
      content: |
        This how-to requires you to have a dev mode or self-managed HashiCorp Vault. The following instructions will guide you through configuring a HashiCorp Vault in dev mode with the resources you need to integrate it with {{site.base_gateway}}.

        {:.warning}
        > **Important:** This tutorial uses the literal `root` string as your token, which should only be used in testing and development environments.

        1. [Install HashiCorp Vault](https://developer.hashicorp.com/vault/tutorials/get-started/install-binary#install-vault).
        1. In a terminal, start your Vault dev server with `root` as your token.
          ```
          vault server -dev -dev-root-token-id root
          ```
        1. In the output from the previous command, copy the `VAULT_ADDR` to export.
        1. In a new terminal window, export your `VAULT_ADDR` as an environment variable.
        1. Verify that your Vault is running correctly:
          ```
          vault status
          ```
        1. Authenticate with Vault:
          ```
          vault login root
          ```
        1. [Create the `admin-policy.hcl` policy file](https://developer.hashicorp.com/vault/tutorials/policies/policies#write-a-policy). This contains the [permissions you need to create and use secrets](https://developer.hashicorp.com/vault/tutorials/secrets-management/versioned-kv#policy-requirements).
        1. Upload the policy you just created:
          ```
          vault policy write admin admin-policy.hcl
          ```
        1. [Verify that you are using the `v2` secrets engine](https://developer.hashicorp.com/vault/tutorials/secrets-management/versioned-kv?variants=vault-deploy%3Aselfhosted#check-the-kv-secrets-engine-version):
          ```
          vault read sys/mounts/secret
          ```
          The `options` key should have the `map[version:2]` value.
        1. [Write the secret](https://developer.hashicorp.com/vault/tutorials/secrets-management/versioned-kv?variants=vault-deploy%3Aselfhosted#write-secrets):
          ```
          vault kv put secret/customer/acme name="ACME Inc."
          ```
      icon_url: /assets/icons/hashicorp.svg

cleanup:
  inline:
    - title: Clean up HashiCorp Vault
      include_content: cleanup/third-party/hashicorp
      icon_url: /assets/icons/hashicorp.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## 1. Create a Vault entity for HashiCorp Vault 

In this tutorial, we're using `host.docker.internal` as our host instead of the `localhost` that HashiCorp Vault is using because {{site.base_gateway}} is running in a container that has a different `localhost` to you.

Using decK, create a Vault entity in the `kong.yaml` file with the required parameters for HashiCorp Vault:

{% entity_example %}
type: vault
data:
  name: hcv
  prefix: hashicorp-vault
  description: Storing secrets in HashiCorp Vault
  config:
    host: host.docker.internal
    kv: v2
    mount: secret
    port: 8200
    protocol: http
    token: 'root'
{% endentity_example %}

## 2. Validate

To validate that the secret was stored correctly in HashiCorp Vault, you can call a secret from your vault using the `kong vault get` command within the Data Plane container. If the Docker container is named `kong-quickstart-gateway`, you can use the following command:

```sh
docker exec kong-quickstart-gateway kong vault get {vault://hashicorp-vault/customer/acme/name}
```

If the vault was configured correctly, this command should return the value of the secret. You can use `{vault://hashicorp-vault/customer/acme/name}` to reference the secret in any referenceable field.