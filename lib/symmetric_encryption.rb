# Used for compression
require 'zlib'
# Used to coerce data types between string and their actual types
require 'coercible'

require 'symmetric_encryption/version'
require 'symmetric_encryption/cipher'
require 'symmetric_encryption/symmetric_encryption'
require 'symmetric_encryption/exception'

module SymmetricEncryption
  autoload :Reader,    'symmetric_encryption/reader'
  autoload :Writer,    'symmetric_encryption/writer'
  autoload :Generator, 'symmetric_encryption/generator'
end

# Add support for other libraries only if they have already been loaded
require 'symmetric_encryption/railtie' if defined?(Rails)
require 'symmetric_encryption/railties/symmetric_encryption_validator' if defined?(ActiveModel)
