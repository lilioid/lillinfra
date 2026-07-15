# E-Mail Setup Docs & Maintenance Guide

The deployed email system uses my own [mailcalf](https://git.lly.sh/lilly/mailcalf) dockerized mailserver.
It is deployed via [k8s/aut-sys/apps/mailserver](../k8s/aut-sys/apps/mailserver).

## Server data

- Mailserver name: `mail.aut-sys.de`
- IMAP Data:
   - Server: `mail.aut-sys.de`
   - Port: `993`
   - Connection Security: *SSL/TLS*
   - Auth Method: *Normal Password*
   - Credentials: Username and password from [auth.aut-sys.de](https://auth.aut-sys.de)
- SMTP Data:
   - Server: `mail.aut-sys.de`
   - Port: `587`
   - Connection Security: *STARTTLS*
   - Auth Method: *Normal Password*
   - Credentials: Username and password from [auth.aut-sys.de](https://auth.aut-sys.de)
   
## How to add a mailbox

### Actions on my Infrastructure

1. Add user account on [Authentik](https://auth.aut-sys.de/).

   This is the account which will be used for authenticating users over IMAP and Submission (SMTP).

2. Add domain to [postfix_virtual_domains.txt](../k8s/aut-sys/apps//mailserver/configs/postfix_virtual_domains.txt).

   This list is responsible for telling postfix for which domains e-mails are accepted or discarded.
   Domains not listed here will be rejected unless the user is authenticated.

3. Add address rewriting rules to [postfix_virtual_alias_maps.txt](../k8s/aut-sys/apps/mailserver/configs/postfix_virtual_alias_maps.txt).

   Postfix uses this maps for address rewriting of incoming e-mail.
   The file lists `<from> <to>` rewriting rules so that e.g. the rule `foo@example.com bar@example.com` would result in e-mails destined to `foo@example.com` be delivered to `bar@example.com`.
   Aliases can be recursive.
   Aliases can also resolve to multiple addresses which are `;` separated in which case the e-mail will be delivered to all of them.
   Catch-all aliases for a whole domain can be specified as `@example.com`.

   The final resolution should always be to a bare keycloak username (without domain) so that dovecot can deliver it correctly.

4. Add sender authorization entry to [postfix_sender_login_maps.txt](../k8s/aut-sys/apps/mailserver/configs/postfix_sender_login_maps.txt).

   Postfix uses this to determine which user is allowed to send from which address.

   The format is `<sender-address> <username>` where `<sender-address>` can also be the whole domain given as `@example.com`.
   Multiple users can be allowed to send from the same address by separating them with `,`.

5. Add domain to [opendkim_domains.txt](../k8s/aut-sys/apps/mailserver/configs/opendkim_domains.txt)

   This file configures the opendkim daemon to attach signatures to all outgoing mails for domains that are listed here.


### Actions on users Infrastructure

1. Configure [DNS A Record](https://en.wikipedia.org/wiki/List_of_DNS_record_types#A).

   This is not strictly necessary but some e-mail providers require the sending domain to have a valid A record.
   For this reason it is recommended to do so.
   This record does not need to point to the mailserver.

2. Configure [DNS MX Record](https://en.wikipedia.org/wiki/MX_record)

   This record dictates how e-mails for the domain are delivered to different mail servers.
   Multiple records can be specified with different priorities (lower number takes precedence).

   The value of the record should probably be `10 mx1.z9.aut-num.de.`.

3. Configure [SPF Policy](https://en.wikipedia.org/wiki/Sender_Policy_Framework) via DNS.

   *SPF* stands for *Sender Policy Framework* and tells receiving mail servers which IP addresses are authorized to send emails for the sending domain.

   *SPF* is implemented as a *TXT Record* on the domain for which emails should be configured.
   For example, to allow my mailserver to send emails but forbid all others, the below policy could be set.
   If a more sophisticated policy is desired, the *SPF Record Generator* tool from [PowerDmarc](https://powerdmarc.com/power-dmarc-toolbox/) is a good start.

4. Configure the public [DKIM](https://en.wikipedia.org/wiki/DomainKeys_Identified_Mail) Key via DNS.

   *DKIM* is another e-mail verification technique.
   The difference to *SPF* is that it does not verify the sending mail server but the sent e-mail.
   It works by the sending mail server cryptographically signing outgoing e-mails.
   A receiving server then looks up the public key from DNS and verifies the signature.

   *DKIM* is implemented as a *TXT Record* on the domain for which emails should be configured and consists of a key identifier as part of the record host and the public key value.

   The current public key record should be set as `main._domainkey` with value seen below.

5. Configure [DMARC](https://en.wikipedia.org/wiki/DMARC) via DNS.

   *DMARC* is a framework for notifying administrators about policy violations (*SPF* and *DKIM*).
   Such notifications may not be desired, but it improves spam scores if a *DMARC* policy explicitly states that in comparison to not having one.

   *DMARC* is implemented as a `_dmarc.` *TXT Record* on the domain for which it should be configured.

   For example if no reports are wanted, the `_dmarc.$domain` *TXT Record* should be set to the example below.

In summary, the following records are required:

```zonefile
@                  MX    10 mx1.z9.aut-sys.de.
_dmarc             CNAME dmarc.hosted-on.aut-sys.de.
main._domainkey    CNAME dkimkey-main.hosted-on.aut-sys.de.
@	                 TXT	"v=spf1 +include:spf.hosted-on.aut-sys.de ~all"
```

