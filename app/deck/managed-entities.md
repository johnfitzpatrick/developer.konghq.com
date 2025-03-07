---
title: Entities Managed by decK

description: "decK manages entity configuration for {{site.base_gateway}}, including all core proxy entities."

content_type: reference
layout: reference

works_on:
    - on-prem
    - konnect

products:
  - api-ops

tools:
  - deck
related_resources:
  - text: Customize decK object defaults
    url:  /how-to/custom-deck-object-defaults/
---



decK manages entity configuration for {{site.base_gateway}}, including all core proxy entities.

It does not manage {{site.base_gateway}} configuration parameters in `kong.conf`, or content and configuration for the Dev Portal. 

decK can create Workspaces and manage entities in a given Workspace. 
However, decK can't delete Workspaces, and it can't update multiple Workspaces simultaneously.
See the [Workspace](/gateway/entities/workspace/) documentation for more information. 


## Managed entities

{% feature_table %}
columns:
  - title: Managed by decK
    key: managed
features:
  - title: Services
    url: /gateway/entities/service/
    managed: true
  - title: Routes
    url: /gateway/entities/route/
    managed: true
  - title: Consumers
    url: /gateway/entities/consumer/
    managed: true
  - title: Plugins
    url: /gateway/entities/plugin/
    managed: true
  - title: Certificates
    managed: true
  - title: CA Certificates
    managed: true
  - title: SNIs
    managed: true
  - title: Upstreams
    url: /gateway/entities/upstream/
    managed: true
  - title: Targets
    url: /gateway/entities/target/
    managed: true
  - title: Vaults
    managed: true
  - title: Keys and key sets
    managed: false
  - title: Licenses
    managed: false
  - title: Workspaces
    url: /gateway/entities/workspace/
    managed: true
  - title: RBAC roles and endpoint permissions
    managed: true
  - title: RBAC groups and admins
    managed: false
  - title: Developers
    managed: false
  - title: Consumer groups
    url: /gateway/entities/consumer-group/
    managed: false
  - title: Event hooks
    url: /gateway/entities/event-hook/
    managed: false
  - title: Keyring and data encryption
    managed: false
{% endfeature_table %}

{:.info}
> decK doesn't manage documents (`document_objects`) related to Services. That means they will not be included when performing a `deck gateway dump` or `deck gateway sync` action. If you attempt to delete a service that has an associated document via decK, it will fail.
