---
layout: default
---

## PCI Compliance

In order to assist with PCI Compliance audits, below are some ways that
Symmetric Encryption assists with the [PCI DSS](https://www.pcisecuritystandards.org/security_standards/documents.php)

Since Symmetric Encryption is used to encrypt any sensitive data, such fields will
be refered to as PII (Personally Identifiable Information) and not just PANs as
mentioned in the PCI DSS.

The primary purpose of Symmetric Encryption is to secure data at rest. It also
secures encrypted fields in flight between the application servers and the backend
databases, since the encryption/decryption occurs within the application.
Additionally it can be used to secure files containing PII data, securing both the
network traffic generated while the file is being read/written to a network share
as well as while the files are at rest locally or on a remote network share.

Note that Symmetric Encryption does not address the PCI Compliance requirements
relating to documenting the necessary internal processes.

Symmetric Encryption assists with the following PCI DSS requirements. These responses
need to be read in conjunction with the [PCI DSS](https://www.pcisecuritystandards.org/security_standards/documents.php)
documentation:

### Requirement 3: Protect stored cardholder data

#### 3.4 Strong Cryptography of PII wherever it is stored

3.4.a

* This relies on all PII being marked as requiring encryption
with Symmetric Encryption in the source code itself
    * Confirm that the models for accessing the PII are secured using for example:

~~~ruby
# Rails ActiveRecord example of securing `bank_account_number`
#
# A column called `encrypted_bank_account_number` should exist in the database
# that contains the encrypted bank account number. There should not be a column
# called `bank_account_number`
class User < ActiveRecord::Base
  attr_encrypted :bank_account_number
  attr_encrypted :long_string, random_iv: true, compress: true
~~~

~~~ruby
# Mongoid example of securing `bank_account_number`
#
# A column called `encrypted_bank_account_number` should exist in MongoDB
# that contains the encrypted bank account number. There should not be a column
# called `bank_account_number`
class User
  include Mongoid::Document

  field :encrypted_bank_account_number, type: String,  encrypted: true
  field :encrypted_long_string,         type: String,  encrypted: {random_iv: true, compress: true}
~~~

* Is the configured encryption algorithm and block cipher sufficiently strong for
the production environment?
    * Confirm by checking production environment settings in symmetric_encryption.yml

* User Passwords should be rendered unreadable by using one-way hash functions
  based on strong cryptography so that it is not possible to reverse the user's
  password back to it's original form.
    * There are several gems for Rails to implement secure one-way hash's

Notes:

* It is recommended to set `random_iv: true` for all fields that are encrypted, since
the same data will always result in different encrypted output.
    * However, it is not possible for any field that is used in lookups to use this option.
    * For example, looking for all previous instances of a specific `bank_account_number` requires
that the encrypted data always have the same output for the same input.
    * When the `random_iv` is not set for any field it should be kept short as encypting
large amounts of data with the same `data-encryption-key` and `initialization-vector` (IV)
can eventually expose the `data-encryption-key`
    * Rotation policies to change the `data-encryption-key` can help mitigate this exposure

3.4.b, 3.4.c

* Browse the data stored in the Database, for example: MySQL, MongoDB, to confirm that
identified fields are unreadable (not plain text)
* For any files consumed or generated by the system confirm that
the required fields, or that the entire file is unreadable (not plain text)
    * This includes any files uploaded to the system, or made available for download from the system

3.4.d

* Out of the box Symmetric Encryption does not assist with cleansing / encrypting audit or other logs
    * Use features built into Rails to prevent logging of PII fields

#### 3.5 Procedures to protect keys

3.5.1

With Symmetric Encryption it is necessary to maintain separation of duties so that
anyone with access to the `data-encryption-key` does _not_ also have access to the `key-encryption-key`.

* The `data-encryption-key` is limited to the user under which the application runs and
  to any production system administrator that has root / administrator access to override the read-only
  restriction
    * Verify that the `data-encryption-key` is only readable by the application user
      and not by group or everyone (Example: rails)

In Symmetric Encryption the `data-encryption-key` is stored on the file system and
is placed their by the system administrator. The `key-encryption-key` is stored in the
source code that should only be accessible to the application development team.

3.5.2a

* The keys are generated by Symmetric Encryption itself and are immediately wrapped
  with the `key-encryption-key` so are never in the clear.

* See Symmetric Encryption configuration on how keys are generated

3.5.2b

* With Symmetric Encryption the secret and private keys (`data-encryption-key`) are
  encrypted with a `key-encryption-key`.

3.5.2c

* The `key-encryption-key` uses RSA 2048 bit encryption and therefore exceeds the strength
  of the `data-encryption-key`
* The `key-encryption-key` must be placed on the system directly by a system administrator
  and must _not_ be included in the source code, or the source control repository


3.5.3

* Consider storing the `key-encryption-key` in a separate repository that is limited
  to custodians and the application itself

### 3.6 Key Management Procedures

3.6.1a

* The keys are generated by Symmetric Encryption itself and are immediately wrapped
  with the `key-encryption-key` so are never in the clear.
* See Symmetric Encryption configuration on how keys are generated

3.6.1b

* Confirm by checking production environment settings in symmetric_encryption.yml

3.6.2

* Needs a secure, documented, repeatable process for distributing the `data-encryption-key`

3.6.3a, 3.6.3b

* The keys are generated by Symmetric Encryption itself and are immediately wrapped
  with the `key-encryption-key` so are never in the clear.

3.6.4, 3.6.5

* The `key-encryption-key` should be rotated on a regular interval, or when compromised
    * For example, annually

* Symmetric Encryption versions all encrypted data so that during a key rotation period
  the new key is used for encryption and decryption, and the old key(s) can be used
  exclusively to decrypt older data.
    * Confirm by checking production environment settings in symmetric_encryption.yml
      to ensure that new key is listed before the old keys

* Once all data has been re-encrypted with the new key, the old key can be destroyed
    * To verify that all data has been migrated, check the version header of encrypted
      data and confirm that all encrypted data starts with the header from the new
      key
    * For example, in the Rails console to see the same data encrypted with the new and
      the old key:

~~~ruby
# Encrypted with new key
SymmetricEncryption.encrypt('hello')

# Encrypted with old key
SymmetricEncryption.secondary_ciphers.first.encrypt('hello')
~~~

3.6.6

* N/A since `data-encryption-key` is secured with a `key-encryption-key`

3.6.7

* Procedures in place to prevent unauthorized replacement of keys
    * Linux security must limit write access for `data-encryption-keys` to System Administrators only
    * A `data-encryption-key` encrypted with a different `key-encryption-key` will
      be rejected by the system on startup

3.6.8

Recommendations not covered by PCI Compliance:

* Recommend separating custodians for `key-encryption-key` from
  custodians for `data-encryption-key`
* Recommend that the above key custodians not have access to database backup media

### Next => [API](api.html)
