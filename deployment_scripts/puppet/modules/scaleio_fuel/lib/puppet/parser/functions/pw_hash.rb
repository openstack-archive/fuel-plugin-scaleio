module Puppet::Parser::Functions
  newfunction(:pw_hash, :type => :rvalue) do |args|
    require 'digest/sha2'

    raise(Puppet::ParseError, "pw_hash(): Wrong number of arguments " +
      "passed (#{arguments.size} but we require 3)") if arguments.size != 3
      
    password = args[0]
    alg = args[1]
    salt  = args[2]

    return case alg
      when 'SHA-512'
        Digest::SHA512.digest(salt + password)
      when 'SHA-256'
        Digest::SHA256.digest(salt + password)
      when 'MD5'
        Digest::MD5.digest(salt + password)
      else
        raise(Puppet::ParseError, "pw_hash(): Invalid algorithm " +
          "passed (%s but it supports only SHA-512, SHA-256, MD5)" % alg)
      end
  end
end
