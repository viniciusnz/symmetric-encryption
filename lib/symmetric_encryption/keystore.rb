module SymmetricEncryption
  module Keystore
    #@formatter:off
    autoload :Environment, 'symmetric_encryption/keystore/environment'
    autoload :File,        'symmetric_encryption/keystore/file'
    autoload :Memory,      'symmetric_encryption/keystore/memory'
    #@formatter:on

    # Returns [Hash] a new configuration file after performing key rotation.
    #
    # Perform key rotation for each of the environments in the configuration file, by
    # * generating a new key, and iv with an incremented version number.
    #
    # Params:
    #   config: [Hash]
    #     The current contents of `symmetric-encryption.yml`.
    #
    #   environments: [Array<String>]
    #     List of environments for which to perform key rotation for.
    #     Default: All environments found in the current configuration file except development and test.
    #
    #   rolling_deploy: [true|false]
    #     To support a rolling deploy of the new key it must added initially as the second key.
    #     Then in a subsequent deploy the key can be moved into the first position to activate it.
    #     In this way during a rolling deploy encrypted values written by updated servers will be readable
    #     by the servers that have not been updated yet.
    #     Default: false
    #
    # Notes:
    # * iv_filename is no longer supported and is removed when creating a new random cipher.
    #     * `iv` does not need to be encrypted and is included in the clear.
    def self.rotate_keys!(config, environments: [], app_name:, rolling_deploy: false)
      config.each_pair do |environment, cfg|
        # Only rotate keys for specified environments. Default, all
        next if !environments.empty? && !environments.include?(environment.to_sym)

        # Find the highest version number
        version = cfg[:ciphers].collect { |c| c[:version] || 0 }.max

        cipher_cfg = cfg[:ciphers].first

        # Only generate new keys for keystore's that have a key encrypting key
        next unless cipher_cfg[:key_encrypting_key]

        # Generate a new random Key Encrypting Key
        rsa_key            = KeyEncryptingKey.generate_rsa_key
        key_encrypting_key = KeyEncryptingKey.new(rsa_key)

        cipher_name    = cipher_cfg[:cipher_name] || 'aes-256-cbc'
        new_cipher_cfg =
          if cipher_cfg.has_key?(:key_filename)
            key_path = ::File.dirname(cipher_cfg[:key_filename])
            Keystore::File.new_cipher(key_path: key_path, cipher_name: cipher_name, key_encrypting_key: key_encrypting_key, app_name: app_name, version: version, environment: environment)
          elsif cipher_cfg.has_key?(:key_env_var)
            Keystore::Environment.new_cipher(cipher_name: cipher_name, key_encrypting_key: key_encrypting_key, app_name: app_name, version: version, environment: environment)
          elsif cipher_cfg.has_key?(:encrypted_key)
            Keystore::Memory.new_cipher(cipher_name: cipher_name, key_encrypting_key: key_encrypting_key, app_name: app_name, version: version, environment: environment)
          end

        new_cipher_cfg[:key_encrypting_key] = rsa_key

        # Add as second key so that key can be published now and only used in a later deploy.
        if rolling_deploy
          cfg[:ciphers].insert(1, new_cipher_cfg)
        else
          cfg[:ciphers].unshift(new_cipher_cfg)
        end
      end
      config
    end
  end
end