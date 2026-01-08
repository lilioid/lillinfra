# E-Mail Setup Docs & Maintenance Guide

The deployed email system uses my own [mailcalf](https://git.lly.sh/lilly/mailcalf) dockerized mailserver.
It is deployed via [k8s/apps/mailserver](../k8s/apps/mailserver).

## Server data

- Mailserver name: `mail.lly.sh`
- IMAP Data:
   - Server: `mail.lly.sh`
   - Port: `993`
   - Connection Security: *SSL/TLS*
   - Auth Method: *Normal Password*
   - Credentials: Username and password from [auth.lly.sh](https://auth.lly.sh)
- SMTP Data:
   - Server: `mail.lly.sh`
   - Port: `587`
   - Connection Security: *STARTTLS*
   - Auth Method: *Normal Password*
   - Credentials: Username and password from [auth.lly.sh](https://auth.lly.sh)
   
## How to add a mailbox

### Actions on my Infrastructure

1. Add user account on [Keycloak](https://auth.ftsell.de/admin/master/console/).

   This is the account which will be used for authenticating users over IMAP and Submission (SMTP).

2. Add domain to [postfix_virtual_domains.txt](../k8s/user-apps/mailserver/configs/postfix_virtual_domains.txt).

   This list is responsible for telling postfix for which domains e-mails are accepted or discarded.
   Domains not listed here will be rejected unless the user is authenticated.

3. Add address rewriting rules to [postfix_virtual_alias_maps.txt](../k8s/user-apps/mailserver/configs/postfix_virtual_alias_maps.txt).

   Postfix uses this maps for address rewriting of incoming e-mail.
   The file lists `<from> <to>` rewriting rules so that e.g. the rule `foo@example.com bar@example.com` would result in e-mails destined to `foo@example.com` be delivered to `bar@example.com`.
   Aliases can be recursive.
   Aliases can also resolve to multiple addresses which are `;` separated in which case the e-mail will be delivered to all of them.
   Catch-all aliases for a whole domain can be specified as `@example.com`.

   The final resolution should always be to a bare keycloak username (without domain) so that dovecot can deliver it correctly.

4. Add sender authorization entry to [postfix_sender_login_maps.txt](../k8s/user-apps/mailserver/configs/postfix_sender_login_maps.txt).

   Postfix uses this to determine which user is allowed to send from which address.

   The format is `<sender-address> <username>` where `<sender-address>` can also be the whole domain given as `@example.com`.
   Multiple users can be allowed to send from the same address by separating them with `,`.

5. Add domain to [opendkim_domains.txt](../k8s/user-apps/mailserver/configs/opendkim_domains.txt)

   This file configures the opendkim daemon to attach signatures to all outgoing mails for domains that are listed here.


### Actions on users Infrastructure

1. Configure [DNS A Record](https://en.wikipedia.org/wiki/List_of_DNS_record_types#A).

   This is not strictly necessary but some e-mail providers require the sending domain to have a valid A record.
   For this reason it is recommended to do so.
   This record does not need to point to the mailserver.

2. Configure [DNS MX Record](https://en.wikipedia.org/wiki/MX_record)

   This record dictates how e-mails for the domain are delivered to different mail servers.
   Multiple records can be specified with different priorities (lower number takes precedence).

   The value of the record should probably be `mail.srv.lly.sh`.

3. Configure [SPF Policy](https://en.wikipedia.org/wiki/Sender_Policy_Framework) via DNS.

   *SPF* stands for *Sender Policy Framework* and tells receiving mail servers which IP addresses are authorized to send emails for the sending domain.

   *SPF* is implemented as a *TXT Record* on the domain for which emails should be configured.
   For example, to allow my mailserver to send emails but forbid all others the policy `v=spf1 +include:lly.sh -all` can be used.
   If a more sophisticated policy is desired, the *SPF Record Generator* tool from [PowerDmarc](https://powerdmarc.com/power-dmarc-toolbox/) is a good start.

4. Configure the public [DKIM](https://en.wikipedia.org/wiki/DomainKeys_Identified_Mail) Key via DNS.

   *DKIM* is another e-mail verification technique.
   The difference to *SPF* is that it does not verify the sending mail server but the sent e-mail.
   It works by the sending mail server cryptographically signing outgoing e-mails.
   A receiving server then looks up the public key from DNS and verifies the signature.

   *DKIM* is implemented as a *TXT Record* on the domain for which emails should be configured and consists of a key identifier as part of the record host and the public key value.

   The current public key record should be set as `main._domainkey` with value
   ```text
   v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2Aq7HNQZmuk438HUlcYsxkmRuHJOz4ZpPRfIIml6C3Qp5hY5O7l8cSmvhsj1vLoMoPi4CWwHyOVl2hRTMQqsYz+l6ZFAcwI3YBDTD7hjaB3nNjGfOVo1X2Cq7c+sFaeMAZwTqC2R1TusfVb7QBuUTRxVnHStvc7crmOdJb0NCVBZvJ0juYkmXtAi6S/VhBZxDSpMb69Eef48yeyFEhK5qcRSAA2D/RnaZwY1/RrKS4RpP6YEhkgFkLtgiQuYjslk64zDYiJu3pmIhW1an+qv984C55FowifyGVaLkCkvXrnO/kMMX5Ya05N6RnurVCP9w6Vu2yX8zThY1F8yyro6SwIDAQAB
   ```

5. Configure [DMARC](https://en.wikipedia.org/wiki/DMARC) via DNS.

   *DMARC* is a framework for notifying administrators about policy violations (*SPF* and *DKIM*).
   Such notifications may not be desired, but it improves spam scores if a *DMARC* policy explicitly states that in comparison to not having one.

   *DMARC* is implemented as a `_dmarc.` *TXT Record* on the domain for which it should be configured.

   For example if no reports are wanted, the `_dmarc.$domain` *TXT Record* should be set to `v=DMARC1; p=none`.
