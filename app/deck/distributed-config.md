---
title: Distributed Configuration for Kong using decK

description: decK can operate on a subset of configuration instead of managing the entire configuration of {{site.base_gateway}}.

content_type: reference
layout: reference

works_on:
    - on-prem
    - konnect

products:
  - api-ops

tools:
  - deck

breadcrumbs:
  - /deck/

related_resources:
  - text: Tags reference
    url: /gateway/tags/

---

decK can operate on a subset of configuration instead of managing the entire configuration of {{site.base_gateway}}.
You can do this by breaking up the configuration into multiple files and managing them using tags.

With tags, you can use decK's `select-tag` feature to export, sync, or reset
only a subset of configuration.

## Use cases

Distributed configuration management can be very useful in a variety of scenarios. 
For example:

| Use case | Description |
|----------|-------------|
| Single Kong installation whose configuration is built by multiple teams | For example, one team manages the inventory API, while another team manages the users API. Both APIs are exposed via {{site.base_gateway}}. <br> Team Inventory needs to manage its configuration without worrying about the configuration of the other team, and vice versa. The two teams can push out configuration changes on their own schedules. |
| Very large configuration | You have a large set of entities - hundreds, maybe thousands - and it's very difficult to manage them all in one file. You can use decK to break up the configuration into different files with specific purposes. |
| Separation of consumer management | You want to declaratively manage all of the configuration for Kong except consumers and their credentials. This could be for any number of reasons: <br> - The consumers are being managed by another service <br> - The consumers are dynamically created <br> - The number of consumers is so large that it makes no sense to manage them in a declarative fashion | 

## Methods for managing distributed configuration

### Tags

Tags provide a way to associate metadata with entities
in {{site.base_gateway}}. You can also filter entities by tags on the list endpoints in {{site.base_gateway}}.

Using this feature, decK associates tags with entities and can manage a group
of entities which share a common tag(s).

When multiple tags are specified in decK, decK `AND`s those tags together,
meaning only entities containing all the tags will be managed by decK.
You can specify a combination of up to 5 tags, but we recommend using
fewer or only one tag, for performance reasons in Kong's codebase.

### Gateway dump 

You can export a subset of entities in {{site.base_gateway}} by specifying common tags
using the `--select-tag` flag.

For example, the following command generates a `kong.yaml` file with all entities 
which have both of the specified tags:

```shell
deck gateway dump --select-tag foo-tag --select-tag bar-tag
```

If you observe the file generated by decK, you will see the following section:

```yaml
_info:
  select_tags:
  - foo-tag
  - bar-tag
```

This sub-section tells decK to filter out entities containing select-tags during
a sync operation.

### Gateway sync

You don't need to specify `--select-tag` in `sync` and `diff` commands.
The commands will use the tags present in the state file and perform the diff
accordingly.

Since the state files contain the tagging information, different teams can
make updates to the part of configuration in Kong without worrying about
configuration of other teams. You no longer need to maintain Kong's
configuration in a single repository, where multiple teams need to
co-ordinate.

The `--select-tag` flag is present on those two commands for use cases where
the file cannot have `select_tags` defined inside it. It is strongly advised
that you do not supply select-tags to sync and diff commands via flags.
This is because the tag information should be part of the declarative
configuration file itself in order to provide a practical declarative file.
The tagging information and entity definitions should be present in one place,
else an error in supplying the wrong tag via the CLI can break the
configuration.

### Gateway reset

You can delete only a subset of entities sharing a tag using the `--select-tag`
flag on the `gateway reset` command.

## Troubleshooting initial setup

When you initially get started with a distributed configuration
management, you will likely run into a problem where the related entities
you would like to manage don't share a single database.

To get around this problem, you can use one of the following approaches:

- Go through each entity in Kong, and patch those entities with the common
  tag(s) you'd like, then use decK's `dump` command to export by different
  tags.
- Export the entire configuration of Kong, and divide up the configuration
  into different files. Then, add the `select_tags` info to the file.
  This will require re-creation of the database now, since decK will not
  detect any of the entities present (as they are missing the common tag).
