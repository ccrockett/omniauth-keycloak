# Changelog

## [v1.5.2](https://github.com/ccrockett/omniauth-keycloak/tree/v1.5.2) (2024-02-01)

[Full Changelog](https://github.com/ccrockett/omniauth-keycloak/compare/v1.5.1...v1.5.2)

**Closed issues:**

- Can we update the dependency [\#45](https://github.com/ccrockett/omniauth-keycloak/issues/45)

**Merged pull requests:**

- Loosen omniauth-oauth2 dependency restriction [\#43](https://github.com/ccrockett/omniauth-keycloak/pull/43) ([mcelaney](https://github.com/mcelaney))

## [v1.5.1](https://github.com/ccrockett/omniauth-keycloak/tree/v1.5.1) (2023-03-01)

[Full Changelog](https://github.com/ccrockett/omniauth-keycloak/compare/v1.5.0...v1.5.1)

**Merged pull requests:**

- Add ability to get params from request and pass thru to keycloak url [\#24](https://github.com/ccrockett/omniauth-keycloak/pull/24) ([ccrockett](https://github.com/ccrockett))

## [v1.5.0](https://github.com/ccrockett/omniauth-keycloak/tree/v1.5.0) (2023-03-01)

[Full Changelog](https://github.com/ccrockett/omniauth-keycloak/compare/v1.4.4...v1.5.0)

**Closed issues:**

- When in test mode, setup phase tries to fetch Keycloak configuration [\#32](https://github.com/ccrockett/omniauth-keycloak/issues/32)

**Merged pull requests:**

- Fix typo [\#34](https://github.com/ccrockett/omniauth-keycloak/pull/34) ([Kazhuu](https://github.com/Kazhuu))
- Skip fetching keycloak configuration when in testing mode [\#33](https://github.com/ccrockett/omniauth-keycloak/pull/33) ([Kazhuu](https://github.com/Kazhuu))

## [v1.4.4](https://github.com/ccrockett/omniauth-keycloak/tree/v1.4.4) (2022-07-25)

[Full Changelog](https://github.com/ccrockett/omniauth-keycloak/compare/v1.4.3...v1.4.4)

**Merged pull requests:**

- Fix NoMethodError when querying for JSON Web keys [\#31](https://github.com/ccrockett/omniauth-keycloak/pull/31) ([Kazhuu](https://github.com/Kazhuu))

## [v1.4.3](https://github.com/ccrockett/omniauth-keycloak/tree/v1.4.3) (2022-07-24)

[Full Changelog](https://github.com/ccrockett/omniauth-keycloak/compare/v1.4.2...v1.4.3)

**Fixed bugs:**

- Error: uninitialized constant OmniAuth::Strategies::KeycloakOpenId::MultiJson after gem update [\#30](https://github.com/ccrockett/omniauth-keycloak/issues/30)

## [v1.4.2](https://github.com/ccrockett/omniauth-keycloak/tree/v1.4.2) (2022-06-14)

[Full Changelog](https://github.com/ccrockett/omniauth-keycloak/compare/v1.4.1...v1.4.2)

**Closed issues:**

- Adjust endpoints to updated Keycloak paths [\#29](https://github.com/ccrockett/omniauth-keycloak/issues/29)
- Expose id\_token inside extra hash of auth hash [\#25](https://github.com/ccrockett/omniauth-keycloak/issues/25)

**Merged pull requests:**

- Set omniauth version to \>= 2.0 [\#28](https://github.com/ccrockett/omniauth-keycloak/pull/28) ([hobbypunk90](https://github.com/hobbypunk90))

## [v1.4.1](https://github.com/ccrockett/omniauth-keycloak/tree/v1.4.1) (2022-05-25)

[Full Changelog](https://github.com/ccrockett/omniauth-keycloak/compare/v1.4.0...v1.4.1)

**Closed issues:**

- Get Request is now Post Request [\#23](https://github.com/ccrockett/omniauth-keycloak/issues/23)
- Is the "/auth/" part mandatory in Keycloak's configuration URL? [\#19](https://github.com/ccrockett/omniauth-keycloak/issues/19)
- Keycloak reports incorrect redirect\_uri [\#14](https://github.com/ccrockett/omniauth-keycloak/issues/14)

**Merged pull requests:**

- expose id\_token inside extra hash of auth hash [\#26](https://github.com/ccrockett/omniauth-keycloak/pull/26) ([Riz-v](https://github.com/Riz-v))
- Bump bindata from 2.4.9 to 2.4.10 [\#22](https://github.com/ccrockett/omniauth-keycloak/pull/22) ([dependabot[bot]](https://github.com/apps/dependabot))

## [v1.4.0](https://github.com/ccrockett/omniauth-keycloak/tree/v1.4.0) (2021-12-18)

[Full Changelog](https://github.com/ccrockett/omniauth-keycloak/compare/v1.3.0...v1.4.0)

**Closed issues:**

- Are there any reason to specify one certificate key to decode JWT? [\#17](https://github.com/ccrockett/omniauth-keycloak/issues/17)
- No route matches \[POST\] "/auth/keycloak\_openid" [\#15](https://github.com/ccrockett/omniauth-keycloak/issues/15)

**Merged pull requests:**

- Use JSON::JWK::Set instead of JSON::JWK [\#21](https://github.com/ccrockett/omniauth-keycloak/pull/21) ([hobbypunk90](https://github.com/hobbypunk90))
- Allow pass a Proc to the setup option when you specify a strategy [\#18](https://github.com/ccrockett/omniauth-keycloak/pull/18) ([Cambero](https://github.com/Cambero))
- Add information on how to use it to readme [\#16](https://github.com/ccrockett/omniauth-keycloak/pull/16) ([frenesim](https://github.com/frenesim))

## [v1.3.0](https://github.com/ccrockett/omniauth-keycloak/tree/v1.3.0) (2021-05-17)

[Full Changelog](https://github.com/ccrockett/omniauth-keycloak/compare/v1.2.1...v1.3.0)

**Merged pull requests:**

- Bump Omniauth dependencies to v2 [\#13](https://github.com/ccrockett/omniauth-keycloak/pull/13) ([offner](https://github.com/offner))

## [v1.2.1](https://github.com/ccrockett/omniauth-keycloak/tree/v1.2.1) (2020-12-19)

[Full Changelog](https://github.com/ccrockett/omniauth-keycloak/compare/v1.2.0...v1.2.1)

**Closed issues:**

- Dynamically load Client and Realm [\#11](https://github.com/ccrockett/omniauth-keycloak/issues/11)
- cannot load such file -- /Library/Ruby/Gems/2.6.0/gems/omniauth-keycloak-1.2.0/lib/omniauth-keycloak.rb \(LoadError\) [\#8](https://github.com/ccrockett/omniauth-keycloak/issues/8)
- Release json-jwt version restriction change [\#5](https://github.com/ccrockett/omniauth-keycloak/issues/5)

**Merged pull requests:**

- Raise errors on setup failure and logging with OmniAuth::Strategy::log method [\#10](https://github.com/ccrockett/omniauth-keycloak/pull/10) ([alexpetrov](https://github.com/alexpetrov))
- Bump json from 2.1.0 to 2.3.1 [\#9](https://github.com/ccrockett/omniauth-keycloak/pull/9) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump rack from 2.2.2 to 2.2.3 [\#7](https://github.com/ccrockett/omniauth-keycloak/pull/7) ([dependabot[bot]](https://github.com/apps/dependabot))

## [v1.2.0](https://github.com/ccrockett/omniauth-keycloak/tree/v1.2.0) (2020-05-28)

[Full Changelog](https://github.com/ccrockett/omniauth-keycloak/compare/v1.1.0...v1.2.0)

**Merged pull requests:**

- Bump activesupport from 6.0.1 to 6.0.3.1 [\#6](https://github.com/ccrockett/omniauth-keycloak/pull/6) ([dependabot[bot]](https://github.com/apps/dependabot))
- Update rake requirement from ~\> 10.0 to ~\> 13.0 [\#4](https://github.com/ccrockett/omniauth-keycloak/pull/4) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump rack from 2.0.7 to 2.0.8 [\#2](https://github.com/ccrockett/omniauth-keycloak/pull/2) ([dependabot[bot]](https://github.com/apps/dependabot))
- Adding Devise Documentation [\#1](https://github.com/ccrockett/omniauth-keycloak/pull/1) ([masonhensley](https://github.com/masonhensley))

## [v1.1.0](https://github.com/ccrockett/omniauth-keycloak/tree/v1.1.0) (2018-12-16)

[Full Changelog](https://github.com/ccrockett/omniauth-keycloak/compare/v1.0.1...v1.1.0)

## [v1.0.1](https://github.com/ccrockett/omniauth-keycloak/tree/v1.0.1) (2018-12-16)

[Full Changelog](https://github.com/ccrockett/omniauth-keycloak/compare/v1.0.0...v1.0.1)

## [v1.0.0](https://github.com/ccrockett/omniauth-keycloak/tree/v1.0.0) (2018-12-16)

[Full Changelog](https://github.com/ccrockett/omniauth-keycloak/compare/7877c8a75f9e3f342b49bf808fa69965377d60b5...v1.0.0)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
