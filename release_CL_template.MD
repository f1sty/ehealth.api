# New release deployment preperation checklist
- [ ] prepare release notes that should include list of all the tickets or PRs that are going to be delivered with this release.
- [ ] prepare all the release specific chekpoints: what should be checked in addition to the postman collection tests for this specifica release
- [ ] prepare all the DB scripts that should be executed and that were not included in the migrations (configurations, scopes, etc.)
- [ ] create PR with the new version of API specs in the repo https://github.com/ehealth-ua/api-spec

# todo checklist that should be used for any eHealth deployment

- [ ] define required versions of repo to the destination env.
- [ ] apply the required versions of repo to the destination env.
  - [ ] ehealth.api
  - [ ] prm.api
  - [ ] mpi.api
  - [ ] annon
  - [ ] ael_api
  - [ ] digital_signature_api
  - [ ] man_api
  - [ ] mithril_api
  - [ ] ops
  - [ ] uaddresses
  - [ ] otp_verification_api
  - [ ] nhs.auth.web
  - [ ] nhs.portal.web - TBD
  - [ ] nhs.admin.web -TBD
  - [ ] man.web
  - [ ] uaddresses.web - TBD
- [ ] IL.dictionaries - add/update if any. IDs should be the same.
- [ ] PRM.global_parameters - add/update if any. IDs should be the same
- [ ] uaddresses - add/update records if any. IDs should be the same
- [ ] GW.apis - migrate config
  - [ ] GW.apis - Exclude temp dev routes
- [ ] GW.plugins
- [ ] Mithril config
  - [ ] client_types - add/update if any changes.
  - [ ] roles - add/update if any changes.
  - [ ] user_roles - for admin fronts
  - [ ] clients for mithril.admin, nhs.admin, uaddresses.admin
  - [ ] tokens - generate new tokens with new scopes in case if new endpoints are released
  - [ ] approvals - generate or copy MIS approvals
- [ ] man templates - add/update if any. IDs should be the same
- [ ] DS - migrate certificates if any
- [ ] NHS admin config
  - [ ] set/change configuration values in case if new configuration is added or system is deployed to new environment firtst time

# post-release check-list (WIP)
- [ ] cluster metrics
- [ ] service metrics
- [ ] API health-checks
- [ ] merge PR with the new version of API specs in the repo https://github.com/ehealth-ua/api-spec
- [ ] login/sanity check of NHS admin
- [ ] login/sanity check of UAddresses admin
- [ ] manual sanity check of new deployed features (should be taken from the Release Notes)
- [ ] check backups
- [ ] check logs in kibana
- [ ] check graphana monitoring metrics
- [ ] check reports and fraud DB replication status
  - [ ] overall replication status
  - [ ] every table status
- [ ] check dictionaries
- [ ] check scopes
