---
title: Configure the Konnect Config Store vault
content_type: how_to
related_resources:
  - text: Secrets management
    url: /secrets-management/
  - text: Vault entity
    url: /gateway/entities/vault/
  - text: Store certificates in Konnect Config Store
    url: /how-to/store-certificates-in-konnect-config-store/
  - text: Store a Mistral API key as a secret in Konnect Config Store
    url: /how-to/store-a-mistral-api-key-as-a-secret-in-konnect-config-store/

products:
    - gateway

works_on:
    - konnect

entities: 
  - vault

tags:
    - security
    - secrets-management

tldr:
    q: How do I use a {{site.konnect_short_name}}-native Vault?
    a: |
      1. Use the {{site.konnect_short_name}} API to create a Config Store using the `/config-stores` endpoint.
      2. Create a {{site.konnect_short_name}} Vault using the [`/vaults/` endpoint](/api/konnect/control-planes-config/v2/#/operations/create-vault).
      3. Store your secret as a key/value pair using the `/secrets` endpoint. 
      4. Reference the secret using the Vault prefix and key (for example: `{vault://mysecretvault/secret-key}`).

faqs:
  - q: Can I reference {{site.konnect_short_name}} Config Store Vault secrets in `kong.conf`?
    a: No. You can't reference secrets stored in a {{site.konnect_short_name}} Config Store Vault in `kong.conf` because {{site.konnect_short_name}} resolves the secret after {{site.base_gateway}} connects to the control plane. For more information about the fields you can reference as secrets, see [What can be stored as a secret?](/gateway/entities/vault/#what-can-be-stored-as-a-secret).

tools:
  - konnect-api
 
cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/
---

## 1. Configure a {{site.konnect_short_name}} Config Store

Before you can configure a {{site.konnect_short_name}} Vault, you must first create a Config Store using the [Control Planes Configuration API](/api/konnect/control-planes-config/v2/#/) by sending a `POST` request to the `/config-stores` endpoint:

<!--vale off-->
{% control_plane_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/config-stores
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $KONNECT_TOKEN'
body:
    name: my-config-store
{% endcontrol_plane_request %}
<!--vale on-->

Export the Config Store ID in the response body as an environment variable so you can use it later:

```sh
export CONFIG_STORE_ID=config-store-uuid
```

## 2. Configure {{site.konnect_short_name}} as your Vault

Enable {{site.konnect_short_name}} as your vault with the [Vault entity](/gateway/entities/vault/). Send a `POST` request to the [`/vaults/`](/api/konnect/control-planes-config/v2/#/operations/create-vault) endpoint:

<!--vale off-->
{% control_plane_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/vaults/
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $KONNECT_TOKEN'
body:
    config:
      config_store_id: $CONFIG_STORE_ID
    description: Storing secrets in Konnect
    name: konnect
    prefix: mysecretvault
{% endcontrol_plane_request %}
<!--vale on-->

## 3. Store a secret in your {{site.konnect_short_name}} Vault

By storing a secret in a {{site.konnect_short_name}} Vault, you can reference it within [`kong.conf`](/gateway/manage-kong-conf/) or as a referenceable plugin fields without having to store any values in plain-text.

Store your secret by sending a `POST` request to the `/secrets` endpoint:

<!--vale off-->
{% control_plane_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/config-stores/$CONFIG_STORE_ID/secrets/
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $KONNECT_TOKEN'
body:
    key: secret-key
    value: my-secret-value
{% endcontrol_plane_request %}
<!--vale on-->

## 4. Validate

You can validate that your secret was stored correctly by sending a `GET` request to the `/secrets` endpoint:

<!--vale off-->
{% control_plane_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/config-stores/$CONFIG_STORE_ID/secrets/
status_code: 201
method: GET
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $KONNECT_TOKEN'
{% endcontrol_plane_request %}
<!--vale on-->

If your secret was successfully stored in {{site.konnect_short_name}}, the endpoint should return a `201` status code and your `secret-key` key in the output.

You can now reference your {{site.konnect_short_name}} secret in configurations as `{vault://mysecretvault/secret-key}`.